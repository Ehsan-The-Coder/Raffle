// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

//<-----------------------------imports--------------------------->
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

/**
 * @title Raffle the decentralized way of buying lottery
 * @author Muhammad Ehsan
 * @notice This project uses the chainlink VRF(Verifiable Random Function) & Upkeeps
 * to get the true  random number and automatically chosen the winner after the interval is passed
 */
contract Raffle is VRFConsumerBaseV2, AutomationCompatible {
    //<-----------------------------type declarations--------------------------->
    //help to check wether the winner is being chosen
    //or available for entrance
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    //<-----------------------------state variables--------------------------->
    //raffle variables

    //how many players atleast have before withdraw
    uint256 private constant MIN_NO_OF_PLAYERS = 2;
    address[] private s_players;
    uint256 private immutable i_entranceFee;
    //time period after which the raffle automattically withdraws
    //withdraw time =current timestamp+interval
    uint256 private immutable i_interval;
    //is used to store the latest/previous withdraw
    //which help us to calculate next time to withdraw raffle
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    //
    //
    //
    //chainlink essentail variable for VRF and Automations
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callBackGasLimit;
    uint8 private constant REQUEST_CONFIRMATIONS = 3;
    uint8 private constant NUM_OF_WORDS = 1;

    //<-----------------------------event--------------------------->
    event RaffleEntered(address indexed player);
    event RequestedRaffleWinnner(uint256 indexed requestId);
    event WinnerPicked(address indexed recentWinner);

    //<-----------------------------custom error--------------------------->
    error Raffle__NotEnoughEthSended();
    error Raffle__IsNotOpen();
    error Raffle__TransferFailed();
    error Raffle__UpkeepNotNeeded(
        uint256 raffleState,
        uint256 timeInterval,
        uint256 playersLength,
        uint256 currentBalance
    );

    //<-----------------------------modifiers--------------------------->
    modifier isEnoughEth() {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthSended();
        }
        _;
    }
    modifier isRaffleOpen() {
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__IsNotOpen();
        }
        _;
    }
    modifier isUpkeepNeeded() {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            uint256 timeInterval = block.timestamp - s_lastTimestamp;
            revert Raffle__UpkeepNotNeeded(
                uint256(s_raffleState),
                timeInterval,
                s_players.length,
                address(this).balance
            );
        }
        _;
    }

    //<-----------------------------special functions--------------------------->
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinatorV2Interface,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinatorV2Interface) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_raffleState = RaffleState.OPEN;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2Interface);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        i_callBackGasLimit = callBackGasLimit;
        s_lastTimestamp = block.timestamp;
    }

    receive() external payable {
        enterRaffle();
    }

    fallback() external payable {
        enterRaffle();
    }

    //<-----------------------------external functions--------------------------->
    /**
     * @dev Performs the necessary upkeep for the raffle.
     * This function changes the state of the raffle to CALCULATING and requests a random word from the Chainlink VRF.
     * Once the random word is received, the winner of the raffle is determined and the raffle state is reset to OPEN.
     * param calldata Unused in this function.
     */
    function performUpkeep(bytes calldata) external override isUpkeepNeeded {
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_OF_WORDS
        );
        emit RequestedRaffleWinnner(requestId);
    }

    //<-----------------------------external view/pure functions--------------------------->
    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getPlayers() external view returns (address[] memory) {
        return s_players;
    }

    function getPlayersLength() external view returns (uint256) {
        return s_players.length;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getMinimumPlayer() external view returns (uint256) {
        return MIN_NO_OF_PLAYERS;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getVRFCoordinator()
        external
        view
        returns (VRFCoordinatorV2Interface)
    {
        return i_vrfCoordinator;
    }

    function getSubscriptionId() external view returns (uint64) {
        return i_subscriptionId;
    }

    function getLastTimestamp()
        external
        view
        returns (uint256 lastTimeWithdraw)
    {
        lastTimeWithdraw = s_lastTimestamp;
    }

    function getKeyHash() external view returns (bytes32) {
        return i_keyHash;
    }

    function getCallBackGasLimit() external view returns (uint32) {
        return i_callBackGasLimit;
    }

    function getRequestConfirmations() external pure returns (uint8) {
        return REQUEST_CONFIRMATIONS;
    }

    function getNumberOfWords() external pure returns (uint8) {
        return NUM_OF_WORDS;
    }

    //<-----------------------------public functions--------------------------->
    /**
     * @dev Allows a user to enter the raffle.
     * Each ticket costs the entrance fee specified during contract deployment.
     * Users can enter the raffle multiple times, each time purchasing a new ticket.
     */
    function enterRaffle() public payable isEnoughEth isRaffleOpen {
        s_players.push(msg.sender);
        emit RaffleEntered(msg.sender);
    }

    //<-----------------------------public view/pure functions--------------------------->
    /**
     * @dev Checks whether upkeep is needed based on the current state of the raffle.
     * Upkeep is needed if the raffle is open, enough time has passed since the last draw, there are enough players, and the contract has enough balance.
     * param _data Unused in this function.
     * @return upkeepNeeded A boolean indicating whether upkeep is needed.
     * return performData Unused in this function.
     */
    function checkUpkeep(
        bytes memory
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimestamp) > i_interval);
        bool hasPlayers = (s_players.length > MIN_NO_OF_PLAYERS);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    //<-----------------------------internal functions--------------------------->
    /**
     * @dev Fulfills the random words generated by the Chainlink VRF.
     * Uses the random word to choose a winner from the pool of players.
     * Transfers the entire balance of the contract to the winner.
     * param _requestId The ID of the request sent to the Chainlink VRF.
     * @param randomWords The random words generated by the Chainlink VRF.
     */
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        s_recentWinner = s_players[winnerIndex];
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimestamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);
        (bool success, ) = s_recentWinner.call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
}
