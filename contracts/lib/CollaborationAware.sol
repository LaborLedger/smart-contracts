pragma solidity 0.5.13;

import "./Constants.sol";
import "./ICollaboration.sol";

contract CollaborationAware is Constants {

    // address of the collaboration smart-contract
    address public collaboration;

    // @dev "constructor" function that shall be called on the "Proxy Caller" deployment
    function initCollaboration(address _collaboration) internal {
        require(_collaboration != address(0), "Invalid Collaboration address");

        bytes4 result = ICollaboration(_collaboration).logLaborLedger(address(this));
        require(result == LOGLABORLEDGER__INTERFACE_ID, "LogLaborLager unsupported");

        collaboration = _collaboration;
    }
}
