pragma solidity 0.5.11;

contract Erc165Compatible {

    bytes4 constant erc165Selector = 0x01ffc9a7;    // i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`
    bytes4 constant initFnSelector = 0xb7b0422d;    // i.e. `bytes4(keccak256("init(uint256)"))`

    /**
    * @dev The implementation of the ERC-165 supportsInterface function
    */
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return  interfaceID == erc165Selector ||    // ERC-165 support
                interfaceID == initFnSelector;      // "init" method support
    }
}
