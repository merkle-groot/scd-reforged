// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// import { Test } from 'forge-std/Test.sol';
// import { CDPManager } from "src/CDPManager.sol";
// import { DSMath } from "src/lib/DSMath.sol";


// contract CDPManagerTest is Test{
//     CDPManager cdp;

//     function setUp() public {
//         cdp = new CDPManager(
//             // 10 % every year
//             1000000003022265970023464960,
//             // 5 % every year
//             1000000001547125985827094528
//         );
//     }

//     function test_mul() public{
//         // 0 secs elapsed
//         uint stabilityFeeMul1 = cdp.getStabilityFeeMul();
//         uint totalFeeMul1 = cdp.getTotalFeeMul();
//         assertEq(stabilityFeeMul1, DSMath.RAY);
//         assertEq(totalFeeMul1, DSMath.RAY);

//         skip(86400);

//         // 1 day elapsed
//         uint stabilityFeeMul2 = cdp.getStabilityFeeMul();
//         uint totalFeeMul2 = cdp.getTotalFeeMul();
//         assertEq(stabilityFeeMul2, 1000261157875197197935442824);
//         assertEq(totalFeeMul2, 1000394873406473592135593799);

//         skip(86400);

//         // 2 days elapsed
//         uint stabilityFeeMul3 = cdp.getStabilityFeeMul();
//         uint totalFeeMul3 = cdp.getTotalFeeMul();
//         assertEq(stabilityFeeMul3, 1000522383953830173386098236);
//         assertEq(totalFeeMul3, 1000789902737954324329903096);
//     }

// }

