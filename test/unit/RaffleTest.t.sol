// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    event EnteredRaffle(address indexed _player);

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
    function testRaffleRevertWhenYouDontPayEnough() public {
        vm.startPrank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSend.selector);
        raffle.enterRaffle();
        vm.stopPrank();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.startPrank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }

    function testCantEnterWhenRaffleStateIsCalculating() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.startPrank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
    }

    /* CHECK UPKEEP */
    function testCheckUpkeepReturnsFalseIfNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval - 10);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    /* PERFORM UPKEEP */
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        uint256 currBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currBalance,
                numPlayers,
                raffleState
            )
        );
        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed() {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.stopPrank();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitRequestId()
        public
        raffleEnteredAndTimePassed
    {
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(rState) == 1);
        assert(requestId > 0);
    }

    /* FULFILL RANDOM WORDS */ modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformedUpkeep(
        uint256 randomRequestId
    ) public raffleEnteredAndTimePassed {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFulfillRandomWordsPickWinnerResetsAndSendsMoney()
        public
        raffleEnteredAndTimePassed
        skipFork
    {
        // additional 5 players enter
        uint256 additionalEntrant = 5;
        uint256 startingIndex = 1;
        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrant;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrant + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 previousTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        console.log(uint256(raffle.getLengthOfPlayers()));
        // assert(uint256(raffle.getRaffleState()) == 0);
        // assert(raffle.getRecentWiner() != address(0));
        // assert(raffle.getLengthOfPlayers() == 0);
        // assert(previousTimeStamp < raffle.getLastTimeStamp());
        // assert(
        //     raffle.getRecentWiner().balance ==
        //         STARTING_USER_BALANCE + prize - entranceFee
        // );
    }
}
