// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract Padre {
    string hola="soy el padre";
    function quienSoy() public view virtual  returns(string memory) { return(hola); 
    }
}
contract Madre {
    string hola2="soy la madre";
    function quienSoy() public view virtual returns(string memory) { return(hola2); 
    }
}
contract hijo is Padre, Madre {
    string hola3="soy el hijo";
    function quienSoy() public view override(Madre, Padre) returns (string memory) {
        return hola3;
        //return super.quienSoy(); 
    }
}
