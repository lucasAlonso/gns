//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Registry.sol";

contract Exchange is ERC20 {
    address public tokenAddress;
    address public registryAddress;
    uint16 public fee;

    constructor(address _token) ERC20("EXCOIN", "EXC") {
        require(_token != address(0), "token invalido");
        //para agregar, validar si es un ERC20
        fee = 9950;
        tokenAddress = _token;
        registryAddress = msg.sender;
    }

    function addLiquidity(uint256 _tokenAmount)
        public
        payable
        returns (uint256)
    {
        uint256 mintedTokens;
        if (totalSupply() == 0) {
            mintedTokens = address(this).balance;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 correctTokenAmount = (msg.value * tokenReserve) /
                ethReserve;
            require(_tokenAmount >= correctTokenAmount, "eth insuficiente");
            mintedTokens = (totalSupply() * msg.value) / ethReserve;
        }
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        _mint(msg.sender, mintedTokens);
        return mintedTokens;
    }

    function removeLiquidity(uint256 _amount)
        public
        returns (uint256, uint256)
    {
        require(_amount > 0, "invalid amount");
        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();

        _burn(msg.sender, _amount); // si el usuario no tiene esa cantidad de tokens el burn falla y se revierte

        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private view returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "reservas invalidas");
        uint256 inputAmountWithFee = inputAmount * fee;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 10000) + inputAmountWithFee;
        return numerator / denominator;
    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "amount not valid");

        uint256 tokenReserve = getReserve();
        return _getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "amount not valid");

        uint256 tokenReserve = getReserve();
        return _getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToToken(uint256 _minTokens, address recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = _getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        require(
            tokensBought >= _minTokens,
            "transaccion no cumple los requisitos"
        );
        IERC20(tokenAddress).transfer(recipient, tokensBought);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    function ethToTokenTransfer(uint256 _mintTokens, address _recipient)
        public
        payable
    {
        ethToToken(_mintTokens, _recipient);
    }

    function tokenToEthSwap(uint256 _tokenSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = _getAmount(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );

        require(ethBought > _minEth, "no cumplo los requisitos");
        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenSold
        );
        payable(msg.sender).transfer(ethBought);
    }

    function tokenToTokenSwap(
        uint256 _tokenSold,
        uint256 _minTokensBought,
        address _tokenAddress
    ) public {
        address exchangeAddress = Registry(registryAddress).getExchange(
            _tokenAddress
        );
        require(exchangeAddress != address(0), "no registry for that token");
        require(exchangeAddress != address(this), "invalid exchange address");

        uint256 tokenReserve = getReserve();
        uint256 ethBought = _getAmount(
            _tokenSold,
            tokenReserve,
            address(this).balance
        );

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenSold
        );

        Exchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(
            _minTokensBought,
            msg.sender
        );
    }

    function changeFee(uint16 _newFee) public {
        require(_newFee != 0, "new fee must be not 0");
        fee = _newFee;
    }
}
