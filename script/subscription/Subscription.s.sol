// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {CreateSubscription} from "./CreateSubscription.s.sol";
import {FundSubscription} from "./FundSubscription.s.sol";
import {AddConsumer} from "./AddConsumer.s.sol";

contract Subscription is Script {
    CreateSubscription public create = new CreateSubscription();
    FundSubscription public fund = new FundSubscription();
    AddConsumer public consumer = new AddConsumer();

    function createSubscriptionUsingConfig()
        public
        returns (uint64 subscriptionId)
    {
        subscriptionId = create.createSubscriptionUsingConfig();
    }

    function createSubscription(
        address vrfCoordinator,
        uint256 deployerKey
    ) public returns (uint64 subscriptionId) {
        subscriptionId = create.createSubscription(vrfCoordinator, deployerKey);
    }

    function fundSubscriptionUsingConfig() public {
        fund.fundSubscriptionUsingConfig();
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subscriptionId,
        address link,
        uint256 deployerKey
    ) public {
        fund.fundSubscription(
            vrfCoordinator,
            subscriptionId,
            link,
            deployerKey
        );
    }

    function addConsumer(
        address vrfCoordinator,
        uint64 subscriptionId,
        address vrfConsumer,
        uint256 deployerKey
    ) public {
        consumer.addConsumer(
            vrfCoordinator,
            subscriptionId,
            vrfConsumer,
            deployerKey
        );
    }

    function run() external {}
}
