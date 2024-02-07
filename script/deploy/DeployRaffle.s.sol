// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Subscription} from "../subscription/Subscription.s.sol";

contract DeployRaffle is Script {
    uint256 entranceFee; //fee to enter in raffle
    uint256 interval; //time in seconds
    address vrfCoordinator;
    uint64 subscriptionId;
    bytes32 keyHash; //GasLane
    uint32 callBackGasLimit;
    address link;
    uint256 deployerKey;

    Raffle public raffle;
    HelperConfig public helperConfig;
    Subscription subscription;

    function run() external returns (Raffle, HelperConfig) {
        setHelperValues();
        setSubcriptions();

        vm.startBroadcast(deployerKey);
        raffle = new Raffle(
            entranceFee,
            interval,
            vrfCoordinator,
            subscriptionId,
            keyHash,
            callBackGasLimit
        );
        vm.stopBroadcast();

        setConsumer();
        return (raffle, helperConfig);
    }

    function setHelperValues() private {
        //get all the cosntructor variable from helper config
        //based on the chain we are on
        helperConfig = new HelperConfig();
        (, , , , keyHash, callBackGasLimit, link, deployerKey) = helperConfig
            .activeNetworkConfig();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            subscriptionId,
            ,
            ,
            ,

        ) = helperConfig.activeNetworkConfig();
    }

    function setSubcriptions() private {
        //get the subscription manager
        //create subscription on chainlink based on chainId,
        // fund it and add consumer which is in over case is raffle contract
        subscription = new Subscription();
        if (subscriptionId == 0) {
            subscriptionId = subscription.createSubscription(
                vrfCoordinator,
                deployerKey
            );
            subscription.fundSubscription(
                vrfCoordinator,
                subscriptionId,
                link,
                deployerKey
            );
        }
    }

    function setConsumer() private {
        subscription.addConsumer(
            vrfCoordinator,
            subscriptionId,
            address(raffle),
            deployerKey
        );
    }
}
