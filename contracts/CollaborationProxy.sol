pragma solidity 0.5.13;

import "@openzeppelin/upgrades/contracts/upgradeability/AdminUpgradeabilityProxy.sol";
import "./lib/interface/ICollaboration.sol";

contract CollaborationProxy is AdminUpgradeabilityProxy {

    /**
     * @param implementation <address> instance of LaborLedgerImpl contract
     * @param projectLead <address> address of project lead
     * @param projectLead <address> address of project lead
     * @param startWeek <uint16> project first week as Week Index (default - previous week)
     * @param managerEquity <uint32> manager equity pool in Share Units
     * @param investorEquity <uint32> investor equity pool in Share Units
     * (4 x uint8 packed into uint32) for JUNIOR (lowest byte), STANDARD, SENIOR, ADVISER
     *
     * @dev collaboration is the only mandatory param
     *   ... provide zero value(s) for any other param(s) to set the default value(s)
     */
    constructor (
        address implementation,
        address proxyAdmin,
        bytes32 uid,
        address quorum,
        address inviter,
        uint32 managerEquity,
        uint32 investorEquity,
        uint32 laborEquity,
        address laborLedgerImpl,
        address projectLead,
        address projectArbiter,
        address defaultOperator,
        uint16 startWeek
    )
        AdminUpgradeabilityProxy(
            implementation,
            proxyAdmin,
            // `data` to call the <LaborLedgerInitialize.initialize>
            abi.encodeWithSelector(
                ICollaboration(implementation).initialize.selector,
                proxyAdmin,
                uid,
                quorum,
                inviter,
                managerEquity,
                investorEquity,
                laborEquity,
                laborLedgerImpl,
                projectLead,
                projectArbiter,
                defaultOperator,
                startWeek
            )
        ) public { }
}
