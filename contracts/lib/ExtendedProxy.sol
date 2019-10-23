pragma solidity 0.5.11;

import "./Proxy.sol";

contract ExtendedProxy is Proxy {
    // Selector for 'function init(uint256)' = bytes4(keccak256("init(uint256)"))
    bytes4 constant initFnSelector = 0xb7b0422d;

    function delegatecallInit(uint256 initParams) internal {
        address _impl = implementation();
        bytes memory _initParams = abi.encodePacked(initFnSelector, initParams);
        _impl.delegatecall(_initParams);
    }
}
