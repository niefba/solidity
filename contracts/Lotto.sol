// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Lotto {

    address private owner;
    uint[] results;
    address[] rankOne;
    address[] rankTwo;
    address[] rankThree;
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
        require(msg.value == 1000 gwei, "Insuffisante value");
        require(checkGrid(numeros), "Invalid grid");
        
        jackpot += 1000 gwei;
        Grid memory current;
        current.numeros = numeros;
        current.player = msg.sender;
        playerGrids.push(current);
    }

    function retrieve() public view returns (Grid[] memory) {
        return playerGrids;
    }

    function viewJackpot() public view returns (uint) {
        return jackpot;
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

    function fakeTirage() public {
        require(msg.sender == owner, "Not allowed");
        results = [1,2,3,4,5,6];
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

    function payment() public returns (uint[] memory) {
        require(results.length == 6, "Waiting for Tirage");
        

        for (uint i=0; i<playerGrids.length; i++) {
            for (uint j=0; j<playerGrids[i].numeros.length; j++) {
                uint countMatching = 0;
                for (uint k=0; k < results.length; k++) {
                    if (results[k] == playerGrids[i].numeros[j]) {
                        countMatching++;
                    }
                }
                if(countMatching == 6) {
                    rankOne.push(playerGrids[i].player);
                }
                else if(countMatching == 5) {
                    rankTwo.push(playerGrids[i].player);
                }
                else if(countMatching == 4) {
                    rankThree.push(playerGrids[i].player);
                }

            }

        }

        // Jackpot for rank one
        uint jackpotRankOne = (jackpot * 60 / 100) / rankOne.length;

        //uint jackpotRankOne = jackpot / 2;

        // Send payment to players of rank one
        for (uint i=0; i < rankOne.length; i++) {
            (bool success, ) = rankOne[i].call{value:jackpotRankOne}("");
            require(success, "Transfer failed.");
        }

        return results;
    }

}