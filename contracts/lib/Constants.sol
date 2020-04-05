pragma solidity 0.5.13;

contract Constants {

    // in Time Units
    uint16 constant STD_MAX_TIME_WEEKLY = 55 hours / 5 minutes;
    uint16 constant MAX_MAX_TIME_WEEKLY = 100 hours / 5 minutes;

    uint16 constant LATEST_START_WEEK = 3130;       // week index for 31/12/2030

    // Default factors to convert Time Units into Labor Units (Uint8[4] packed into Uint32)
    uint32 constant WEIGHTS = 0x04030201;           // ADVISER=04, SENIOR=03, STANDARD=02, JUNIOR=01
    uint8 constant internal NO_WEIGHT = 0x00;

    // in Share Units
    uint32 constant LABOR_EQUITY = 100000;
    uint32 constant MANAGER_EQUITY = 900000;
    uint32 constant INVESTOR_EQUITY = 0;
    uint32 constant HUNDRED_PERCENT = 1000000;
    uint256 constant HUNDRED_PERCENT256 = 1000000;

    // ERC-165 Selectors and interface IDs

    bytes4 constant LOGADDRESS_SEL = 0x5f91b0af;    // `bytes4(keccak256("logAddress(address)"))`
    bytes4 constant LOGBYTES32_SEL = 0x2d21d6f7;    // `bytes4(keccak256("logBytes32(bytes32)"))`
    bytes4 constant LOG2BYTES32_SEL = 0xfa7a0767;   // `bytes4(keccak256("logTwoBytes32(bytes32,bytes32)"))`
    bytes4 constant LOGGER_IFACE = LOGADDRESS_SEL ^ LOGBYTES32_SEL ^ LOG2BYTES32_SEL;

    bytes4 constant ISQUORUM_SEL = 0x84f8d402;      // isQuorum(address)
    bytes4 constant GETINVITE_SEL = 0x1fe1476d;     // `bytes4(keccak256("getInvite(bytes32)"))`
    bytes4 constant CLEARINVITE_SEL = 0xc6df1383;   // `bytes4(keccak256("clearInvite(bytes32)"))`
    bytes4 constant COLLABORATION_IFACE = ISQUORUM_SEL ^ GETINVITE_SEL ^ CLEARINVITE_SEL;

    bytes4 constant SETTLELABOR_SEL = 0xfc236188;   // `bytes4(keccak256("settleLabor(address,uint32,bytes32)"))`
    bytes4 constant LABORLEDGER_IFACE = SETTLELABOR_SEL;
}
