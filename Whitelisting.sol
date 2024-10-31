// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Whitelisting {
    mapping (address => bool) public whitelist;
    uint256 public counter;
    uint256 public receiveCounter;
    uint256 public fallbackCounter;
    
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
        receive() external payable { 
        receiveCounter++;
    }

    fallback() external payable {
        fallbackCounter++;
     }

    function withdraw() external {
        address _contrato = address(this);
        uint256 _balance = _contrato.balance;
        payable(msg.sender).transfer(_balance);
     }

}