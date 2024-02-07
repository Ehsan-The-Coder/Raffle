// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../deploy/HelperConfig.s.sol";
import {LinkToken} from "../deploy/mock/src/LinkToken.sol";

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        (
            address vrfCoordinator,
            uint64 subscriptionId,
            address link,
            uint256 deployerKey
        ) = getHelperVariables();

        fundSubscription(vrfCoordinator, subscriptionId, link, deployerKey);
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subscriptionId,
        address link,
        uint256 deployerKey
    ) public {
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }

        console.log("Subscription is funded....");
        console.log("SubscriptionId: ", subscriptionId);
        console.log("VRFCoordinatorV2: ", vrfCoordinator);
        console.log("Link: ", link);
        console.log("Amount: ", FUND_AMOUNT);
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }

    function getHelperVariables()
        private
        returns (
            address vrfCoordinator,
            uint64 subscriptionId,
            address link,
            uint256 deployerKey
        )
    {
        HelperConfig helperConfig = new HelperConfig();

        (
            ,
            ,
            vrfCoordinator,
            subscriptionId,
            ,
            ,
            link,
            deployerKey
        ) = helperConfig.activeNetworkConfig();
    }
}
