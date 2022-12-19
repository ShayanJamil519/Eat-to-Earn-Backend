// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Imports

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";  // For Random Numbers generations
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";   // For Price Feeds


contract EatMoney is ERC1155, VRFConsumerBaseV2{

    // <---------------------Declarations------------------------------------>

    uint256 constant EAT_DECIMALS = 8;

    uint256 FACTOR_1 = 1;    // cofficent for efficency (will change according to the market)
    uint256 FACTOR_2 = 3;    // random start
    uint256 FACTOR_3 = 5;    // random end

    // Chainlink VRF Variables
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



    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    )
    VRFConsumerBaseV2(vrfCoordinator)
    ERC1155("ipfs://bafybeickwso5eac5krffgzdk2ktfg5spnryiygk3mbenryxdsapg3a54va/")
{
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_keyHash =keyHash;
    s_subscriptionId = subscriptionId;
    priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);  // //MATIC/USD price feed mumbai   
}



    
}
