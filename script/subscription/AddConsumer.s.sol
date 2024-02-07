// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../deploy/HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract AddConsumer is Script {
    function addConsumerUsingConfig(address vrfConsumer) public {
        (
            address vrfCoordinator,
            uint64 subscriptionId,
            uint256 deployerKey
        ) = getHelperVariables();

        addConsumer(vrfCoordinator, subscriptionId, vrfConsumer, deployerKey);
    }

    // addConsumer(uint64 _subId, address _consumer)
    function addConsumer(
        address vrfCoordinator,
        uint64 subscriptionId,
        address vrfConsumer,
        uint256 deployerKey
    ) public {
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(
            subscriptionId,
            vrfConsumer
        );
        vm.stopBroadcast();

        console.log("Consumer is added...");
        console.log("ChainId: ", block.chainid);
        console.log("deployerKey: ", deployerKey);
        console.log("SubscriptionId: ", subscriptionId);
        console.log("VRF Coordinator: ", vrfCoordinator);
        console.log("VRF Consumer Contract: ", vrfConsumer);
    }

    function getHelperVariables()
        private
        returns (
            address vrfCoordinator,
            uint64 subscriptionId,
            uint256 deployerKey
        )
    {
        HelperConfig helperConfig = new HelperConfig();
        (, , vrfCoordinator, subscriptionId, , , , deployerKey) = helperConfig
            .activeNetworkConfig();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
