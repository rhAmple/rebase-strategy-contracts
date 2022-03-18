// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {
    IRebaseStrategy
} from "rhAmple-contracts/interfaces/IRebaseStrategy.sol";

interface IOracle {
    function getData() external returns (uint, bool);
}

contract MainnetStrategyV1 is IRebaseStrategy {

    // @todo Copied from Ampleforth Dashboard.
    /// @dev The CPI value at Ample's launch.
    /// @dev Is in 18 decimals precision for cents, i.e. 100e18 = 1$.
    uint private constant BASE_CPI = 109200000000000000000;
    //                                  ^ 18th decimal
    //                            => 109 cent = 1.09 USD

    /// @dev Ample's decimals.
    uint private constant DECIMALS = 9;

    // @todo Docs about 18 decimal?
    //  Push from Ampleforth: 118734666666666669240
    //  Is in 18 decimals, but in cents!
    /// @notice The Ample market price oracle address.
    /// @dev Changeable by owner.
    /// @dev The price is in 18 decimal precision.
    address public ampleMarketOracle;

    // @todo Docs about 18 decimal, price target?
    /// @notice The Ample CPI oracle address.
    /// @dev Changeable by owner.
    /// @dev The price target is in 18 decimal precision.
    address public ampleCPIOracle;

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
