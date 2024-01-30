// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

import {LinkToken} from "./src/LinkToken.sol";

contract DeployLinkToken is Script {
    function run() external returns (LinkToken linkToken) {
        vm.startBroadcast();
        linkToken = new LinkToken();
        vm.stopBroadcast();
    }
}
