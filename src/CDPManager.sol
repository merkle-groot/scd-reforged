// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { DSMath } from "./lib/DSMath.sol";

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

    function getStabilityFeeMul() public returns(uint){
        update_multipliers();
        return stabilityFeeMul;
    }

    function getTotalFeeMul() public returns(uint){
        update_multipliers();
        return totalFeeMul;
    }

    function update_multipliers() internal {
        uint current_timestamp = block.timestamp;
        uint age = lastUpdatedAt - current_timestamp;

        // 0 sec elapsed
        if (age == 0) return;

        // calculate stability mul
        uint pending_multiplier = DSMath.RAY;

        if (stabilityFee != DSMath.RAY) {
            pending_multiplier = DSMath.rpow(stabilityFee, age);
            stabilityFeeMul = DSMath.rmul(stabilityFeeMul, pending_multiplier);

            // Todo(merkle-groot): mint fees to the tap contract 
        }

        // calculate total fee mul 
        // governance fee is an optional fee, if it's not enables skip
        if (governanceFee != DSMath.RAY) {
            pending_multiplier = DSMath.rmul(pending_multiplier, DSMath.rpow(governanceFee, age));
        }

        if (pending_multiplier != DSMath.RAY) {
            totalFeeMul = DSMath.rmul(totalFeeMul, pending_multiplier);
        }
    }
}