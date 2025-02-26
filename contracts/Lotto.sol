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

    
    event Transfer (address indexed _from, address indexed _to, uint amount);
    event Log(address indexed sender, string message);

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
        require(msg.value == 1 gwei, "Insuffisante value");
        require(checkGrid(numeros), "Invalid grid");
        
        jackpot += 1 gwei;

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

    function payment() public {
        require(msg.sender == owner, "Not allowed");
        require(results.length == 6, "Waiting for Tirage");
        

        for (uint i=0; i<playerGrids.length; i++) {
            uint countMatching = 0;
            for (uint j=0; j<playerGrids[i].numeros.length; j++) {
                for (uint k=0; k < results.length; k++) {
                    if (results[k] == playerGrids[i].numeros[j]) {
                        countMatching++;
                    }
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

        // Jackpot for rank one
        if (rankOne.length >= 1) {
            sendPaymentByRank(rankOne, (jackpot * 60 / 100) / rankOne.length);
        }

        // Jackpot for rank two
        if (rankTwo.length >= 1) {
            sendPaymentByRank(rankTwo, (jackpot * 20 / 100) / rankTwo.length);
        }

        // Jackpot for rank three
        if (rankThree.length >= 1) {
            sendPaymentByRank(rankThree, (jackpot * 10 / 100) / rankThree.length);
        }

        // Reset all
        reset();

    }

    function sendPaymentByRank(address[] memory rank, uint amount) private {
        for (uint i=0; i < rank.length; i++) {
            emit Transfer(msg.sender, rank[i], amount);
            (bool success, ) = rankOne[i].call{value:amount}("");
            require(success, "Transfer failed.");
        }
    }

    function reset() private {
        delete results;
        delete rankOne;
        delete rankTwo;
        delete rankThree;
        delete playerGrids;
        jackpot = 0;
    }
}