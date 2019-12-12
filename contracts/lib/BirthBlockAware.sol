pragma solidity 0.5.13;

contract BirthBlockAware {
    // Block the contract is deployed in
    uint32 public birthBlock;

    // @dev "constructor" function that shall be called on the "Proxy Caller" deployment
    function initBirthBlock() internal {
        birthBlock = uint32(block.number);
    }
}
