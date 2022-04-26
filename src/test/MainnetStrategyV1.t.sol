// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";

import "../MainnetStrategyV1.sol";

import {OracleMock} from "./utils/mocks/OracleMock.sol";

contract MainnetStrategyV1Test is Test {
    // SuT
    MainnetStrategyV1 strategy;

    // Mocks
    OracleMock marketOracle;
    OracleMock cpiOracle;

    function setUp() public {
        marketOracle = new OracleMock();
        marketOracle.setValid(true);

        cpiOracle = new OracleMock();
        cpiOracle.setValid(true);

        strategy = new MainnetStrategyV1(
            address(marketOracle),
            address(cpiOracle)
        );
    }

    //--------------------------------------------------------------------------
    // Constructor Tests

    function testConstructor() public {
        assertEq(strategy.ampleMarketOracle(), address(marketOracle));
        assertEq(strategy.ampleCPIOracle(), address(cpiOracle));
    }

    function testFailConstructorIfMarketOracleInvalid() public {
        marketOracle.setValid(false);

        strategy = new MainnetStrategyV1(
            address(marketOracle),
            address(cpiOracle)
        );
    }

    function testFailConstructorIfCPIOracleInvalid() public {
        cpiOracle.setValid(false);

        strategy = new MainnetStrategyV1(
            address(marketOracle),
            address(cpiOracle)
        );
    }

    //--------------------------------------------------------------------------
    // getSignal Tests

    struct TestCase {
        uint cpi;
        uint exchangeRate;
        bool wantSignal;
    }

    function testSignal() public {
        TestCase[7] memory testTable = [
            // Tx: 0x1759626962c5efaacf0dd4f24143440393b86881d59a0072c35a14db59fa5921
            // Rebase: Contraction
            // Signal: Hedge
            TestCase(uint(118734666666666669244), 942915573185907350, true),
            // Tx: 0x7af755b164789f59c1874b908dcd3a1852159d99c2246ea90f46d08e0922d608
            // Rebase: Expansion
            // Signal: Dehedge
            TestCase(uint(118117000000000004432), 1199454408321776189, false),
            // Tx: 0x205bc2debb042f6b00fc817c802ff246a399121f59bd34b7b8f1875a54cc9c67
            // Rebase: Equilibrium (due to Threshold)
            // Signal: Dehedge
            TestCase(uint(117459666666666650000), 1111967949182716353, false),
            // Tx: 0xc4944e44a1975f3b445262bbd5ffba2f320241108d195367dbc28b7e8b81c9c8
            // Rebase: Expansion
            // Signal: Dehedge
            TestCase(uint(117459666666666650000), 1172597381040277220, false),
            // Tx: 0x438bd97c3c9a55bd5f814784a9b754e893900e9d4e76a3d12bf5408e0b0a0c27
            // Rebase: Contraction
            // Signal: Hedge
            TestCase(uint(117459666666666650000), 1003734926646385972, true),
            // Tx: 0xf3ef887ab507b8f82f76b21e8496ede7a5a1192f53c0fba5b3314f8ed76690b4
            // Rebase: Contraction
            // Signal: Hedge
            TestCase(uint(116788000000000010000), 928373079480195095, true),
            // Tx: 0x67d6666cc6eb6083ec070f35b10ce166dfb910a836a76f88e90f95595a3b5e70
            // Rebase: Expansion
            // Signal: Dehedge
            TestCase(uint(116788000000000010000), 1202550305255891950, false)
        ];

        // Execute each test case.
        for (uint i; i < testTable.length; i++) {
            // Set cpi and exchange rate.
            cpiOracle.setData(testTable[i].cpi);
            marketOracle.setData(testTable[i].exchangeRate);

            // Note we do not need to call the setUp function on each iteration
            // as the strategy is stateless.

            bool signal;
            bool valid;
            (signal, valid) = strategy.getSignal();

            assertTrue(signal == testTable[i].wantSignal);
            assertTrue(valid);
        }
    }

    function testSignalInvalidIfMarketOracleInvalid() public {
        marketOracle.setValid(false);

        bool signal;
        bool valid;
        (signal, valid) = strategy.getSignal();

        assertTrue(!signal);
        assertTrue(!valid);
    }

    function testSignalInvalidIfCPIOracleInvalid() public {
        cpiOracle.setValid(false);

        bool signal;
        bool valid;
        (signal, valid) = strategy.getSignal();

        assertTrue(!signal);
        assertTrue(!valid);
    }

}
