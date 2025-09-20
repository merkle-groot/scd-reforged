// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import { DSMath } from "src/lib/DSMath.sol";
import { console } from "forge-std/console.sol";
import { Token } from "src/lib/Token.sol";
import { Liquidator } from "src/Liquidator.sol";
import { TrustedOracle } from "src/lib/TrustedOracle.sol";

contract CDPManager {
    // tokens
    // single collateral dai aka SAI token
    Token scd;
    // token that tracks bad debt in the system
    Token toxic_peth;
    // collateral token
    Token weth;
    // locked collateral token; claim on collateral
    Token peth;
    // governance token
    Token gov;

    // oracles
    TrustedOracle wethOracle;
    TrustedOracle govOracle;
    TrustedOracle scdOracle;

    // vault
    // serial id of vault
    struct Vault {
        address owner;
        // amount of peth locked
        uint lockedCollateral;
        // tracker of scd drawn/stabilityFeeMul
        uint normalizedDebt;
        // tracker of scd drawn/totalFeeMul
        uint normalizedTotalDebt;
    }
    uint currentVaultId = 0;
    mapping(uint => Vault) public vaultIdToVault;
    uint minCollateralRatio;

    // Spread between join and exit
    uint spread;

    // contracts
    // liquidator
    Liquidator liquidator;

    // compound interest calculated every sec on debt
    uint stabilityFee;
    // compound interest calculated every sec on debt + stability fee
    uint governanceFee;

    // last updated timestamp
    uint lastUpdatedAt;
    // multiplier for stability fee
    uint public stabilityFeeMul;
    // multiplier for stability + governance fee
    uint public totalFeeMul;
    // system debt  
    uint public totalDebt;

    // system state
    bool off = false;
    bool out = false;

    // events
    event NewVault(address indexed owner, uint indexed vaultId);
    event CollateralAdded(uint indexed vaultId, uint pethAmount);

    constructor(
        uint _stabilityFee,
        uint _governanceFee,
        uint _spread,
        Token _scd,
        Token _toxic_peth,
        Token _weth,
        Token _peth,
        Token _gov,
        TrustedOracle _scdOracle,
        TrustedOracle _wethOracle,
        TrustedOracle _govOracle,
        Liquidator _liquidator,
        uint _minCollateralRatio
    ) {
        stabilityFee = _stabilityFee;
        governanceFee = _governanceFee;

        stabilityFeeMul = DSMath.RAY;
        totalFeeMul = DSMath.RAY;
        lastUpdatedAt = block.timestamp;

        spread = _spread;

        scd = _scd;
        toxic_peth = _toxic_peth;
        weth = _weth;
        peth = _peth;
        gov = _gov;

        scdOracle = _scdOracle;
        wethOracle = _wethOracle;
        govOracle = _govOracle;

        liquidator = _liquidator;
        minCollateralRatio = _minCollateralRatio;
    }

    function getStabilityFeeMul() public returns(uint){
        updateMultipliers();
        return stabilityFeeMul;
    }

    function getTotalFeeMul() public returns(uint){
        updateMultipliers();
        return totalFeeMul;
    }

    function updateMultipliers() internal{
        uint currentTimestamp = block.timestamp;
        uint age = currentTimestamp - lastUpdatedAt;

        // 0 sec elapsed
        if (age == 0) return;

        lastUpdatedAt = currentTimestamp;

        // calculate stability mul
        uint pendingMultiplier = DSMath.RAY;

        if (stabilityFee != DSMath.RAY) {
            uint previousStabilityFeeMul = stabilityFeeMul;
            pendingMultiplier = DSMath.rpow(stabilityFee, age);
            stabilityFeeMul = DSMath.rmul(stabilityFeeMul, pendingMultiplier);
            console.log("stability", pendingMultiplier);
            
            // Todo(merkle-groot): test
            // Debt at t1 = totalDebt * previousStabilityFeeMul
            // Debt at t2 = totalDebt * stabilityFeeMul
            // New debt = totalDebt * stabilityFeeMul -  totalDebt * previousStabilityFeeMul
            scd.mint(address(liquidator), DSMath.wmul(totalDebt, stabilityFeeMul - previousStabilityFeeMul));
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

    function ethLocked() internal view returns(uint){
        return weth.balanceOf(address(this));
    }

    function pethMinted() internal view returns(uint){
        return peth.totalSupply();
    }

    function ethPerPeth() public view returns(uint){
        return pethMinted() == 0 ? DSMath.RAY : DSMath.rdiv(ethLocked(), pethMinted());
    }

    function bid(uint pethAmount) internal view returns(uint){
        return DSMath.rmul(DSMath.wmul(ethPerPeth(), pethAmount), spread);
    }

    function ask(uint pethAmount) internal view returns(uint){
        return DSMath.rmul(DSMath.wmul(ethPerPeth(), pethAmount), 2 * DSMath.WAD - spread);
    }

    function join(uint pethAmount) external{
        require(!off, "scd: The system is shutdown");
        uint askAmount = ask(pethAmount);
        require(askAmount > 0, "sdc: ask amount is 0");
        require(weth.transferFrom(msg.sender, address(this), askAmount), "scd: Not enough balance/approval");
        peth.mint(msg.sender, pethAmount);
    }

    function exit(uint pethAmount) external{
        require(!off || out, "scd: The system is shutdown");
        uint bidAmount = bid(pethAmount);
        peth.burn(msg.sender, pethAmount);
        require(weth.transfer(msg.sender, bidAmount));
    }

    // vault
    function getDebt(uint vaultId) public returns(uint){
        return DSMath.rmul(vaultIdToVault[vaultId].normalizedDebt, getStabilityFeeMul());
    }

    function getGovDebt(uint vaultId) public returns(uint){
        return  DSMath.rmul(vaultIdToVault[vaultId].normalizedTotalDebt, totalFeeMul) - getDebt(vaultId);
    }

    function isSafe(uint vaultId) public returns(bool) {
        uint collateralValue =  DSMath.rmul(ethPerPeth(),  DSMath.wmul(vaultIdToVault[vaultId].lockedCollateral, wethOracle.readPrice()));
        uint debtValue =  DSMath.wmul(getDebt(vaultId),  DSMath.wmul(scdOracle.readPrice(), minCollateralRatio));
        console.log("===> collateralValue: ", collateralValue);
        console.log("===> debtValue: ", debtValue);
        return debtValue <= collateralValue;
    }

    function openVault() external returns (uint) {
        require(!off, "scd: The system is shutdown");
        vaultIdToVault[currentVaultId].owner = msg.sender;

        emit NewVault(msg.sender, currentVaultId);
        currentVaultId++;
        return currentVaultId - 1;
    }

    function lockCollateral(uint vaultId, uint pethAmount) external {
        require(!off, "scd: The system is shutdown");
        require(peth.transferFrom(msg.sender, address(this), pethAmount), "scd: Not enough balance/approval");
        require(vaultId < currentVaultId, "scd: Invalid vault id");
        vaultIdToVault[vaultId].lockedCollateral += pethAmount;

        emit CollateralAdded(vaultId, pethAmount);
    }

    function drawScd(uint vaultId, uint scdAmount) external {
        require(!off, "scd: The system is shutdown");

        Vault storage vault = vaultIdToVault[vaultId];
        require(vault.owner == msg.sender, "scd: auth failed");
        require(vaultId < currentVaultId && vault.owner == msg.sender, "scd: Invalid vault id");

        console.log("dai taken: ", scdAmount);
        vault.normalizedDebt += DSMath.rdiv(scdAmount, getStabilityFeeMul());
        vault.normalizedTotalDebt += DSMath.rdiv(scdAmount, totalFeeMul);

        console.log("normalizedDebt increment: ", DSMath.rdiv(scdAmount, getTotalFeeMul()));
        console.log("normalizedTotalDebt increment: ", DSMath.rdiv(scdAmount, totalFeeMul));
        totalDebt += DSMath.rdiv(scdAmount, getStabilityFeeMul());
        // Check for the safety of the vault
        require(isSafe(vaultId), "scd: insufficient collateral in the vault");
        scd.mint(msg.sender, scdAmount);
    }

    function wipeDebt(uint vaultId, uint scdAmount) external {
        require(!off, "scd: The system is shutdown");

        Vault storage vault = vaultIdToVault[vaultId];
        scd.burn(vault.owner, scdAmount);

        // reduce proportional amount of gov debt
        uint debtOwed = getDebt(vaultId);
        uint debtReduction = DSMath.rdiv(scdAmount, stabilityFeeMul);
        uint govDebtInDai = DSMath.rmul(scdAmount, DSMath.rdiv(getGovDebt(vaultId), debtOwed));

        vault.normalizedDebt -= debtReduction;
        vault.normalizedTotalDebt -= DSMath.rdiv(scdAmount + govDebtInDai, totalFeeMul);

        totalDebt -= debtReduction;

        if(governanceFee != DSMath.RAY){
            uint govDebt = DSMath.wdiv(govDebtInDai, govOracle.readPrice());
            require(gov.transferFrom(msg.sender, address(this), govDebt), "scd: Not enough balance/approval");
        }
    }

    function unlockCollateral(uint vaultId, uint pethAmount) external {
        require(!off, "scd: The system is shutdown");

        Vault storage vault = vaultIdToVault[vaultId];
        require(vault.owner == msg.sender, "scd: auth failed");

        vault.lockedCollateral -= pethAmount;
        require(peth.transfer(msg.sender, pethAmount), "scd: Not enough peth in the contract");
        require(isSafe(vaultId), "scd: insufficient collateral in the vault");

        // Todo: prevent leaving dust eth in the vault
    }

}