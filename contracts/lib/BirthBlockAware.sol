pragma solidity 0.5.11;

contract BirthBlockAware {
    // Block the contract is deployed in
    uint32 public birthBlock;

    constructor() internal {
        birthBlock = uint32(block.number);
    }
}
