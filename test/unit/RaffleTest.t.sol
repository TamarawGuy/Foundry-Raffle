// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helper;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    uint256 entranceFee;
    uint256 interval;
    address link;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helper) = deployer.run();
        (
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link,
            ,
            interval,
            entranceFee
        ) = helper.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testRaffleInitialState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /* ENTER RAFFLE */
}
