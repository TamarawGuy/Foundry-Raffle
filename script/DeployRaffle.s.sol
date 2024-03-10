// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";

import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, AddConsumer, FundSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helper = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        (
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey,
            uint256 automationUpdateInterval,
            uint256 raffleEntranceFee
        ) = helper.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (subscriptionId, vrfCoordinator) = createSubscription
                .createSubscription(vrfCoordinator, deployerKey);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link,
                deployerKey
            );
        }

        vm.startBroadcast(deployerKey);
        Raffle raffle = new Raffle(
            raffleEntranceFee,
            automationUpdateInterval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );

        vm.stopBroadcast();

        addConsumer.addConsumer(
            address(raffle),
            vrfCoordinator,
            subscriptionId,
            deployerKey
        );

        return (raffle, helper);
    }
}
