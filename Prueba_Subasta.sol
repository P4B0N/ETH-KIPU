// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Subasta {
    uint256 public valorInicial;
    uint256 public fechaInicio;
    uint256 public  tiempoDuracion;
    uint256 private mayorOferta;
    address private ofertanteGanador;
    address private owner;
    uint8 private semaforo;
    mapping (address => uint256) public valorMetido;

    constructor() {
        owner =msg.sender;
        valorInicial = 1 gwei;
        fechaInicio = block.timestamp;
        tiempoDuracion = fechaInicio +7 days;
    }

    function getOferenteGanador() external view returns (address) {
        return ofertanteGanador;
    }

    function getMoayorOferta() external view returns (uint256) {
        return mayorOferta;
    }

    function setOferta() external payable {
        require(semaforo==0,"La subasta ha finalizado");
        uint256 _valorOfertado = msg.value;
        require(_valorOfertado>valorInicial,"El valor es menor al inicial");
        if(_valorOfertado > mayorOferta) {
            address _addrOferente = msg.sender;
            mayorOferta = _valorOfertado;
            ofertanteGanador = _addrOferente;
            valorMetido[_addrOferente] += _valorOfertado;
        }else{
            revert("No supera el valor");
        }
    }

    function finalizarSubasta() external  {
        require(owner==msg.sender,"Usted no tiene permisos");
        semaforo = 1;
    }
}