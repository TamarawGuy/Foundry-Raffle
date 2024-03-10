// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title A simple Raffle Contract
 * @notice This contract implements a simple raffle system, which
 * picks a random winner from a list of participants.
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Errors */
    /* Interfaces, Libraries, Contracts */
    /* Types */
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    /* State variables */
    // Chainlink VRF
    VRFCoordinatorV2Interface private immutable i_vrfCoordinatorV2;
    uint64 i_subscriptionId;
    bytes32 i_gasLane;
    uint32 i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    
    // Lottery Variables
    uint256 private immutable i_interval;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    address payable[] private s_players;
    RaffleState private s_raffleState;
    /* Events */
    /* Modifiers */

    /* Constructor */
    constructor(
        uint64 _subscriptionId,
        bytes32 _gasLane,
        uint256 _interval,
        uint256 _entranceFee,
        uint32 _callbackGasLimit,
        address _vrfCoordinatorV2
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        i_vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        i_subscriptionId = _subscriptionId;
        i_gasLane = _gasLane;
        i_interval = _interval;
        i_entranceFee = _entranceFee;
        i_callbackGasLimit = _callbackGasLimit;
    }

    // Receive | Fallback
    // External
    // Public
    function enterRaffle() public payable {}

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {}

    function performUpkeep(bytes calldata /* performData */) external override {

    }

    function fulfillRandomWords(uint256 /*requestId */, uint256[] memory randomWords) internal override {

    }
    // Internal
    // Private
    // View & Pure functions
}
