// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { Test } from 'forge-std/Test.sol';
import { DSMath } from '../../src/lib/DSMath.sol';

contract DSMathTest is Test {
    function test_min() pure public {
        assertEq(DSMath.min(1, 1), 1);
        assertEq(DSMath.min(1, 2), 1);
    }

    function test_max() pure public {
        assertEq(DSMath.max(1, 1), 1);
        assertEq(DSMath.max(1, 2), 2);
    }

    function test_imin() pure public {
        assertEq(DSMath.imin(1, 1), 1);
        assertEq(DSMath.imin(1, 2), 1);
        assertEq(DSMath.imin(1, -2), -2);
    }

    function test_imax() pure public {
        assertEq(DSMath.imax(1, 1), 1);
        assertEq(DSMath.imax(1, 2), 2);
        assertEq(DSMath.imax(1, -2), 1);
    }

    function test_wmul_trivial() pure public {
        assertEq(DSMath.wmul(2 ** 128 - 1, 1.0 ether), 2 ** 128 - 1);
        assertEq(DSMath.wmul(0.0 ether, 0.0 ether), 0.0 ether);
        assertEq(DSMath.wmul(0.0 ether, 1.0 ether), 0.0 ether);
        assertEq(DSMath.wmul(1.0 ether, 0.0 ether), 0.0 ether);
        assertEq(DSMath.wmul(1.0 ether, 1.0 ether), 1.0 ether);
    }

    function test_wmul_fractions() pure public {
        assertEq(DSMath.wmul(1.0 ether, 0.2 ether), 0.2 ether);
        assertEq(DSMath.wmul(2.0 ether, 0.2 ether), 0.4 ether);
    }

    function test_wdiv_trivial() pure public {
        assertEq(DSMath.wdiv(0.0 ether, 1.0 ether), 0.0 ether);
        assertEq(DSMath.wdiv(1.0 ether, 1.0 ether), 1.0 ether);
    }

    function test_wdiv_fractions() pure public {
        assertEq(DSMath.wdiv(1.0 ether, 2.0 ether), 0.5 ether);
        assertEq(DSMath.wdiv(2.0 ether, 2.0 ether), 1.0 ether);
    }

    function test_wmul_rounding() pure public {
        uint a = .950000000000005647 ether;
        uint b = .000000001 ether;
        uint c = .00000000095 ether;
        assertEq(DSMath.wmul(a, b), c);
        assertEq(DSMath.wmul(b, a), c);
    }

    function test_rmul_rounding() pure public {
        uint a = 1 ether;
        uint b = .95 ether * 10**9 + 5647;
        uint c = .95 ether;
        assertEq(DSMath.rmul(a, b), c);
        assertEq(DSMath.rmul(b, a), c);
    }

}   