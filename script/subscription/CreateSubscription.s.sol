// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../deploy/HelperConfig.s.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig()
        public
        returns (uint64 subscriptionId)
    {
        (address vrfCoordinator, uint256 deployerKey) = getHelperVariables();
        subscriptionId = createSubscription(vrfCoordinator, deployerKey);
    }

    function createSubscription(
        address vrfCoordinator,
        uint256 deployerKey
    ) public returns (uint64 subscriptionId) {
        vm.startBroadcast(deployerKey);
        subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();

        console.log("Subscription is created...");
        console.log("ChainId: ", block.chainid);
        console.log("deployerKey: ", deployerKey);
        console.log("SubscriptionId: ", subscriptionId);
        console.log("VRF Coordinator: ", vrfCoordinator);
    }

    function getHelperVariables()
        private
        returns (address vrfCoordinator, uint256 deployerKey)
    {
        HelperConfig helperConfig = new HelperConfig();

        (, , vrfCoordinator, , , , , deployerKey) = helperConfig
            .activeNetworkConfig();
    }

    function run() external returns (uint64 subId) {
        subId = createSubscriptionUsingConfig();
    }
}
