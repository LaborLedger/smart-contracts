pragma solidity 0.5.13;

import "./lib/Constants.sol";
import "./lib/Erc165Compatible.sol";
import "./lib/interface/ILogger.sol";

contract Logger is Constants, Erc165Compatible, ILogger {

    event Address(address indexed account);
    event Bytes32(bytes32 indexed _bytes);
    event TwoBytes32(bytes32 bytesA, bytes32 bytesB);

    function logAddress(address account) external returns(bytes4) {
        emit Address(account);
        return  LOGADDRESS_SEL;
    }

    function logBytes32(bytes32 _bytes) external returns(bytes4) {
        emit Bytes32(_bytes);
        return  LOGBYTES32_SEL;
    }

    function logTwoBytes32(bytes32 bytesA, bytes32 bytesB) external returns(bytes4) {
        emit TwoBytes32(bytesA, bytesB);
        return  LOG2BYTES32_SEL;
    }

    // @dev ERC-165 supportsInterface realization
    function _supportInterface(bytes4 interfaceID) internal pure returns (bool) {
        return
            interfaceID == LOGADDRESS_SEL ||
            interfaceID == LOGBYTES32_SEL ||
            interfaceID == LOG2BYTES32_SEL ||
            super._supportInterface(interfaceID);
    }
}
