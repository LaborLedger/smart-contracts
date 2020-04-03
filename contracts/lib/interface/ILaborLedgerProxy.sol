pragma solidity 0.5.13;

interface ILaborLedgerProxy {

    /**
     * @dev "constructor" to be delegatecall`ed on deployment of Proxy
     *
     * @param collaboration Address of the Collaboration contract, the only mandatory param
     * (provide zero value(s) for any (all) other param(s) to set the default value(s))
     * @param projectLead (optional) Address of project lead
     * @param startWeek Week Index iof the Project first week (default - previous week)
     * @param weights Factors to convert Time Units in Labor Units (4 uint8 packed into uint8[4])
     */
    function initialize(
        address collaboration,
        address projectLead,
        address projectArbiter,
        address defaultOperator,
        uint16 startWeek,
        uint32 weights
    ) external;
}
