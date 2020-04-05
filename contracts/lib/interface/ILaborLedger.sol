pragma solidity 0.5.13;

interface ILaborLedger {

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

    /**
     * @return The net (unsettled) Labor Units of a member
     */
    function getMemberNetLabor(address member) external view returns(uint32);

    /**
     * @return The share of net Labor Units of a member in total net Labor Units of all members
     * (the share is expressed in Share Units)
     */
    function getMemberLaborShare(address member) external view returns(uint32);

    /**
     * @dev Book (register) settlement of Labor Units of a member
     * (in decreases net Labor Units and remaining share in total net Labor Units of the member)
     *
     * @return ERC-165 selector (interface ID)
     */
    function settleLabor(address member, uint32 labor, bytes32 uid) external returns(bytes4);
}
