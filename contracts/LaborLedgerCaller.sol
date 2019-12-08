pragma solidity 0.5.13;

import "./lib/ExtendedProxy.sol";
import "./lib/PackedInitParamsAware.sol";

contract LaborLedgerCaller is PackedInitParamsAware, ExtendedProxy {

    // @dev this contract expects the implementation contract NEVER writes in storage slots 0 and 1
    address private _implementation;    // @dev storage slot 0
    address public implementor;         // @dev storage slot 1
    // @dev be aware the implementation contract overwrites slots following the slot 1

    constructor (
        address implementation,
        address _collaboration,
        bytes32 _terms,
        uint16 _startWeek,
        uint32 _managerEquity,
        uint32 _investorEquity,
        uint8[4] memory _weights
    ) public {
        implementor = msg.sender;
        _setImplementation(implementation);

        bytes memory initParams = packInitParams(
            _collaboration,
            _terms,
            _startWeek,
            _managerEquity,
            _investorEquity,
            _weights
        );

        delegatecallInit(initParams);
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
