pragma solidity 0.5.13;

import "./Constants.sol";
import "./Proxy.sol";

contract UpgradableProxy is Constants, Proxy {

    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    // @dev this contract expects the implementation contract NEVER writes in storage slots 0 and 1
    address public implementor;         // @dev storage slot 0
    address private _implementation;    // @dev storage slot 1
    // @dev be aware the implementation contract overwrites slots following the slot 1

    function implementation() public view returns (address) {
        return _implementation;
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

    function _setImplementation(address newImplementation) internal {
        require(newImplementation != address (0), "invalid implementation address");
        _implementation = newImplementation;
        emit Upgraded(newImplementation);
    }

    function init(bytes memory initParams) internal {
        address _impl = implementation();
        require(_impl != address(0), 'no implementation');

        bytes memory _initParams = abi.encodeWithSelector(INIT_INTERFACE_ID, initParams);
        (bool success, bytes memory result) = _impl.delegatecall(_initParams);

        if (!success || (abi.decode(result, (bytes4)) != INIT_INTERFACE_ID)) {
            revert("init is unsupported");
        }
    }
}
