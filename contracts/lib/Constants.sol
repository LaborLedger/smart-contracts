pragma solidity 0.5.13;

contract Constants {

    // in Time Units
    uint16 constant DEF_MAX_TIME_WEEKLY = 55 hours / 5 minutes;
    uint16 constant MAX_MAX_TIME_WEEKLY = 100 hours / 5 minutes;

    uint16 constant LATEST_START_WEEK = 3130;   // week index for 31/12/2030

    // default memberWeights (uint8[4] packed into uint32):
    // ADVISER=0x04, SENIOR=0x03, STANDARD=0x02, _=0x00
    uint32 constant MEMBER_WEIGHTS = 0x04030200;

    // in Share Units
    uint32 LABOR_EQUITY = 100000;
    uint32 MANAGER_EQUITY = 900000;
    uint32 INVESTOR_EQUITY = 0;
    uint32 TOTAL_EQUITY = 1000000;

    // Selector for ERC-165
    bytes4 constant INIT_INTERFACE_ID = 0x4ddf47d4;             // i.e. `bytes4(keccak256("init(bytes)"))`
    bytes4 constant LOGLABORLEDGER__INTERFACE_ID = 0xf3dfab1e;  // i.e. `bytes4(keccak256("logLaborLedger(address)"))`;
}
