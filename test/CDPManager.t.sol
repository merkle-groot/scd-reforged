// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { Test } from 'forge-std/Test.sol';
import { CDPManager } from "src/CDPManager.sol";
import { DSMath } from "src/lib/DSMath.sol";
import { Token, TokenFactory } from "src/lib/Token.sol";
import { TrustedOracle } from "src/lib/TrustedOracle.sol";
import { Liquidator } from "src/Liquidator.sol";
import { console } from "forge-std/console.sol";


contract CDPManagerTest is Test{
    struct Vault {
        address owner;
        uint lockedCollateral;
        uint normalizedDebt;
        uint normalizedTotalDebt;
    }

    CDPManager cdp;

    // 10% every year
    uint stabilityFee = 1000000003022265970023464960;
    // 5% every year
    uint governanceFee = 1000000001547125985827094528;
    // spread 0.1 %
    uint spread = 1001000000000000000;
    // 150 % of the debt
    uint minCollateralRatio = 1500000000000000000;

    Token scd;
    Token weth;
    Token toxic_peth;
    Token peth;
    Token gov;

    TrustedOracle scdOracle;
    TrustedOracle wethOracle;
    TrustedOracle govOracle;
    
    Liquidator liquidator;
    address immutable owner = address(0x42);
    address[4] users = [address(0x100), address(0x101), address(0x102), address(0x103)];
    uint inititalBalance = 100 ether;

    // 1 usd
    uint scdOraclePrice = 1 * DSMath.WAD;
    // 3500 usd
    uint wethOraclePrice = 3500 * DSMath.WAD;
    // 10 usd
    uint govOraclePrice = 10 * DSMath.WAD;

    function setUp() public {
        TokenFactory token_factory = new TokenFactory();
        scd = token_factory.deployToken("single collateral dai", "SCD", owner);
        weth = token_factory.deployToken("wrapped ether", "WETH", owner);
        toxic_peth = token_factory.deployToken("toxic peth", "TPETH", owner);
        peth = token_factory.deployToken("pooled peth", "PETH", owner);
        gov = token_factory.deployToken("governance token", "GOV", owner);

        scdOracle = new TrustedOracle(owner);
        wethOracle = new TrustedOracle(owner);
        govOracle = new TrustedOracle(owner);
        liquidator = new Liquidator();

        cdp = new CDPManager(
            // 10 % every year
            stabilityFee,
            // 5 % every year
            governanceFee,
            // 1% spread
            spread,
            scd,
            toxic_peth,
            weth,
            peth,
            gov,
            scdOracle,
            wethOracle,
            govOracle,
            liquidator,
            minCollateralRatio
        );

        vm.startPrank(owner);
        scdOracle.setPrice(scdOraclePrice);
        wethOracle.setPrice(wethOraclePrice);
        govOracle.setPrice(govOraclePrice);
        scd.grantRole(keccak256("MINTER_ROLE"), address(cdp));
        weth.grantRole(keccak256("MINTER_ROLE"), address(this));
        peth.grantRole(keccak256("MINTER_ROLE"), address(cdp));
        vm.stopPrank();

        for(uint i=0; i < users.length; ++i){
            weth.mint(users[i], inititalBalance);
        }
    }

    function test_mul() public{
        // 0 secs elapsed
        uint stabilityFeeMul1 = cdp.getStabilityFeeMul();
        uint totalFeeMul1 = cdp.getTotalFeeMul();
        assertEq(stabilityFeeMul1, DSMath.RAY);
        assertEq(totalFeeMul1, DSMath.RAY);

        skip(86400);

        // check for role
        console.log("has role", scd.hasRole(keccak256("MINTER_ROLE"), address(cdp)));

        // 1 day elapsed
        uint stabilityFeeMul2 = cdp.getStabilityFeeMul();
        uint totalFeeMul2 = cdp.getTotalFeeMul();
        assertEq(stabilityFeeMul2, 1000261157875197197935442824);
        assertEq(totalFeeMul2, 1000394873406473592135593799);

        skip(86400);

        // 2 days elapsed
        uint stabilityFeeMul3 = cdp.getStabilityFeeMul();
        uint totalFeeMul3 = cdp.getTotalFeeMul();
        assertEq(stabilityFeeMul3, 1000522383953830173386098236);
        assertEq(totalFeeMul3, 1000789902737954324329903096);

        // no debt in the system yet
        assertEq(scd.balanceOf(address(liquidator)), 0);
    }

    function test_drawing_scd() public{
        address alice = users[0];
        vm.startPrank(alice);

        // peth - 1 WAD
        // eth deposited - peth * per * 0.1%
        uint deposit_amount = 1 * DSMath.WAD;
        uint cdp_balance_before_deposit = weth.balanceOf(address(cdp));
        uint alice_balance_before_deposit = weth.balanceOf(alice);
        uint alice_peth_balance_before_deposit = peth.balanceOf(alice);
        // increase allowance
        weth.approve(address(cdp), UINT256_MAX);
        cdp.join(deposit_amount);
        uint cdp_balance_after_deposit = weth.balanceOf(address(cdp));
        uint alice_balance_after_deposit = weth.balanceOf(alice);
        uint alice_peth_balance_after_deposit = peth.balanceOf(alice);

        // inital ethPerPeth is RAY => 1
        uint weth_deposited = 999000000000000000;
        console.log("weth deposited: ", weth_deposited);
        console.log("alice_balance_before_deposit: ", alice_balance_before_deposit);
        console.log("alice_balance_after_deposit: ", alice_balance_after_deposit);
        assertEq(alice_balance_after_deposit, alice_balance_before_deposit - weth_deposited);
        assertEq(alice_peth_balance_after_deposit, alice_peth_balance_before_deposit + deposit_amount);
        assertEq(cdp_balance_after_deposit, cdp_balance_before_deposit + weth_deposited);

        // open and deposit 
        uint vaultId = cdp.openVault();
        peth.approve(address(cdp), UINT256_MAX);
        cdp.lockCollateral(vaultId, deposit_amount);

        uint alice_peth_balance_after_lock = peth.balanceOf(alice);
        uint cdp_peth_balance_after_lock = peth.balanceOf(address(cdp));
        assertEq(alice_peth_balance_after_lock, 0);
        assertEq(cdp_peth_balance_after_lock, deposit_amount);

        // check the vault
        (address vaultOwner, uint lockedCollateral, uint _normalizedDebt, uint _normalizedTotalDebt) = cdp.vaultIdToVault(vaultId);
        assertEq(lockedCollateral, deposit_amount);
        assertEq(vaultOwner, alice);

        // fast forwad a day to populate values in chi and rhi
        skip(86400);

        // draw scd
        // max drawable: 
        uint collateralValue = DSMath.rmul(
            DSMath.rdiv(weth_deposited, deposit_amount), 
            DSMath.wmul(lockedCollateral, wethOracle.readPrice())
        );
        // Draw 50% of the collateral as DAI
        // collateral ratio of 200%
        uint scdDrawn = DSMath.wmul(collateralValue, 0.5 ether);

        // draw max colalteral possible
        uint aliceSCDBalanceBefore = scd.balanceOf(alice);
        cdp.drawScd(vaultId, scdDrawn);
        uint aliceSCDBalanceAfter = scd.balanceOf(alice);
        assertEq(aliceSCDBalanceAfter, aliceSCDBalanceBefore + scdDrawn);

        (, , uint normalizedDebtAfter, uint normalizedTotalDebt) = cdp.vaultIdToVault(vaultId);
        assertEq(lockedCollateral, deposit_amount);
        assertEq(vaultOwner, alice);
        assertEq(normalizedDebtAfter, DSMath.rdiv(scdDrawn, cdp.stabilityFeeMul()));
        assertEq(normalizedTotalDebt, DSMath.rdiv(scdDrawn, cdp.totalFeeMul()));
        assertEq(cdp.totalDebt(),  DSMath.rdiv(scdDrawn, cdp.stabilityFeeMul()));
    }

}

