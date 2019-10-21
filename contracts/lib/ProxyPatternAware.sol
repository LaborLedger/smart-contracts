pragma solidity 0.5.11;

contract ProxyPatternAware {
    /** @dev
    * The body of this contract intentionally has no code lines (it contains comments only).
    *
    * The contract "inheriting" this "code" is meant to be the Proxy Implementation contract.
    * The code of the Implementation is called via `delegatecall` by the Proxy Caller contract.
    *
    * On `delegatecall`, the Implementation writes directly into the storage of the Caller.
    * As the the Caller writes own data in the slots 0 and 1 the Implementation must NEVER write into these slots.
    *
    * To avoid overwriting a free slot, the Implementation must skip the slot explicitly or implicitly by:
    * - either declaring variables which occupy two slots and leaving these variables unset
    * - or declaring two mapping before other storage variables
    *   (a mapping occupies the first free slot but never writes into it)
    *
    * To save storage slots the project uses the second approach (mappings).
    */

    // Uncomment following two lines to apply the first approach
    // uint256 private _intentionallySkippedStorageSlotZero;
    // uint256 private _intentionallySkippedStorageSlotOne;
}
