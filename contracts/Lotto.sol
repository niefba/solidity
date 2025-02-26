// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lotto {

    address private owner;
    uint[] results;
    uint jackpot = 0;
    struct Grid {
        uint[] numeros;
        address player;
    }
    Grid[] playerGrids;

    constructor() {
        owner = msg.sender;
    }

    function checkGrid(uint[] memory numbers) pure  private returns (bool) {
        // Grid should have 6 numbers
        if (numbers.length != 6) {
            return false;
        }
        for (uint i=0; i<numbers.length; i++) {
            // Numbers should be between 1 and 50
            if (numbers[i] < 1 || numbers[i] > 50) {
                return false;
            }
            // Numbers should be unique
            for (uint j=i+1; j<numbers.length; j++) {
                if (numbers[i] == numbers[j]) {
                    return false;
                }
            }

        }
        return true;
    }

    function play(uint[] memory numeros) payable  public {
        require(msg.value == 10 wei, "Insuffisante value");
        require(checkGrid(numeros), "Invalid grid");
        
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
        uint seed = 0;

        // Pull 6 unique random numbers between 1 and 50
        while (results.length < 6) {
            seed++;
            uint number = getRandomNumber(seed);
            bool isUnique = true;
            for (uint i=0; i<results.length; i++) {
                if (results[i] == number) {
                    isUnique = false;
                    break;
                }
            }
            if (isUnique) {
                results.push(number);
            }
        }
        
    }

    function payment() public view returns (uint[] memory) {
        require(results.length == 6, "Waiting for 6 results");
        return results;
    }

}