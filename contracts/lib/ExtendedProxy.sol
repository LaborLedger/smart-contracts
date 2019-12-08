pragma solidity 0.5.13;

import "./Constants.sol";
import "./Proxy.sol";

contract ExtendedProxy is Constants, Proxy {

    function delegatecallInit(bytes memory initParams) internal {
        address _impl = implementation();
        bytes memory _initParams = abi.encodePacked(INIT_INTERFACE_ID, initParams);
        (bool success, bytes memory result) = _impl.delegatecall(_initParams);
        if (!success || (abi.decode(result, (bytes4)) != INIT_INTERFACE_ID)) {
            revert("DelegateCallInit is unsupported");
        }
    }
}
