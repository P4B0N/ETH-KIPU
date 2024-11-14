/**
 *Submitted for verification at sepolia.scrollscan.com on 2024-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/// @title Contrato de Subasta Buenos Aires
/// @dev Este contrato implementa una subasta donde los usuarios pueden ofertar, 
///      retirar reenbolsos parciales, y el propietario puede retirar las comisiones 
///      y la oferta ganadora una vez que reenbolsa a los postores y la subasta esta finalizada finaliza.
///      El contrato también maneja una extensión de tiempo si se colocan ofertas cerca del final de la subasta.
///
/// @notice Este contrato solo es accesible por el propietario para ciertas funciones
///         
///
/// @author Mario A. Parodi

contract AuctionBsAs {
    /// @dev Enum que representa los posibles estados de la subasta
    enum AuctionState { Active, Ended, DepositsRefunded, Completed }

    /// @notice Estado actual de la subasta
    AuctionState public auctionState;

    /// @notice Hora de finalización de la subasta
    uint public auctionEndTime;

    /// @notice Fondo acumulado por comisiones de la subasta
    uint public commissionFunds;

    /// @notice Oferta más alta actual
    uint public highestBid;

    /// @notice Dirección del postor con la oferta más alta
    address public highestBidder;

    /// @notice Dirección del propietario de la subasta
    address public owner;

    /// @notice Comisión que se aplica en reembolsos parciales (2%) para cubrir costos de gas
    uint constant COMMISSION = 2;

    /// @notice Incremento mínimo de la oferta, debe ser mayor o igual al 5% de la oferta ganadora
    uint constant MIN_INCREMENT = 5;

    /// @notice Tiempo de extensión de la subasta (10 minutos)
    uint constant TIME_EXTENSION = 10 minutes;

    /// @dev Mapeo de todas las ofertas realizadas por cada postor
    mapping(address => uint[]) public bidsHistory; // Almacena todas las ofertas de cada postor

    /// @dev Mapeo del total de las ofertas de cada postor
    mapping(address => uint) public totalBids; // Total de la oferta actual de cada postor

    /// @dev Mapeo del monto ya reembolsado parcialmente a cada postor
    mapping(address => uint) public partialRefundedAmount; // Monto total ya reembolsado parcialmente

    /// @dev Lista de postores que han participado en la subasta
    address[] public bidders;

    /// @dev Modificador para asegurar que solo el propietario pueda ejecutar la función
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion");
        _;
    }

    /// @dev Modificador para asegurar que la subasta esté activa
    modifier onlyDuringActiveAuction() {
        require(auctionState == AuctionState.Active, "La subasta no esta activa");
        _;
    }

    /// @dev Modificador para validar que la oferta sea válida (mayor al 5% de la oferta ganadora)
    modifier validBid(uint amount) {
        require(amount >= highestBid + ((highestBid * MIN_INCREMENT) / 100),
            "La oferta debe ser al menos un 5% mayor que la oferta ganadora.");
        _;
    }

    /// @dev Modificador para asegurar que la subasta ya ha finalizado
    modifier onlyAfterAuctionEnded() {
        require(block.timestamp >= auctionEndTime, "La subasta no ha terminado");
        _;
    }

    /// @dev Modificador para asegurar que los depósitos hayan sido reembolsados antes de ejecutar la función
    modifier onlyAfterDepositsRefunded() {
        require(auctionState == AuctionState.DepositsRefunded, "Los depositos no han sido reembolsados.");
        _;
    }

    /// @notice Evento que se emite cuando un postor realiza una nueva oferta
    /// @param bidder Dirección del postor
    /// @param amount Monto de la oferta realizada
    event BidPlaced(address indexed bidder, uint amount);

    /// @notice Evento que se emite cuando se realiza un reembolso parcial
    /// @param bidder Dirección del postor
    /// @param amount Monto reembolsado
    event PartialRefund(address indexed bidder, uint amount);
    
    /// @notice Evento que se emite cuando la subasta es extendida
    /// @param newEndTime Nueva hora de finalización de la subasta
    event AuctionExtended(uint newEndTime);

    /// @notice Evento que se emite cuando la subasta termina mostrando el ganador y el monto ganador
    /// @param winner Dirección del postor ganador
    /// @param winningBid Monto de la oferta ganadora
    event AuctionEnded(address indexed winner, uint winningBid);

    /// @notice Evento que se emite cuando el owner reenbolsa 
    ///         los depositos a los postores
    /// @param bidder Dirección del postor
    /// @param amount Monto reenbolsado
    event DepositWithdrawn(address indexed bidder, uint amount);
       
    /// @notice Evento que se emite cuando el propietario retira las comisiones
    /// @param amount Monto retirado
    event CommissionsWithdrawn(uint amount);

    /// @notice Evento que se emite cuando el propietario retira la oferta ganadora
    /// @param amount Monto retirado
    event WinningBidWithdrawn(uint amount);

    /// @notice Evento que se emite cuando la subasta se ha completado exitosamente 
    /// @param success Indica si la subasta se completó sin errores (true si no hubo errores) 
    event AuctionCompleted(bool success);

    /// @dev Estructura que representa una oferta en la subasta
     struct Offer {
        address bidder; /// @dev Dirección del postor
        uint amount;    /// @dev Monto de la oferta
    }

    /// @dev Historial de todas las ofertas realizadas en la subasta
    Offer[] public offersHistory; // Almacena todas las ofertas en orden cronológico

    /// @notice Constructor de la subasta, establece el tiempo de duración
    /// @param _duration Duración de la subasta en segundos
    constructor(uint _duration) {
        require(_duration >= 20 minutes && _duration <= 7 days,
            "La duracion debe ser entre 20 minutos y 7 dias.");
        auctionEndTime = block.timestamp + _duration;
        auctionState = AuctionState.Active;
        owner = msg.sender;
    }

    /// @notice Permite a un postor realizar una oferta en la subasta
    /// @dev Solo es válida durante una subasta activa, y debe cumplir con los requisitos de oferta valida
    function placeBid() external payable onlyDuringActiveAuction validBid(msg.value) {
        require(block.timestamp <= auctionEndTime, "La subasta ha finalizado.");

        if (block.timestamp > auctionEndTime - TIME_EXTENSION) {
            auctionEndTime += TIME_EXTENSION;
            emit AuctionExtended(auctionEndTime);
        }

        uint newBid = msg.value;
        bidsHistory[msg.sender].push(newBid);
        totalBids[msg.sender] += newBid;

        // Almacenamos la oferta en el historial de ofertas en orden cronológico
        offersHistory.push(Offer(msg.sender, newBid));

        if (newBid > highestBid) {
            highestBid = newBid;
            highestBidder = msg.sender;
        }

        if (bidsHistory[msg.sender].length == 1) {
            bidders.push(msg.sender);
        }

        emit BidPlaced(msg.sender, newBid);
    }

    /// @notice Permite a cualquier usuario ver el historial completo de ofertas
    /// @return Un arreglo de ofertas realizadas en la subasta
    function viewOffers() external view returns (Offer[] memory) {
        return offersHistory;
    }

    /// @notice Permite a los postores solicitar un reembolso parcial de sus ofertas anteriores
    /// @dev Solo puede realizarse durante una subasta activa
    function partialRefund() external onlyDuringActiveAuction {
    require(auctionState != AuctionState.Completed, "La subasta ya ha sido completada.");
    uint totalPreviousBids = 0;
    uint[] storage userBids = bidsHistory[msg.sender];
    require(userBids.length > 1, "No hay ofertas anteriores para retirar.");

    // Suma de todas las ofertas previas, excluyendo la última
    for (uint i = 0; i < userBids.length - 1; i++) {
        totalPreviousBids += userBids[i];
    }

    // Calcular el monto reembolsable excluyendo el monto ya reembolsado
    uint refundableAmount = totalPreviousBids - partialRefundedAmount[msg.sender];
    require(refundableAmount > 0, "No hay saldo adicional para reembolsar.");

    // Actualizar el monto reembolsado para este usuario
    partialRefundedAmount[msg.sender] += refundableAmount;

    // Aplicar comisión
    uint commissionAmount = (refundableAmount * COMMISSION) / 100;
    uint refundAmount = refundableAmount - commissionAmount;

    // Actualizar el balance de la última oferta como la oferta total
    totalBids[msg.sender] = userBids[userBids.length - 1];

    // Incrementar el fondo de comisiones
    commissionFunds += commissionAmount;

    // Realizar el reembolso al postor
    (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
    require(success, "Fallo al realizar el reembolso parcial.");

    emit PartialRefund(msg.sender, refundAmount);
}

    /// @notice Permite ver los depósitos actuales de todos los postores
    /// @return Un arreglo con las direcciones de los postores y sus montos actuales
    function viewDeposits() external view returns (address[] memory, uint[] memory) {
        uint length = bidders.length;
        address[] memory addresses = new address[](length);
        uint[] memory amounts = new uint[](length);

        for (uint i = 0; i < length; i++) {
            address bidder = bidders[i];
            addresses[i] = bidder;
            amounts[i] = totalBids[bidder];
        }

        return (addresses, amounts);
    }

    /// @notice Finaliza la subasta, indicando el ganador y el monto ganador
    function endAuction() external onlyOwner onlyAfterAuctionEnded {
        require(auctionState == AuctionState.Active, "La subasta ya ha sido finalizada.");
        require(block.timestamp >= auctionEndTime, "La subasta aun no ha terminado.");
        auctionState = AuctionState.Ended;

        emit AuctionEnded(highestBidder, highestBid);
    }

    /// @notice Permite al propietario reembolsar los depósitos de los postores menos la oferta ganadora 
    ///         despues de marcar la subasta como finalizada   
    function withdrawDeposits() external onlyOwner onlyAfterAuctionEnded {
        require(auctionState != AuctionState.Completed, "La subasta ya ha sido completada.");
        require(auctionState == AuctionState.Ended, "La subasta aun no ha terminado.");

        for (uint i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            if (bidder != highestBidder) {  // Solo reembolsamos a los postores que no ganaron
                uint refundAmount = totalBids[bidder];
                totalBids[bidder] = 0;

                if (refundAmount > 0) {
                    (bool success, ) = payable(bidder).call{value: refundAmount}("");
                    require(success, "Fallo al devolver los depositos.");

                    emit DepositWithdrawn(bidder, refundAmount);
                }
            }
        }

        auctionState = AuctionState.DepositsRefunded;
    }

    /// @notice Permite al propietario retirar las comisiones acumuladas
    function withdrawCommissions() external onlyOwner onlyAfterDepositsRefunded {
        require(auctionState != AuctionState.Completed, "La subasta ya ha sido completada.");
        require(auctionState == AuctionState.DepositsRefunded, "Los depositos no han sido reembolsados.");
        uint amount = commissionFunds;
        commissionFunds = 0;

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Fallo al retirar las comisiones.");

        emit CommissionsWithdrawn(amount);
    }

    /// @notice Permite al propietario retirar la oferta ganadora
    function withdrawWinningBid() external onlyOwner onlyAfterDepositsRefunded {
        require(auctionState != AuctionState.Completed, "La subasta ya ha sido completada.");
        require(auctionState == AuctionState.DepositsRefunded, "Los depositos no han sido reembolsados.");
        uint amount = highestBid;
        auctionState = AuctionState.Completed;

        // Actualizamos el balance del ganador a cero
        totalBids[highestBidder] = 0;

        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Fallo al retirar la oferta ganadora.");

        emit WinningBidWithdrawn(amount);

        emit AuctionCompleted(success);
    }
}