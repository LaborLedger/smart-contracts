pragma solidity 0.5.13;

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";


contract CollaborationRoles is Context {
    using Roles for Roles.Role;

    event QuorumAdded(address indexed account);
    event QuorumRemoved(address indexed account);
    event InviterAdded(address indexed account);
    event InviterRemoved(address indexed account);

    Roles.Role private _quorums;
    Roles.Role private _inviters;

    uint256[10] __gap; // reserved for upgrades

    // @dev "constructor" to be called on deployment
    function _initialize(address quorum, address inviter) internal {
        _addQuorum(quorum == address (0) ? _msgSender() : quorum);
        _addInviter(inviter == address (0) ? _msgSender() : inviter);
    }

    modifier onlyQuorum() {
        require(
            isQuorum(_msgSender()),
            "caller does not have the Quorum role"
        );
        _;
    }

    modifier onlyInviter() {
        require(
            isInviter(_msgSender()),
            "caller does not have the Inviter role"
        );
        _;
    }

    function isQuorum(address account) public view returns (bool) {
        return _quorums.has(account);
    }

    function isInviter(address account) public view returns (bool) {
        return _inviters.has(account);
    }

    function addQuorum(address account) public onlyQuorum {
        _addQuorum(account);
    }

    function addInviter(address account) public onlyQuorum {
        _addInviter(account);
    }

    function renounceQuorum() public onlyQuorum {
        _removeQuorum(_msgSender());
    }

    function renounceInviter() public onlyQuorum {
        _removeQuorum(_msgSender());
    }

    function _addQuorum(address account) internal {
        _quorums.add(account);
        emit QuorumAdded(account);
    }

    function _addInviter(address account) internal {
        _inviters.add(account);
        emit InviterAdded(account);
    }

    function _removeQuorum(address account) internal {
        _quorums.remove(account);
        emit QuorumRemoved(account);
    }

    function _removeInviter(address account) internal {
        _inviters.remove(account);
        emit InviterRemoved(account);
    }
}
