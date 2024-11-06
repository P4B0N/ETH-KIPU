// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

//Herencia, Interface, abstract, llamada entre contratos:
    
interface IERC20 {
    //function balanceOf(address) external virtual view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

abstract contract ERC20Base is IERC20 {
    uint internal balance=100;
}

contract ERC20 is ERC20Base {
    function balanceOf(address) external override  view returns (uint256) {
        return balance;
    }
}

contract ICO {
    IERC20 usdt;

    constructor(IERC20 _usdt) {
        usdt = _usdt;
    }

    function getBalance() public view returns (uint256) {
        return usdt.balanceOf(address(this));
    }
}
