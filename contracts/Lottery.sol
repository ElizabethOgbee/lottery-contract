// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

//MAIN FUNCTIONS FOR OUR LOTTERY GAME: ENTER(), STARTGAME(), ENDGAME(), WITHDRAWAMOUNT()

contract Lottery is Ownable, VRFConsumerBase {
    address payable[] public players;
    uint256 usdEntryFee;
    Aggregator internal ethUSDPriceFeed;
    LOTTERY_STATE public lottery_state;
    uint256 public fee;
    bytes32 public keyHash;
    event RequestedRandomness(bytes32 requestID);
    // uint256 public randomness;
    // address payable public recentWinner;

    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCUATING_WINNER
    }

    constructor(
        address _priceFeedAddress,
        address _vrfCordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
         ) public VRFConsumerBase(_vrfCordinator, _link) {
        usdEntryFee = 50 * (10 ** 18); ///@user: fee in usd is set to 50 dollars
        ethUSDPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    function getEntranceFee() public view returns (uint256) {
        //get the price feed and round the price
        (, uint256 price, , , ) = ethUSDPriceFeed.latestRounfData();
        // Since we know we're going to be using an ethereum / usd pricefeed that has eight decimals.Let's also just convert it to having 18 decimals as well.
        uint256 adjustedPrice = uint256(price) * 10 ** 10;
        // Now that we've adjusted price we'll do:
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / price;
        return costToEnter;
    }

    function enterGame() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        //50$ minimum
        require(msg.value >= getEntranceFee(), "NOT ENOUGH ETH!");
        players.push(msg.sender);
    }

    function startGame() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "CANT START A NEW LOTTEY YET!"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endGame() public {
        lottery_state = LOTTERY_STATE.CALCUATING_WINNERS;
        bytes32 requestId = requestRandomness(keyHash, fee);
    }
//WE MADE THS FUNCTION INTERNAL BECAUSE WE ONLY WANT OUR CHAINLINK TO CALL IT
// It's internal because actually the chainlink node is calling the 
// vrfCoordinator and then the vrfCoordinator is calling our fulfillRandomness. So 
// we made it internal so that only the vrfCoordinator can be the one to call and 
// return this function.
    function fullfillRandomness(bytes32 _requestId, uint256 _randomness) internal override{
        require(lottery_state == LOTTERY_STATE.CALCUATING_WINNER, "YOU AREN'T THERE YET");
        require(_randomness > 0, "RANDOM NOT FOUND");
        uint256 indexOfWinner = _randomness % players.length;
             recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).address);

        //RESET THE ARRAY
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CALCUATING_CLOSED;
            randomness = _randomness;

            emit RequestedRandomness(requestID);
    }

    function withdrawGame() public payable {}
}

//  Now we're going to want to do a little bit of quick math.
// Typically if we're setting the price at $50 and we've a
//  pricefeed of $2000 per eth, we'd just wanna do 50/2000 but
//   ofcourse solidity doesn't work with decimals we can't
//   actually just do this.So we'll have to do 50 *
//   (somebignumber) / 2000.But first convert the price from
//   int256 to uint256.
