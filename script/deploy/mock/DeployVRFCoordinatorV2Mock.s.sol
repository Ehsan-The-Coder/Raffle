// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {VRFCoordinatorV2Mock} from "../../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract DeployVRFCoordinatorV2Mock is Script {
    uint96 private constant BASE_FEE = 0.25 ether;
    uint96 private constant GAS_PRICE_LINK = 1e9;

    function run()
        external
        returns (VRFCoordinatorV2Mock vrfCoordinatorV2Mock)
    {
        vm.startBroadcast();
        vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            BASE_FEE,
            GAS_PRICE_LINK
        );
        vm.stopBroadcast();
    }
}
