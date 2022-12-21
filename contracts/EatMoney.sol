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

    // ===========
    // Mappings
    // ===========
    mapping(uint256 => ChainlinkRequestType) public chainlinkRequestTypes;
    mapping(uint256 => uint8) public reqIdToCategory;

    // ===========
    // Structures
    // ===========
    struct MintRequest{
        uint8 category;
        uint256[] randomWords;
        bool isMinted;
    }

    struct SpinRequest{
        uint256 plateId;
        address owner;
        uint256 eatCoins;
        bool active;
    }

    struct EatRequest{
        uint256 plateId;
        address owner;
        uint256 restaurantId;
        uint256 amount;
        bool active;
    }

    MintRequest[] public mintRequests;
    
    // ==================
    // Mapping of Requests
    // ===================
    mapping(uint256 => EatRequest) public reqIdToEatRequest;
    mapping(uint256=>SpinRequest) public reqIdToSpinRequest;

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
}
