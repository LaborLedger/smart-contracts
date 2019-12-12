pragma solidity 0.5.13;

interface IErc165Compatible {

    /**
    * @dev the ERC-165 supportsInterface function
    */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
}
