// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
contract Lottery{
    address payable[] public player;
    //MAIN FUNCTIONS FOR OUR LOTTERY GAME: ENTER(), STARTGAME(), ENDGAME(), WITHDRAWAMOUNT()
    constructor() public{
        usdEntryFee = 50 * (10 ** 18);
    }
    function get entranceFee() public view returns(uint256){}
    function enterGame() public payable {
        players.push(msg.sender);
    }

    function startGame()public{}

    function endGame()public{}

    function withdrawGame()public{}


}


