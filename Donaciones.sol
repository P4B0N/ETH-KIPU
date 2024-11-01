// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Donaciones2 {

    struct Donacion {
        address donante;
        uint cantidad;
        uint fecha;
    }

    Donacion[] public donaciones;

    mapping (address => uint256) public balance;
    
    address[] public uniqueAddr;

    event DonacionRealizada(address indexed donante, uint256 cantidad, uint256 fecha);

    function donar() external payable {
        donaciones.push(Donacion(msg.sender,msg.value,block.timestamp));
        if(balance[msg.sender]==0) {
            uniqueAddr.push(msg.sender);
        }
        balance[msg.sender] +=  msg.value;
        emit DonacionRealizada(msg.sender,msg.value,block.timestamp);
    }

    function obtenerDonaciones() external view returns (Donacion[] memory _donaciones) {
        uint256 len = uniqueAddr.length;
        for(uint256 i=0; i< len; i++) {
            _donaciones[i] = Donacion(uniqueAddr[i],balance[uniqueAddr[i]],block.timestamp);
        }
        return _donaciones;
    }
}