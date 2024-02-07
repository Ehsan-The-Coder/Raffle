//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/deploy/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/deploy/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test, Script {
    //<-----------------------------variable--------------------------->
    Raffle raffle;
    HelperConfig helperConfig;
    //
    //
    //raffle variables
    address private link;
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
    uint256 private constant MIN_NO_OF_PLAYERS = 2;
    // TEST Variable
    uint256 deployerKey;
    uint256 USERS_START_BALANCE = 10 ether;
    uint256 private constant OWNER_INDEX = 0;
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
        //given the function signature so fund function is called and tested
        bytes memory dataCallInBytes = abi.encodePacked(
            bytes4(keccak256("enterRaffle()"))
        );
        enterRaffle(dataCallInBytes);
        _;
    }
    modifier passTime() {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }
    modifier performUpkeep() {
        performUpkeepHelper();
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    //<---------------------------------------setUp------------------------------------------>
    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();
        setHelperValues();
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

    function setHelperValues() private {
        (, , , , keyHash, callBackGasLimit, , ) = helperConfig
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
        raffleState = Raffle.RaffleState.OPEN;
    }

    function enterRaffle(bytes memory functionSignature) public {
        // Arrange
        uint256 enterAmount;
        for (
            uint8 playerIndex = 0;
            playerIndex < players.length;
            playerIndex++
        ) {
            enterAmount += entranceFee;
            address player = players[playerIndex];
            vm.prank(player);
            vm.expectEmit(true, false, false, false, address(raffle));
            emit RaffleEntered(player);

            // ACT
            (bool callSuccess, ) = address(raffle).call{value: entranceFee}(
                functionSignature
            );

            // Assert
            assert(callSuccess);
            assert(enterAmount == address(raffle).balance);
            assert(player == raffle.getPlayer(playerIndex));
            assert(playerIndex + 1 == raffle.getPlayersLength());
        }
        address[] memory playersBuyRaffle = raffle.getPlayers();
        for (
            uint8 playerIndex = 0;
            playerIndex < players.length;
            playerIndex++
        ) {
            address expectedPlayer = players[playerIndex];
            address actualPlayer = playersBuyRaffle[playerIndex];
            assert(expectedPlayer == actualPlayer);
        }
    }

    function performUpkeepHelper() private returns (uint256 requestedId) {
        //Arrange
        //upkeepNeeded is passed
        // ACT
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory eventEntries = vm.getRecordedLogs();
        bytes32 requestId = eventEntries[1].topics[1];
        requestedId = uint256(requestId);
        assert(requestedId > 0);
        raffleState = Raffle.RaffleState.CALCULATING;
        assert(raffleState == raffle.getRaffleState());
    }

    //<---------------------------------------test------------------------------------------>
    ////////////////////////////
    ///////Constructor/////////
    //////////////////////////

    function testConstructor() external {
        assert(entranceFee == raffle.getEntranceFee());
        assert(interval == raffle.getInterval());
        assert(vrfCoordinator == address(raffle.getVRFCoordinator()));
        assert(keyHash == raffle.getKeyHash());
        assert(raffle.getSubscriptionId() != 0);
        assert(callBackGasLimit == raffle.getCallBackGasLimit());
        assert(raffleState == raffle.getRaffleState());
        assert(block.timestamp == raffle.getLastTimestamp());
    }

    ////////////////////////////
    ///////Constant////////////
    //////////////////////////
    function testConstants() external {
        assert(REQUEST_CONFIRMATIONS == raffle.getRequestConfirmations());
        assert(MIN_NO_OF_PLAYERS == raffle.getMinimumPlayer());
        assert(REQUEST_CONFIRMATIONS == raffle.getRequestConfirmations());
    }

    ///////////////////////////
    //////enterRaffle/////////
    //////////////////////////
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

    function testEnterRaffle() external buyRaffle {
        //already tested in the modifier
    }

    function testEnterRaffleRevertIfRaffleCalculating()
        external
        buyRaffle
        passTime
    {
        //Arrange
        raffle.performUpkeep("");
        //Act/Assert
        vm.expectRevert(Raffle.Raffle__IsNotOpen.selector);
        raffle.enterRaffle{value: entranceFee}();
    }

    ////////////////////////////
    //fallbacek and receive////
    //////////////////////////
    function testFallback() public {
        //data is passed so fallback function is trigered
        string memory dataForCall = "0x1234"; // Non-empty data payload
        bytes memory dataCallInBytes = bytes(dataForCall);
        enterRaffle(dataCallInBytes);
    }

    function testReceive() public {
        //no data is passed so receive function is trigered
        string memory dataForCall = "";
        bytes memory dataCallInBytes = bytes(dataForCall);
        enterRaffle(dataCallInBytes);
    }

    ////////////////////////////
    //////checkUpkeep//////////
    //////////////////////////
    function testCheckUpkeepFalseIfRaffleIsOpen() external buyRaffle passTime {
        //Arrange
        //with buyRaffle hasPlayer=true and hasBalance=true
        //passtime=true
        //raffle is in calculating state
        raffle.performUpkeep("");
        //Act/Assert
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepFalseIfTimeIntervalNotPass() external buyRaffle {
        //with buyRaffle hasPlayer=true and hasBalance=true
        //Raffle is in open state
        //passtime=false
        //Act/Assert
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepFalseIfNotEnoughPlayers() external {
        //Arrange
        uint256 playerIndex = 1;
        address player = players[playerIndex];
        vm.prank(player);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //hasBalance=true;timePassed=true;hasBalance=true;
        //only minimumPlayer=false
        // Assert
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepFalseIfBalanceIsZero() external buyRaffle {
        //Arrange
        //all parameters are true
        //only balacne is zero
        vm.deal(address(raffle), 0);
        // Assert
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeep() external buyRaffle passTime {
        //Arrange
        //all parameters are true
        // Assert
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    ////////////////////////////
    //////performUpkeep////////
    //////////////////////////
    function testPerformUpkeepRevertUpkeepNotNeeded() external buyRaffle {
        //revert as time is not passed
        //Act/Assert
        uint256 currentRaffleState = 0;
        uint256 timeInterval = block.timestamp - raffle.getLastTimestamp();
        uint256 plasyerLength = raffle.getPlayersLength();
        uint256 balance = address(raffle).balance;
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentRaffleState,
                timeInterval,
                plasyerLength,
                balance
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeep() external buyRaffle passTime performUpkeep {
        //this is tested via modifer
    }

    ////////////////////////////
    /////fulfillRandomWords////
    //////////////////////////
    function testFulFillRandomWordsRevertWhenPerformUpkeepNotNeeded(
        uint256 requestId
    ) external skipFork buyRaffle passTime {
        // Arrange
        // Act / Assert
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );
    }

    function testFulfillRandomWords() external skipFork buyRaffle passTime {
        uint256 requestId = performUpkeepHelper();
        uint256 expectedBalance = USERS_START_BALANCE -
            entranceFee +
            (entranceFee * (raffle.getPlayersLength()));

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            requestId,
            address(raffle)
        );

        recentWinner = raffle.getWinner();
        uint256 winnerBalance = address(recentWinner).balance;
        uint256 contractBalance = address(raffle).balance; //expect 0 as all transfer to winner
        uint256 playersLength = raffle.getPlayersLength(); //0
        raffleState = raffle.getRaffleState();

        assert(expectedBalance == winnerBalance);
        assert(contractBalance == 0);
        assert(playersLength == 0);
        assert(raffleState == Raffle.RaffleState.OPEN);
    }
}
