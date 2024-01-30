// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../deploy/HelperConfig.s.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingHelperConfig()
        public
        returns (uint64 subscriptionId)
    {
        subscriptionId = createSubscription(getVRFCoordinator());
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64 subscriptionId) {
        vm.startBroadcast();
        subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
        console.log("Subscription is created & id is:", subscriptionId);
        vm.stopBroadcast();
    }

    function getVRFCoordinator() private returns (address vrfCoordinator) {
        HelperConfig helperConfig = new HelperConfig();

        (
            ,
            ,
            ,
            ,
            /*network*/
            vrfCoordinator,
            ,
            ,
            ,

        ) = helperConfig.activeNetworkConfig();
    }

    function run() external returns (uint64 subId) {
        subId = createSubscriptionUsingHelperConfig();
    }
}
