// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Whitelisting {
    mapping (address => bool) public whitelist;
    uint256 public counter;
    
    modifier onlyWhitelisted (){
        require(whitelist[msg.sender],"No estas whitelisteado");
        _;
    }

    function incCounter() public onlyWhitelisted {
        counter++;
    }

    function setWhitelist (address _addr) public {
        whitelist [_addr] = true;
    }

}