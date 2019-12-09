pragma solidity 0.5.13;

interface IDelegatecallInit {
    /**
    * @param {uint256} initParams packed arbitrary params
    * @return {bytes4} ERC-165 Interface ID
    */
    function init(bytes calldata initParams) external returns (bytes4);
}
