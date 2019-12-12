pragma solidity 0.5.13;

contract LedgerStatusAware {
    // @dev six bytes reserved on the storage for future use
    uint48 private ledgerStatus;
}
