pragma solidity 0.5.13;

interface ICollaboration {
    function isQuorum(address account) external view returns (bool);
    function getInvite(bytes32 inviteHash) external view returns(bytes32);
    function clearInvite(bytes32 inviteHash) external;
}
