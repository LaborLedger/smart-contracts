pragma solidity 0.5.13;

interface ICollaborationProxy {

    /**
    * @dev "constructor" to be delegatecall`ed on deployment of Proxy
    *
    * (provide zero value(s) for any (all) other param(s) to set the default value(s))
    * @param projectLead (optional) Address of project lead
    * @param startWeek Week Index iof the Project first week (default - previous week)
    * @param managerEquity <uint32> manager equity pool in Share Units
    * @param investorEquity <uint32> investor equity pool in Share Units
    * @param laborEquity <uint32> investor equity pool in Share Units
    * @param weights <uint32> (packed uint8[4]) factors to convert Time Units in Labor Units
    */
    function initialize(
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
        uint16 startWeek,
        uint32 weights
    ) external;
}
