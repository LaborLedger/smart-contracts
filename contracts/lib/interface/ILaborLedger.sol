pragma solidity 0.5.13;

interface ILaborLedger {

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

    /**
     * @return Accepted Labor Units and pending (not yet accepted) Labor Units of a member
     */
    function getMemberLabor(address member) external view returns(uint32 accepted, uint32 pending);

    /**
     * @return The share of a member accepted Labor Units in total accepted Labor Units,
     * and the share of pending Labor Units in total accepted and pending Labor Units.
     * Shares expressed in Share Units.
     */
    function getMemberLaborShare(address member) external view returns(uint32 accepted, uint32 pending);

    /**
     * @dev Book (register) settlement of Labor Units of a member
     * (in decreases net Labor Units and remaining share in total net Labor Units of the member)
     *
     * @return ERC-165 selector (interface ID)
     */
    function settleLabor(address member, uint32 labor, bytes32 uid) external returns(bytes4);
}
