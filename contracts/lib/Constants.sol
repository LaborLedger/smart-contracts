pragma solidity 0.5.13;

contract Constants {
    // Selector for ERC-165
    bytes4 constant INIT_INTERFACE_ID = 0x4ddf47d4;             // i.e. `bytes4(keccak256("init(bytes)"))`
    bytes4 constant LOGLABORLEDGER__INTERFACE_ID = 0xf3dfab1e;  // i.e. `bytes4(keccak256("logLaborLedger(address)"))`;
}