// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    uint256 minNoOfPlayers; //minimum player needed for withdraw
    uint256 entranceFee; //fee to enter in raffle
    uint256 interval; //time in seconds
    address vrfCoordinator;
    uint64 subscriptionId;
    bytes32 keyHash; //GasLane
    uint32 callBackGasLimit;
    address link;

    Raffle public raffle;
    HelperConfig public helperConfig;

    function run() external returns (Raffle, HelperConfig) {
        //get all the cosntructor variable from helper config
        //based on the chain we are on
        helperConfig = new HelperConfig();
        (
            ,
            /*network*/
            minNoOfPlayers,
            entranceFee,
            interval,
            vrfCoordinator,
            subscriptionId,
            keyHash,
            callBackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        raffle = new Raffle(
            minNoOfPlayers,
            entranceFee,
            interval,
            vrfCoordinator,
            subscriptionId,
            keyHash,
            callBackGasLimit
        );
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
