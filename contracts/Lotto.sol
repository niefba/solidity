// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lotto {

    address private owner;
    uint[6] results;
    uint jackpot = 0;
    struct Grid {
        uint[6] numeros;
        address player;
    }
    Grid[] playerGrids;

    constructor() {
        owner = msg.sender;
    }

    function play(uint[6] memory numeros) payable  public {
        require(msg.value == 10 wei, "Insuffisante value");
        require(numeros.length == 6, "Invalid array");
        
        jackpot += 10;
        Grid memory current;
        current.numeros = numeros;
        current.player = msg.sender;
        playerGrids.push(current);
    }

    function retrieve() public view returns (Grid[] memory) {
        return playerGrids;
    }

    function getRandomNumber(uint i) private view returns (uint8) {
        uint256 randomHash = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao, // Use block.difficulty in versions before 0.8.18
                    i
                )
            )
        );
        return uint8((randomHash % 50) + 1); // Ensures the result is between 1 and 50
    }

    function tirage() public {
        require(msg.sender == owner, "Not allowed");
        
        for (uint i = 0; i < 6; i++) {
            results[i] = getRandomNumber(i);
        }
        
    }

    function payment() public view returns (uint[6] memory) {
        require(results.length == 6, "Waiting for 6 results");
        return results;
    }

}