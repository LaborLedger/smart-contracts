pragma solidity 0.5.13;

import "./interface/IErc165Compatible.sol";

contract Erc165Compatible is IErc165Compatible {

    bytes4 constant erc165Selector = 0x01ffc9a7;    // i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`

    /**
    * @dev The implementation of the ERC-165 supportsInterface function
    */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        if (interfaceID == erc165Selector) return true;
        return  _supportInterface(interfaceID);
    }

    /**
    * @dev a Child-class is expected to re-define the method
    */
    function _supportInterface(bytes4 interfaceID) internal pure returns (bool) {
        return interfaceID == erc165Selector;
    }
}
