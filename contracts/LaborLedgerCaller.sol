pragma solidity 0.5.13;

import "./lib/ExtendedProxy.sol";
import "./lib/PackedInitParamsAware.sol";

contract LaborLedgerCaller is PackedInitParamsAware, ExtendedProxy {

    // @dev this contract expects the implementation contract NEVER writes in storage slots 0 and 1
    address public implementor;         // @dev storage slot 0
    address private _implementation;    // @dev storage slot 1
    // @dev be aware the implementation contract overwrites slots following the slot 1

    /**
     * @param implementation <address> instance of LaborLedgerImplementation contract
     * @param _collaboration <address> instance of Collaboration contract
     * @param _terms <bytes32> project terms of collaboration (default: 0)
     * @param _startWeek <uint16> project first week as Week Index (default - previous week)
     * @param _managerEquity <uint32> manager equity pool in Share Units (default 9000000)
     * @param _investorEquity <uint32> investor equity pool in Share Units (default 0)
     * @param _weights <uint[4]> weights, as a fraction of the STANDARD weight
     *     default: [0, 2, 3, 4] for _ (ignored), STANDARD, SENIOR, ADVISER
     *
     *  @dev _collaboration is the only mandatory param
     *       ... provide zero value(s) for any other param(s) to set default value(s)
     */
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

        uint256 initParams = packInitParams(
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

    function setImplementor(address newImplementor) external {
        require(msg.sender == implementor);
        require(newImplementor != address(0), "invalid new implementor");
        implementor = newImplementor;
    }
}
