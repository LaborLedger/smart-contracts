pragma solidity 0.5.11;

contract CollaborationAware {

    // address of the collaboration smart-contract
    address public collaboration;

    constructor (address _collaboration) internal {
        require(_collaboration != address(0), "Invalid collaboration contract address");
        collaboration = _collaboration;
    }
}
