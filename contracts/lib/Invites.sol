pragma solidity 0.5.13;

contract Invites {

    // @dev invite hash => invite data
    mapping (bytes32 => bytes32) private _invites;

    uint256[10] __gap;              // reserved for upgrades

    event NewInvite(bytes32 inviteHash);
    event InviteCleared(bytes32 inviteHash);

    function getInvite(bytes32 inviteHash) external view returns(bytes32)
    {
        return _invites[inviteHash];
    }

    function _newInvite(bytes32 inviteHash, bytes32 inviteData) internal {
        require(inviteData != 0, "Invalid invite data");
        require(_invites[inviteHash] == 0, "Duplicated invite");
        _invites[inviteHash] = inviteData;
        emit NewInvite(inviteHash);
    }

    function _clearInvite(bytes32 inviteHash) internal {
        if (_invites[inviteHash] != 0) {
            delete _invites[inviteHash];
            emit InviteCleared(inviteHash);
        }
    }
}
