// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Imports

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; // For Random Numbers generations
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // For Price Feeds

contract EatMoney is
    ERC1155,
    ERC1155Burnable,
    Ownable,
    VRFConsumerBaseV2,
    ERC1155Holder
{
    // ===================== Declarations ============================

    uint256 constant EAT_DECIMALS = 8;

    uint256 FACTOR_1 = 1; // cofficent for efficency (will change according to the market)
    uint256 FACTOR_2 = 3; // random start
    uint256 FACTOR_3 = 5; // random end

    // =======================
    // Chainlink VRF Variables
    // =======================
    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 immutable s_keyHash;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint64 s_subscriptionId;

    AggregatorV3Interface internal priceFeed;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _resturants;
    Counters.Counter private _listings;
    
    // ===========
    // Enums
    // ===========

    // Cap is the limit for users to spend an amount less than a specific Cap for each day. on each Category of EAT Plate.
    // 🥉 Bronze ⇒ 5 USD max per day.
    // 🥈 Silver ⇒ 15 USD max per day.
    // 🥇 Gold ⇒ 50 USD max per day.
    // 💎 Emerald ⇒ 100 USD max per day.
    enum Category {
        BRONZE,
        SILVER,
        GOLD,
        EMERALD
    }

    enum ChainlinkRequestType {
        MINT,
        EAT,
        SPIN
    }

    mapping(uint256 => ChainlinkRequestType) public chainlinkRequestTypes;
    mapping(uint256 => uint8) public reqIdToCategory;


    // ===========
    // Structures
    // ===========

    struct EatPlate{
        uint256 id;
        uint256 efficiency;
        uint256 fortune;
        uint256 durability;
        uint256 shiny;     // It tells you how much clean your EAT Plate is. You can only level up if your Shiny is 100%.
        uint8 level;
        Category category;
        uint256 lastEat;
        uint256 eats;
        mapping(uint256=>Spin) idToSpin;
    }

    mapping(uint256=>EatPlate) public idToEatPlate;


    struct EatPlateReturn{
        uint256 id;
        uint256 efficiency;
        uint256 fortune;
        uint256 durability;
        uint256 shiny;
        uint8 level;
        Category category;
        uint256 lastEat;
        uint256 eats;
    }


    struct MintRequest{
        uint8 category;
        uint256[] randomWords;
        bool isMinted;
    }

    MintRequest[] public mintRequests;


    struct SpinRequest{
        uint256 plateId;
        address owner;
        uint256 eatCoins;
        bool active;
    }

    mapping(uint256=>SpinRequest) public reqIdToSpinRequest;


    struct EatRequest{
        uint256 plateId;
        address owner;
        uint256 restaurantId;
        uint256 amount;
        bool active;
    }

    mapping(uint256 => EatRequest) public reqIdToEatRequest;
    
    
    struct Spin{
        uint256 spinId;
        uint32 result;   //    1/2/3/4
        uint256 eatCoins;
        bool isSpinned;
    }


    struct MarketItem{
        uint256 id;
        uint256 price;
        address payable owner;
        bool active;
        uint256 tokenId;
    }

    mapping(uint256 => MarketItem) public idToMarketplaceItem;


    struct Resturant{
        uint256 id;
        string info;
        address payable owner;
    }

    mapping(uint256=>Resturant) public idToRestaurant;
    mapping(address => uint256) public addressToRestaurantId;



    // ==============
    // EVENTS
    // ==============

    event EatFinished(
        uint256 indexed plateId,
        uint256 restaurantId,
        uint256 amount,
        uint256 eatCoinsMinted
    );



    // ===========
    // Constructor
    // ===========
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    )
        VRFConsumerBaseV2(vrfCoordinator)
        ERC1155(
            "ipfs://bafybeickwso5eac5krffgzdk2ktfg5spnryiygk3mbenryxdsapg3a54va/"
        )
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        ); // //MATIC/USD price feed mumbai
    }

    //===========
    // Functions
    //============

    // This function checks whether the parent contract supports the interface specified by the interfaceId parameter.
    // override(ERC1155, ERC1155Receiver): This modifier specifies that the function can be overridden by contracts that implement the ERC1155 or ERC1155Receiver interfaces.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
    {
        ChainlinkRequestType requestType = chainlinkRequestTypes[requestId];
        if(requestType == ChainlinkRequestType.MINT){
            mintRequests.push(
                MintRequest(reqIdToCategory[requestId], randomWords, false)
            );
        }else if(requestType == ChainlinkRequestType.EAT){
            _finishEat(requestId, randomWords);
        }else if( requestType == ChainlinkRequestType.SPIN){
            _finishSpin(requestId, randomWords);
        }
    }







    // ---------------------------------
    
    function _finishEat(uint256 requestId, uint256[] memory randomWords)
    internal
    {
        EatRequest memory eatRequest = reqIdToEatRequest[requestId];
        require(eatRequest.active == false, "Aleady claimed eat coins for this request");
        EatPlate storage plate = idToEatPlate[eatRequest.plateId];

        uint256 shinyFactor = 100;
        if(plate.shiny <= 60){
            shinyFactor = 111;  // earning drop to 90% if shiny is less than 60
        }else if(plate.shiny <= 20){
            shinyFactor = 1000; // earning drop to 10% if shiny is less than 20
        }

        uint256 randomWord = randomWords[0];
        uint256 randFactor = (randomWord % (FACTOR_3 - FACTOR_2 + 1)) + FACTOR_2;
        uint256 eatCoins = ((plate.efficiency ** FACTOR_1) * eatRequest.amount * 10 ** 4 ) / (randFactor * shinyFactor);

        idToEatPlate[eatRequest.plateId].lastEat = block.timestamp;
        idToEatPlate[eatRequest.plateId].shiny -= 10;
        reqIdToEatRequest[requestId].active = true;
        idToEatPlate[eatRequest.plateId].idToSpin[plate.eats + 1] = Spin(
            plate.eats + 1,
            0,
            eatCoins,
            false
        );
        idToEatPlate[eatRequest.plateId].eats += 1;

        mintEatCoins(eatRequest.owner, eatCoins);

        emit EatFinished(
            eatRequest.plateId,
            eatRequest.restaurantId,
            eatRequest.amount,
            eatCoins
        );

    }








    // ---------------------------------







}
