pragma solidity 0.5.13;

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "./Constants.sol";
import "./interface/ICollaboration.sol";

contract CollaborationAware is Context, Constants {

    // address of the collaboration smart-contract
    address internal _collaboration;

    // reserved for upgrades
    uint256[10] __gap;

    modifier onlyCollaboration() {
        require(
            isCollaboration(_msgSender()),
            "sender is not the Collaboration"
        );
        _;
    }

    function getCollaboration() public view returns(address) {
        return _collaboration;
    }

    // @dev "constructor" to be called on deployment
    function _initialize(address collaboration) internal {
        require(collaboration != address(0), "Invalid Collaboration address");
        _collaboration = collaboration;
    }

    function isCollaboration(address account) public view returns (bool) {
        return account == getCollaboration();
    }

    function isQuorum(address account) public view returns(bool) {
        return ICollaboration(getCollaboration()).isQuorum(account);
    }

    function _getInvite(bytes memory invite) internal view returns(bytes32) {
        return ICollaboration(getCollaboration()).getInvite(invite);
    }

    function _clearInvite(bytes memory invite) internal {
        ICollaboration(getCollaboration()).clearInvite(invite);
    }
}
