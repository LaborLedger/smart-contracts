pragma solidity 0.5.13;

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Roles.sol";


contract LaborLedgerRoles is Context {
    using Roles for Roles.Role;

    event ProjectLeadAdded(address indexed account);
    event ProjectArbiterAdded(address indexed account);

    event ProjectLeadRemoved(address indexed account);
    event ProjectArbiterRemoved(address indexed account);

    Roles.Role private _leads;
    Roles.Role private _arbiters;
    uint256[10] __gap; // reserved for upgrades

    // @dev "constructor" to be called on deployment
    function _initialize(
        address projectLead,
        address projectArbiter
    ) internal {
        address sender = _msgSender();
        _addProjectLead( projectLead == address (0) ? sender : projectLead);
        _addProjectArbiter(projectArbiter == address (0) ? sender : projectArbiter);
    }

    modifier onlyProjectLead() {
        require(
            isProjectLead(_msgSender()),
            "caller does not have the Project Lead role"
        );
        _;
    }

    modifier onlyProjectArbiter() {
        require(
            isProjectArbiter(_msgSender()),
            "caller does not have the Project Arbiter role"
        );
        _;
    }

    function isProjectLead(address account) public view returns (bool) {
        return _leads.has(account);
    }

    function isProjectArbiter(address account) public view returns (bool) {
        return _arbiters.has(account);
    }

    function addProjectLead(address account) public
    {
        requireQuorum(_msgSender());
        _addProjectLead(account);
    }

    function addProjectArbiter(address account) public
    {
        requireQuorum(_msgSender());
        _addProjectArbiter(account);
    }

    function renounceProjectLead() public
    {
        requireQuorum(_msgSender());
        _removeProjectLead(_msgSender());
    }

    function renounceProjectArbiter() public
    {
        requireQuorum(_msgSender());
        _removeProjectArbiter(_msgSender());
    }

    // Child contract must redefine it
    function isQuorum(address account) public view returns(bool);

    function _addProjectLead(address account) internal {
        _leads.add(account);
        emit ProjectLeadAdded(account);
    }

    function _addProjectArbiter(address account) internal {
        _arbiters.add(account);
        emit ProjectArbiterAdded(account);
    }

    function _removeProjectLead(address account) internal {
        _leads.remove(account);
        emit ProjectLeadRemoved(account);
    }

    function _removeProjectArbiter(address account) internal {
        _arbiters.remove(account);
        emit ProjectArbiterAdded(account);
    }

    function requireQuorum(address account) internal view {
        require(isQuorum(account), "caller does not have the Quorum role");
    }
}
