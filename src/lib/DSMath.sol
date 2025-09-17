// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// overflow checks are not needed for uint
library DSMath {
    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    uint constant WAD_HALF = WAD / 2;
    uint constant RAY_HALF = RAY / 2;

    function min(uint x, uint y) internal pure returns(uint){
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal pure returns(uint){
        return x >= y ? x : y;
    }

    function imin(int x, int y) internal pure returns(int){
        return x <= y ? x : y;
    }

    function imax(int x, int y) internal pure returns(int){
        return x >= y ? x : y;
    }

    function wmul(uint x, uint y) internal pure returns(uint){
       return (x * y + WAD_HALF) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns(uint){
        return (x * WAD + y/2) / y;
    }

    function rmul(uint x, uint y) internal pure returns(uint){
        return (x * y + RAY_HALF) / RAY;
    }   

    function rdiv(uint x, uint y) internal pure returns(uint){
        return (x * RAY + y/2) / y;
    }

    function rpow(uint x, uint n) internal pure returns(uint){
        uint result = RAY;

        while(n != 0){
            if(n % 2 == 1){
                result = rmul(result, x);
            }  

            x = rmul(x, x);
            n = n / 2;
        }

        return result;
    }


}