pragma solidity 0.5.13;

contract Constants {
    // Selector for use with ERC-165
    bytes4 constant INIT_INTERFACE_ID = 0xb7b0422d;             // i.e. `bytes4(keccak256("init(uint256)"))`
    bytes4 constant LOGLABORLEDGER__INTERFACE_ID = 0xf3dfab1e;  // i.e. `bytes4(keccak256("logLaborLedger(address)"))`;
}
