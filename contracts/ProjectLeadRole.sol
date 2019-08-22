pragma solidity 0.5.11;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Roles.sol";


contract ProjectLeadRole {
    using Roles for Roles.Role;

    event ProjectLeadAdded(address indexed account);
    event ProjectLeadRemoved(address indexed account);

    Roles.Role private _leads;

    constructor () internal {
        _addProjectLead(msg.sender);
    }

    modifier onlyProjectLead() {
        require(
            isProjectLead(msg.sender),
            "ProjectLeadRole: caller does not have the Project Lead role"
        );
        _;
    }

    function isProjectLead(address account) public view returns (bool) {
        return _leads.has(account);
    }

    function addProjectLead(address account) public onlyProjectLead {
        _addProjectLead(account);
    }

    function renounceProjectLead() public {
        _removeProjectLead(msg.sender);
    }

    function _addProjectLead(address account) internal {
        _leads.add(account);
        emit ProjectLeadAdded(account);
    }

    function _removeProjectLead(address account) internal {
        _leads.remove(account);
        emit ProjectLeadRemoved(account);
    }
}