pragma solidity 0.5.11;

import "./lib/ExtendedProxy.sol";

contract LaborLedgerCaller is ExtendedProxy {

    // @dev this contract expects the implementation contract NEVER writes in storage slots 0 and 1

    address private _implementation;    // @dev storage slot 0
    address public implementor;         // @dev storage slot 1

    // @dev be aware the implementation contract overwrites slots following the slot 1

    constructor (address implementation, address collaboration, uint16 startWeek) public {
        implementor = msg.sender;
        _setImplementation(implementation);
        uint256 _initParams = (uint256(collaboration)<<96) | uint256(startWeek);
        delegatecallInit(_initParams);
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    function _setImplementation(address newImplementation) internal {
        require(newImplementation != address (0), "invalid implementation address");
        _implementation = newImplementation;
    }

    function setImplementation(address newImplementation) external {
        require(msg.sender == implementor);
        _setImplementation(newImplementation);
    }

    function setImplementor(address newOImplementor) external {
        require(msg.sender == implementor);
        require(newOImplementor != address(0), "invalid new implementor");
        implementor = newOImplementor;
    }
}
