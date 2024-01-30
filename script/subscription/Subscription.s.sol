// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {CreateSubscription} from "./CreateSubscription.s.sol";
import {FundSubscription} from "./FundSubscription.s.sol";

contract Subscription is Script {
    CreateSubscription public create = new CreateSubscription();
    FundSubscription public fund = new FundSubscription();

    function createSubscriptionUsingHelperConfig()
        public
        returns (uint64 subscriptionId)
    {
        subscriptionId = create.createSubscriptionUsingHelperConfig();
    }

    function createSubscription(
        address vrfCoordinator
    ) public returns (uint64 subscriptionId) {
        subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator)
            .createSubscription();
    }

    function fundSubscriptionUsingHelperConfig() public {
        fund.fundSubscriptionUsingHelperConfig();
    }

    function fundSubscription(
        address vrfCoordinator,
        uint64 subscriptionId,
        address link
    ) public {
        fund.fundSubscription(vrfCoordinator, subscriptionId, link);
    }

    function run() external {}
}
