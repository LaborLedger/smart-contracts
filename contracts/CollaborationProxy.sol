pragma solidity 0.5.13;

import "@openzeppelin/upgrades/contracts/upgradeability/AdminUpgradeabilityProxy.sol";
import "./lib/interface/ILaborLedgerProxy.sol";

contract LaborLedgerCaller is AdminUpgradeabilityProxy {

    /**
     * @param implementation <address> instance of LaborLedgerImpl contract
     * @param collaboration <address> instance of Collaboration contract
     * @param projectLead <address> address of project lead
     * @param projectLead <address> address of project lead
     * @param startWeek <uint16> project first week as Week Index (default - previous week)
     * @param managerEquity <uint32> manager equity pool in Share Units
     * @param investorEquity <uint32> investor equity pool in Share Units
     * @param weights <uint8[4]> factors to convert Time Units into Labor Units
     *   for _ (ignored), STANDARD, SENIOR, ADVISER
     *
     * @dev collaboration is the only mandatory param
     *   ... provide zero value(s) for any other param(s) to set the default value(s)
     */
    constructor (
        address implementation,
        address collaboration,
        address projectLead,
        address projectArbiter,
        address defaultOperator,
        uint16 startWeek,
        uint32 managerEquity,
        uint32 investorEquity,
        uint8[4] memory weights
    )
        AdminUpgradeabilityProxy(
            implementation,
            msg.sender,
            // `data` to call the <LaborLedgerInitialize.initialize>
            abi.encodeWithSelector(
                ILaborLedgerCaller(implementation).initialize.selector,
                collaboration,
                projectLead,
                projectArbiter,
                defaultOperator,
                startWeek,
                uint32( // uint8[4] packed into uint32
                    uint32(uint32(weights[3])<<24) +
                    uint32(uint32(weights[2])<<16) +
                    uint32(uint32(weights[1])<<8) +
                    uint32(weights[0])
                )
            )
        ) public { }
}
