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
    error Raffle__SendMoreToEnter();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );
    error Raffle__TransferFailed();

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
    event EnteredRaffle(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event PickedWinner(address indexed winner);

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
        i_callbackGasLimit = _callbackGasLimit;
        i_interval = _interval;
        i_entranceFee = _entranceFee;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }

    /**
     * Function for entering the Raffle
     * @notice We check if the raffle is OPEN and if the amount sent is
     * greater or equal to the entrance fee. If both conditions are met,
     * we add the player to the list of participants.
     */
    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnter();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that Chainlink
     * Keeper nodes call. They look for "upkeepNeeded"
     * to return True. The following should be true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH
     * 4. Implicitly, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @dev Once "checkUpkeep" is returning "true", this function is
     * called and it kicks off a Chainlink VRF call to get a random
     * winner.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        uint256 requestId = i_vrfCoordinatorV2.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedRaffleWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send money to random winner.
     */
    function fulfillRandomWords(
        uint256 /*requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] * s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(recentWinner);

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /* View | Pure */
    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() external pure returns (uint32) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() external pure returns (uint16) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWiner() external view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 _index) external view returns (address) {
        return s_players[_index];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }
}
