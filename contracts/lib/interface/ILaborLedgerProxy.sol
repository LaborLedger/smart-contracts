pragma solidity 0.5.13;

interface ILaborLedgerProxy {

    /**
     * @dev "constructor" to be delegatecall`ed on deployment of Proxy
     *
     * @param collaboration Address of the Collaboration contract, the only mandatory param
     * (provide zero value(s) for any (all) other param(s) to set the default value(s))
     * @param projectLead (optional) Address of project lead
     * @param startWeek Week Index iof the Project first week (default - previous week)
     */
    function initialize(
        address collaboration,
        address projectLead,
        address projectArbiter,
        address defaultOperator,
        uint16 startWeek
    ) external;
}
