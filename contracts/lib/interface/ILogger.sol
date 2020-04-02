pragma solidity 0.5.13;

interface ILogger {
    /**
    * @return ERC-165 selector
    */
    function logAddress(address account) external returns(bytes4);
    function logBytes32(bytes32 _bytes) external returns(bytes4);
    function logTwoBytes32(bytes32 bytesA, bytes32 bytesB) external returns(bytes4);
}
