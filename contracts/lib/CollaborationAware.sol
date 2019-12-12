pragma solidity 0.5.13;

contract CollaborationAware {

    // address of the collaboration smart-contract
    address public collaboration;

    // @dev "constructor" function that shall be called on the "Proxy Caller" deployment
    function initCollaboration(address _collaboration) internal {
        require(_collaboration != address(0), "Invalid collaboration contract address");
        collaboration = _collaboration;
    }
}
