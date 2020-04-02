pragma solidity 0.5.13;

import "@openzeppelin/upgrades/contracts/upgradeability/AdminUpgradeabilityProxy.sol";
import "./lib/interface/ILaborLedger.sol";

contract LaborLedgerProxy is AdminUpgradeabilityProxy {

    /**
     * @dev Proxy for the LaborLedgerImpl.
     *
     * `implementation` and `collaboration` are mandatory params.
     * Zero value(s) set(s) the default value(s) to any other param(s).
     *
     * @param implementation Address of the of LaborLedgerImpl contract
     * @param collaboration Address of the Collaboration (Proxy) contract
     * @param projectLead Address of the project Lead (msg.sender by default)
     * @param projectArbiter Address of the project Arbiter (msg.sender by default)
     * @param startWeek Week Index of the project first week (default - current week)
     * @param weights Array packed into Uint32 with "weight" factors
     *   (to convert Time Units into Labor Units)
     *   by default, for JUNIOR, STANDARD , SENIOR, ADVISER: [1,2,3,4]
     */
    constructor (
        address implementation,
        address collaboration,
        address projectLead,
        address projectArbiter,
        address defaultOperator,
        uint16 startWeek,
        uint32 weights
    )
        AdminUpgradeabilityProxy(
            implementation,
            msg.sender,
            // `data` to call the <LaborLedgerInitialize.initialize>
            abi.encodeWithSelector(
                ILaborLedger(implementation).initialize.selector,
                collaboration,
                projectLead,
                projectArbiter,
                defaultOperator,
                startWeek,
                weights
            )
        ) public { }
}
