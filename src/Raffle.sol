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
contract Raffle {
    // Errors
    // Interfaces, Libraries, Contracts
    // Types
    // State variables
    // Events
    // Modifiers

    // Constructor
    // Receive | Fallback
    // External
    // Public
    // Internal
    // Private
    // View & Pure functions
}
