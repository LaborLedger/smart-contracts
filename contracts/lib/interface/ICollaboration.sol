pragma solidity 0.5.13;

interface ICollaboration {

    function initialize(
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
        uint16 startWeek,
        uint32 weights
    ) external;

    function isQuorum(address account) external view returns (bool);
    function getInvite(bytes calldata invite) external view returns(bytes32);
    function clearInvite(bytes calldata invite) external;
}
