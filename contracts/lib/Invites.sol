pragma solidity 0.5.13;

contract Invites {

    // @dev invite hash => invite data
    mapping (bytes32 => bytes32) private _invites;

    uint256[10] __gap;              // reserved for upgrades

    event NewInvite(bytes32 inviteHash);
    event KilledInvite(bytes32 inviteHash);

    function getInvite(bytes calldata invite) external view returns(bytes32)
    {
        return _invites[keccak256(invite)];
    }

    function isInvite(bytes32 inviteHash) external view returns(bool)
    {
        return uint256(_invites[inviteHash]) != 0;
    }

    function _newInvite(bytes32 inviteHash, bytes32 inviteData) internal {
        require(inviteData != 0, "Invalid invite data");
        require(_invites[inviteHash] == 0, "Duplicated invite");
        _invites[inviteHash] = inviteData;
        emit NewInvite(inviteHash);
    }

    function _clearInvite(bytes memory invite) internal {
        bytes32 inviteHash = keccak256(invite);
        _cancelInvite(inviteHash);
    }

    function _cancelInvite(bytes32 inviteHash) internal {
        require(_invites[inviteHash] != 0, "Invalid or cleared invite");

        delete _invites[inviteHash];
        emit KilledInvite(inviteHash);
    }

}
