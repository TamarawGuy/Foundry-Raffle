// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64, address) {
        HelperConfig helper = new HelperConfig();
        (address vrfCoordinator, , , , , uint256 deployerKey, , ) = helper
            .activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(
        address _vrfCoordinator,
        uint256 _deployerKey
    ) public returns (uint64, address) {
        vm.startBroadcast(_deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(_vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        return (subId, _vrfCoordinator);
    }

    function run() external returns (uint64, address) {
        return createSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address _raffle,
        address _vrfCoordinator,
        uint64 _subId,
        uint256 _deployerKey
    ) public {
        vm.startBroadcast(_deployerKey);
        VRFCoordinatorV2Mock(_vrfCoordinator).addConsumer(_subId, _raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address _raffle) public {
        HelperConfig helper = new HelperConfig();
        (
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            ,
            uint256 deployerKey,
            ,

        ) = helper.activeNetworkConfig();

        addConsumer(_raffle, vrfCoordinator, subscriptionId, deployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscription(
        address _vrfCoordinator,
        uint64 _subId,
        address _link,
        uint256 _deployerKey
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(_vrfCoordinator).fundSubscription(
                _subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(_deployerKey);
            LinkToken(_link).transferAndCall(
                _vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(_subId)
            );
        }
    }

    function fundSubscriptionUsingConfig() public {
        HelperConfig helper = new HelperConfig();
        (
            address vrfCoordinator,
            ,
            uint64 subscriptionId,
            ,
            address link,
            uint256 deployerKey,
            ,

        ) = helper.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint64 updatedSubId, address updatedVRF) = createSub.run();
            subscriptionId = updatedSubId;
            vrfCoordinator = updatedVRF;
        }

        fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}
