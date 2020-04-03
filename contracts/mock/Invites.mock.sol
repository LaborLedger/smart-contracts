pragma solidity 0.5.13;

import "../lib/Invites.sol";

contract InvitesMock is Invites {

    function newInvite(bytes32 inviteHash, bytes32 inviteData) public {
        _newInvite(inviteHash, inviteData);
    }

    function clearInvite(bytes memory invite) public {
        _clearInvite(invite);
    }

    function cancelInvite(bytes32 inviteHash) public {
        _cancelInvite(inviteHash);
    }

}
