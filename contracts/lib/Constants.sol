pragma solidity 0.5.13;

contract Constants {

    uint16 constant DEF_MAX_TIME_WEEKLY = 55 hours / 5 minutes;
    uint16 constant MAX_MAX_TIME_WEEKLY = 100 hours / 5 minutes;

    // Selector for ERC-165
    bytes4 constant INIT_INTERFACE_ID = 0x4ddf47d4;             // i.e. `bytes4(keccak256("init(bytes)"))`
    bytes4 constant LOGLABORLEDGER__INTERFACE_ID = 0xf3dfab1e;  // i.e. `bytes4(keccak256("logLaborLedger(address)"))`;
}
