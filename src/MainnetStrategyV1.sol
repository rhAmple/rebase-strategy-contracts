// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {
    IRebaseStrategy
} from "rhAmple-contracts/interfaces/IRebaseStrategy.sol";

// Copied from https://github.com/ampleforth/ampleforth-contracts/blob/master/contracts/MedianOracle.sol.
interface IOracle {
    function getData() external returns (uint, bool);
}

contract MainnetStrategyV1 is IRebaseStrategy {

    //--------------------------------------------------------------------------
    // Constants

    /// @dev The CPI value at Ample's launch.
    /// @dev Copied from https://web-api.ampleforth.org/eth/token-info.
    ///      Trailing zero's added for 18 decimal precision.
    uint private constant BASE_CPI = 109195000000000010000;

    /// @dev Copied from UFragmentsPolicy.
    uint private constant DECIMALS = 18;

    //--------------------------------------------------------------------------
    // Storage

    /// @notice The Ample market price oracle address.
    /// @dev The value is in 18 decimal precision and cent denominated.
    address public immutable ampleMarketOracle;

    /// @notice The Ample CPI oracle address.
    /// @dev The price target is in 18 decimal precision cent denominated.
    address public immutable ampleCPIOracle;

    //--------------------------------------------------------------------------
    // Constructor

    constructor(address ampleMarketOracle_, address ampleCPIOracle_) {
        // Make sure that both oracles are working.
        bool isValid;
        ( , isValid) = IOracle(ampleMarketOracle_).getData();
        require(isValid);
        ( , isValid) = IOracle(ampleCPIOracle_).getData();
        require(isValid);

        // Set storage variables.
        ampleMarketOracle = ampleMarketOracle_;
        ampleCPIOracle = ampleCPIOracle_;
    }

    //--------------------------------------------------------------------------
    // IRebaseStrategy Functions

    /// @inheritdoc IRebaseStrategy
    function getSignal() external returns (bool, bool) {
        // Fetch Ample's current CPI value.
        uint cpi;
        bool cpiValid;
        (cpi, cpiValid) = IOracle(ampleCPIOracle).getData();

        // Check for oracle failure.
        if (!cpiValid) {
            return (false, false);
        }

        // Compute Ample's current target rate.
        uint targetRate = cpi * (10**DECIMALS) / BASE_CPI;

        // Fetch Ample's current exchange rate.
        uint exchangeRate;
        bool rateValid;
        (exchangeRate, rateValid) = IOracle(ampleMarketOracle).getData();

        // Check for oracle failure.
        if (!rateValid) {
            return (false, false);
        }

        // Give signal to hedge if Ample's target rate less than the current
        // exchange rate.
        return (exchangeRate < targetRate, true);
    }

}
