pragma solidity 0.5.13;

import "./lib/UpgradableProxy.sol";
import "./lib/PackedInitParamsAware.sol";

contract LaborLedgerCaller is PackedInitParamsAware, UpgradableProxy {

    /**
     * @param implementation <address> instance of LaborLedgerImplementation contract
     * @param _collaboration <address> instance of Collaboration contract
     * @param _terms <bytes32> project terms of collaboration
     * @param _startWeek <uint16> project first week as Week Index (default - previous week)
     * @param _managerEquity <uint32> manager equity pool in Share Units
     * @param _investorEquity <uint32> investor equity pool in Share Units
     * @param _weights <uint8[4]> weights for _ (ignored), STANDARD, SENIOR, ADVISER
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

        bytes memory initParams = packInitParams(
            _collaboration,
            _terms,
            _startWeek,
            _managerEquity,
            _investorEquity,
            packWeights(_weights)
        );

        init(initParams);
    }
}
