// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DeployVRFCoordinatorV2Mock} from "../deploy/mock/DeployVRFCoordinatorV2Mock.s.sol";
import {DeployLinkToken} from "../deploy/mock/DeployLinkToken.s.sol";

error HelperConfig__ChainIdNotAvailable(uint256 chainId);

contract HelperConfig is Script {
    struct NetworkConfig {
        string network;
        uint256 minNoOfPlayers; //minimum player needed for withdraw
        uint256 entranceFee; //fee to enter in raffle
        uint256 interval; //time in seconds
        address vrfCoordinator;
        uint64 subscriptionId;
        bytes32 keyHash; //GasLane
        uint32 callBackGasLimit; //in gwei
        address link;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilEthConfig();
        } else {
            revert HelperConfig__ChainIdNotAvailable(block.chainid);
        }
    }

    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory networkConfig)
    {
        networkConfig = NetworkConfig({
            network: "sepolia",
            minNoOfPlayers: 2,
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            subscriptionId: 5281,
            keyHash: bytes32(
                uint256(
                    keccak256(
                        "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c"
                    )
                )
            ),
            callBackGasLimit: 600000,
            link: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        });
    }

    function getAnvilEthConfig()
        public
        returns (NetworkConfig memory networkConfig)
    {
        networkConfig = NetworkConfig({
            network: "Anvil",
            minNoOfPlayers: 5,
            entranceFee: 1 ether,
            interval: 60 * 60, //one hour
            vrfCoordinator: deployVRFCoordinatorV2MockAndReturnAddress(),
            subscriptionId: 0,
            keyHash: bytes32(
                uint256(
                    keccak256(
                        "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c"
                    )
                )
            ),
            callBackGasLimit: 600000,
            link: deployLinkTokenMockAndReturnAddress()
        });
    }

    function deployVRFCoordinatorV2MockAndReturnAddress()
        private
        returns (address vrfCoordinatorV2)
    {
        DeployVRFCoordinatorV2Mock deployVRFCoordinatorV2Mock = new DeployVRFCoordinatorV2Mock();
        vrfCoordinatorV2 = address(deployVRFCoordinatorV2Mock.run());
    }

    function deployLinkTokenMockAndReturnAddress()
        private
        returns (address linkToken)
    {
        DeployLinkToken deployLinkToken = new DeployLinkToken();
        linkToken = address(deployLinkToken.run());
    }
}
