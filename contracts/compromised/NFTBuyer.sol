// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TrustfulOracle.sol";
import "../DamnValuableNFT.sol";
import "./Exchange.sol";

/**
 * @title Exchange
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract NFTBuyer {
    
    address payable owner;
    uint256 tokenId;
    Exchange exchange;

    constructor() {
        owner = payable(msg.sender);
    }

    function buyToken(Exchange _exchange) external payable {
        exchange = _exchange;
        tokenId = exchange.buyOne{value: msg.value}();
    }

    function sellToken(DamnValuableNFT nft) external {
        nft.approve(address(exchange), tokenId);
        exchange.sellOne(tokenId);
        owner.transfer(address(this).balance);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {

    }
}