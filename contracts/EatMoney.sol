// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Imports

import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";  // For Random Numbers generations
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";   // For Price Feeds


contract EatMoney is VRFConsumerBaseV2{

    // <---------------------Declarations------------------------------------>

    uint256 constant EAT_DECIMALS = 8;

    uint256 FACTOR_1 = 1;    // cofficent for efficency (will change according to the market)
    uint256 FACTOR_2 = 3;    // random start
    uint256 FACTOR_3 = 5;    // random end

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




    
}
