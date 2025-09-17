// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { DSMath } from "src/lib/DSMath.sol";
import {console} from "forge-std/console.sol";

contract CDPManager {
    // compound interest calculated every sec on debt
    uint stabilityFee;
    // compound interest calculated every sec on debt + stability fee
    uint governanceFee;

    // last updated timestamp
    uint lastUpdatedAt;
    // multiplier for stability fee
    uint stabilityFeeMul;
    // multiplier for stability + governance fee
    uint totalFeeMul;

    constructor(
        uint _stabilityFee,
        uint _governanceFee
    ) {
        stabilityFee = _stabilityFee;
        governanceFee = _governanceFee;

        stabilityFeeMul = DSMath.RAY;
        totalFeeMul = DSMath.RAY;
        lastUpdatedAt = block.timestamp;
    }

    function getStabilityFeeMul() public returns(uint){
        updateMultipliers();
        return stabilityFeeMul;
    }

    function getTotalFeeMul() public returns(uint){
        updateMultipliers();
        return totalFeeMul;
    }

    function updateMultipliers() internal {
        uint currentTimestamp = block.timestamp;
        uint age = currentTimestamp - lastUpdatedAt;

        // 0 sec elapsed
        if (age == 0) return;

        lastUpdatedAt = currentTimestamp;

        // calculate stability mul
        uint pendingMultiplier = DSMath.RAY;

        if (stabilityFee != DSMath.RAY) {
            pendingMultiplier = DSMath.rpow(stabilityFee, age);
            stabilityFeeMul = DSMath.rmul(stabilityFeeMul, pendingMultiplier);
            console.log("stability", pendingMultiplier);
            // Todo(merkle-groot): mint fees to the tap contract 
        }

        // calculate total fee mul 
        // governance fee is an optional fee, if it's not enables skip
        if (governanceFee != DSMath.RAY) {
            pendingMultiplier = DSMath.rmul(pendingMultiplier, DSMath.rpow(governanceFee, age));
            console.log("stability*gov", pendingMultiplier);
            
        }

        if (pendingMultiplier != DSMath.RAY) {
            totalFeeMul = DSMath.rmul(totalFeeMul, pendingMultiplier);
            console.log("totalFeeMul", totalFeeMul);
        }
    }

    
}