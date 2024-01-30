//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/deploy/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/deploy/HelperConfig.s.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract RaffleTest is Test {
    //<-----------------------------variable--------------------------->
    Raffle raffle;
    HelperConfig helperConfig;
    //
    //
    //raffle variables
    string private network;
    address private link;
    uint256 private minNoOfPlayers;
    uint256 private entranceFee;
    uint256 private interval;
    uint256 private lastTimestamp;
    address private recentWinner;
    Raffle.RaffleState private raffleState;
    address private vrfCoordinator;
    uint64 private subscriptionId;
    bytes32 private keyHash;
    uint32 private callBackGasLimit;
    uint8 private constant REQUEST_CONFIRMATIONS = 3;
    uint8 private constant NUM_OF_WORDS = 1;
    // TEST Variable
    uint256 USERS_START_BALANCE = 10 ether;
    address[10] public players = [
        address(1),
        address(2),
        address(3),
        address(4),
        address(5),
        address(6),
        address(7),
        address(8),
        address(9),
        address(10)
    ];

    //<-----------------------------event--------------------------->
    event RaffleEntered(address indexed player);
    event RequestedRaffleWinnner(uint256 requestId);
    event WinnerPicked(address indexed recentWinner);

    //<---------------------------------------modifier------------------------------------------>
    modifier buyRaffle() {
        // Arrange
        uint256 playersLength = players.length;
        uint256 enterAmount;
        for (
            uint8 playerIndex = 0;
            playerIndex < playersLength;
            playerIndex++
        ) {
            uint256 totalPlayerEnterInRaffle = playerIndex + 1;
            enterAmount += entranceFee;

            address player = players[playerIndex];
            vm.prank(player);
            vm.expectEmit(true, false, false, false, address(raffle));
            emit RaffleEntered(player);

            // ACT
            raffle.enterRaffle{value: entranceFee}();

            // Assert
            assert(enterAmount == address(raffle).balance);
            assert(player == raffle.getPlayer(playerIndex));
            assert(totalPlayerEnterInRaffle == raffle.getPlayersLength());
        }
        _;
    }

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        setStartValues();
        fundUsersAccount();
    }

    //<---------------------------------------helper functions------------------------------------------>
    function fundUsersAccount() private {
        uint256 playersLength = players.length;
        for (
            uint8 playerIndex = 0;
            playerIndex < playersLength;
            playerIndex++
        ) {
            address player = players[playerIndex];
            vm.deal(player, USERS_START_BALANCE);
        }
    }

    function setStartValues() private {
        (
            network,
            minNoOfPlayers,
            entranceFee,
            interval,
            vrfCoordinator,
            subscriptionId,
            keyHash,
            callBackGasLimit,
            link
        ) = helperConfig.activeNetworkConfig();
        raffleState = Raffle.RaffleState.OPEN;
    }

    //<---------------------------------------test------------------------------------------>
    function testAreConstructorValuesSetProperly() external {
        assert(minNoOfPlayers == raffle.getMinimumPlayer());
        assert(entranceFee == raffle.getEntranceFee());
        assert(interval == raffle.getInterval());
        assert(vrfCoordinator == address(raffle.getVRFCoordinator()));
        assert(keyHash == raffle.getKeyHash());
        assert(subscriptionId == raffle.getSubscriptionId());
        assert(callBackGasLimit == raffle.getCallBackGasLimit());
        assert(raffleState == raffle.getRaffleState());
    }

    function testConstantValues() external {
        assert(REQUEST_CONFIRMATIONS == raffle.getRequestConfirmations());
        assert(NUM_OF_WORDS == raffle.getNumberOfWords());
    }

    function testEnterRaffleShouldRevertWhenNotEnoughEth() external {
        // Arrange
        uint256 playersLength = players.length;
        for (
            uint8 playerIndex = 0;
            playerIndex < playersLength;
            playerIndex++
        ) {
            address player = players[playerIndex];
            //expect revert by passing 0 ether/value
            //Act/Assert
            vm.expectRevert(Raffle.Raffle__NotEnoughEthSended.selector);
            raffle.enterRaffle();
        }
    }

    function testEnterRaffle() external buyRaffle {}
}
