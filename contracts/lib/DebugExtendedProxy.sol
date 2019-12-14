pragma solidity 0.5.13;

import "./Constants.sol";
import "./Proxy.sol";

/**
 * @title Extended Proxy with debug helpers
 * Borrowed from:
 * https://ethereum.stackexchange.com/questions/77475/what-data-is-in-calldataload
 */
contract ExtendedProxy is Constants, Proxy {

    event DebugLogUint(uint256 b);
    event DebugLogBytes(bytes b);
    event DebugLogBool(bool b);
    event DebugLogNote(
        bytes4 indexed selector,
        address indexed caller,
        bytes32 indexed arg1,
        bytes32 indexed arg2,
        bytes data
    ) anonymous;

    modifier logNote {
        _;
        assembly {
        // log an 'anonymous' event DebugLogNote with a constant 6 words of calldata
        // and four indexed topics: selector, caller, arg1 and arg2
            let mark := msize                       // end of memory ensures zero
            mstore(0x40, add(mark, 288))            // update free memory pointer
            mstore(mark, 0x20)                      // bytes type data offset
            mstore(add(mark, 0x20), 224)            // bytes size (padded)
            calldatacopy(add(mark, 0x40), 0, 224)   // bytes payload
            log4(mark, 288,                         // calldata
            shl(224, shr(224, calldataload(0))),   // msg.sig
            caller,                                // msg.sender
            calldataload(4),                       // arg1
            calldataload(36)                       // arg2
            )
        }
    }

    function delegatecallInit(uint256 initParams) internal {
        address _impl = implementation();
        bytes memory _initParams = abi.encodePacked(INIT_INTERFACE_ID, initParams);
        emit DebugLogUint(initParams);
        emit DebugLogBytes(_initParams);
        (bool success, bytes memory result) = _impl.delegatecall(_initParams);
        emit DebugLogBool(success);
        emit DebugLogBytes(result);
        bytes4 response = abi.decode(result, (bytes4));
        if (!success || response != INIT_INTERFACE_ID) {
            revert("DelegateCallInit is unsupported");
        }
    }

    function _delegatecallUint(uint INTERFACE_ID, uint256 uintParam) public {
        emit DebugLogUint(uintParam);
        bytes memory _packed = abi.encodePacked(INTERFACE_ID, uintParam);
        emit DebugLogBytes(_packed);
        address _impl = implementation();
        (bool success, bytes memory result) = _impl.delegatecall(_packed);
        emit DebugLogBool(success);
        emit DebugLogBytes(result);
    }

    function _delegatecallBytes(uint INTERFACE_ID, bytes memory bytesParam) public {
        emit DebugLogBytes(bytesParam);
        bytes memory _packed = abi.encodePacked(INTERFACE_ID, bytesParam);
        emit DebugLogBytes(_packed);
        address _impl = implementation();
        (bool success, bytes memory result) = _impl.delegatecall(_packed);
        emit DebugLogBool(success);
        emit DebugLogBytes(result);
    }

    function _delegatecallNoParams(uint INTERFACE_ID) public {
        bytes memory _packed = abi.encodePacked(INTERFACE_ID);
        emit DebugLogBytes(_packed);
        address _impl = implementation();
        (bool success, bytes memory result) = _impl.delegatecall(_packed);
        emit DebugLogBool(success);
        emit DebugLogBytes(result);
    }
}
