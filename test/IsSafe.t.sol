// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import { Test } from 'forge-std/Test.sol';
// import { CDPManager } from "src/CDPManager.sol";
// import { DSMath } from "src/lib/DSMath.sol";

// contract IsSafeTest is Test {
//     CDPManager cdp;
//     address mockWethOracle;
//     address mockScdOracle;

//     function setUp() public {
//         cdp = new CDPManager(
//             1000000003022265970023464960, // 10% yearly stability fee
//             1000000001547125985827094528  // 5% yearly total fee
//         );

//         mockWethOracle = address(0x123);
//         mockScdOracle = address(0x456);
//     }

//     function test_IsSafe_WhenVaultIsSafe() public {
//         // Mock oracle prices
//         vm.mockCall(
//             mockWethOracle,
//             abi.encodeWithSignature("readPrice()"),
//             abi.encode(2000 * 1e18) // $2000 per ETH
//         );

//         vm.mockCall(
//             mockScdOracle,
//             abi.encodeWithSignature("readPrice()"),
//             abi.encode(1 * 1e18) // $1 per SCD
//         );

//         // Setup vault with sufficient collateral
//         // (You'd need to set up vault state or create helper functions)

//         // bool safe = cdp.isSafe(vaultId);
//         // assertTrue(safe, "Vault should be safe");
//     }

//     function test_IsSafe_WhenVaultIsUnsafe() public {
//         // Mock oracle prices
//         vm.mockCall(
//             mockWethOracle,
//             abi.encodeWithSignature("readPrice()"),
//             abi.encode(1000 * 1e18) // Lower ETH price
//         );

//         vm.mockCall(
//             mockScdOracle,
//             abi.encodeWithSignature("readPrice()"),
//             abi.encode(1 * 1e18)
//         );

//         // bool safe = cdp.isSafe(vaultId);
//         // assertFalse(safe, "Vault should be unsafe");
//     }
// }