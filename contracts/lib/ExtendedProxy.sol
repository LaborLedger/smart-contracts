pragma solidity 0.5.13;

import "./Constants.sol";
import "./Proxy.sol";

contract ExtendedProxy is Constants, Proxy {

    event DebugLogUint(uint256 b);
    event DebugLogBytes(bytes b);
    event DebugLogBool(bool b);

    function delegatecallInit(uint256 initParams) internal {
        address _impl = implementation();
        bytes memory _initParams = abi.encodePacked(INIT_INTERFACE_ID, initParams);
        emit DebugLogUint(initParams);
        emit DebugLogBytes(_initParams);
        (bool success, bytes memory result) = _impl.delegatecall(_initParams);
        emit DebugLogBool(success);
        emit DebugLogBytes(result);
        if (!success || (abi.decode(result, (bytes4)) != INIT_INTERFACE_ID)) {
            revert("DelegateCallInit is unsupported");
        }
    }

    function _delegatecall(uint INTERFACE_ID, bytes memory params) public {
        emit DebugLogBytes(params);
        bytes memory _packed = abi.encodePacked(INTERFACE_ID, params);
        emit DebugLogBytes(_packed);
        address _impl = implementation();
        (bool success, bytes memory result) = _impl.delegatecall(_packed);
        emit DebugLogBool(success);
        emit DebugLogBytes(result);
    }
}
