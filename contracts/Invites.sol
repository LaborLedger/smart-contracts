pragma solidity 0.5.13;

contract Invites {
    mapping(bytes32 => uint256) private _invitations;

    event NewInvite(bytes32 hashedInvite, uint256 value);
    event InviteUsed(bytes32 hashedInvite);
    event InviteRemoved(bytes32 hashedInvite);

    function _addInvite(bytes32 hashedInvite, uint256 value) internal {
        require(hashedInvite != bytes32(0), "Invalid invite hash");
        _invitations[hashedInvite] = value | 1;
        emit NewInvite(hashedInvite, value);
    }

    function useInvite(uint256 invite) internal returns(uint256) {
        require(invite != uint256(0), "Invalid invite");
        bytes32 hashedInvite = sha256(abi.encodePacked(invite));
        uint256 value = _invitations[hashedInvite];
        if (value != uint256(0)) {
            removeInvite(hashedInvite);
            emit InviteUsed(hashedInvite);
        }
        return value;
    }

    function removeInvite(bytes32 hashedInvite) internal {
        delete _invitations[hashedInvite];
        emit InviteRemoved(hashedInvite);
    }
}
