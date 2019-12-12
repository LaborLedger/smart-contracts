pragma solidity 0.5.13;

import "openzeppelin-solidity/contracts/access/Roles.sol";


contract RolesAware {
    using Roles for Roles.Role;

    event ProjectLeadAdded(address indexed account);
    event ProjectQuorumAdded(address indexed account);

    event ProjectLeadRemoved(address indexed account);
    event ProjectQuorumRemoved(address indexed account);

    Roles.Role private _leads;
    Roles.Role private _quorums;

    // @dev "constructor" function that shall be called on the "Proxy Caller" deployment
    function initRoles() internal {
        _addProjectLead(msg.sender);
        _addProjectQuorum(msg.sender);
    }

    modifier onlyProjectLead() {
        require(
            isProjectLead(msg.sender),
            "caller does not have the Project Lead role"
        );
        _;
    }

    modifier onlyProjectQuorum() {
        require(
            isProjectQuorum(msg.sender),
            "caller does not have the Project DAO role"
        );
        _;
    }

    function isProjectLead(address account) public view returns (bool) {
        return _leads.has(account);
    }

    function isProjectQuorum(address account) public view returns (bool) {
        return _quorums.has(account);
    }

    function addProjectLead(address account) public onlyProjectQuorum {
        _addProjectLead(account);
    }

    function addProjectQuorum(address account) public onlyProjectQuorum {
        _addProjectQuorum(account);
    }

    function renounceProjectLead() public onlyProjectQuorum {
        _removeProjectLead(msg.sender);
    }

    function renounceProjectQuorum() public onlyProjectQuorum {
        _removeProjectQuorum(msg.sender);
    }

    function _addProjectLead(address account) internal {
        _leads.add(account);
        emit ProjectLeadAdded(account);
    }

    function _addProjectQuorum(address account) internal {
        _quorums.add(account);
        emit ProjectQuorumAdded(account);
    }

    function _removeProjectLead(address account) internal {
        _leads.remove(account);
        emit ProjectLeadRemoved(account);
    }

    function _removeProjectQuorum(address account) internal {
        _quorums.remove(account);
        emit ProjectQuorumRemoved(account);
    }
}
