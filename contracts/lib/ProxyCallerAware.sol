pragma solidity 0.5.11;

contract ProxyCallerAware {
    /** @dev
    * The body of this contract intentionally has comments only.
    *
    * The contract "inheriting" this "code" is meant to be the `Proxy Implementation` contract.
    * The Implementation's code is supposed to be delegatecall`ed by the `Proxy Caller` contract.
    *
    * The Implementation must be deployed before the Caller.
    * One or more instances of the Caller will use the same instance of the Implementation.
    * So the `constructor` of the Implementation will NOT be called on the Caller Deployment.
    * Therefore the Implementation code initializing the Caller state shall be in `function init(...) external`
    * rather then in its `constructor` (make sure the `init` reverts if called twice).
    * The `init` shall be delegatecall`ed from the Caller's `constructor`.
    *
    * On `delegatecall`, the Implementation writes directly into the storage of the Caller.
    * As the Caller writes own data in the slots 0 and 1 the Implementation must NEVER write into these slots.
    *
    * To avoid overwriting a slot, the Implementation must skip the slot explicitly or implicitly by:
    * - either declaring first variables which occupy two slots and leaving these variables unset
    * - or declaring two mapping before other storage variables
    *   (a mapping occupies the first free slot but never writes into it)
    *
    * To save storage slots the project uses the second approach (mappings).
    */

    // Uncomment following two lines to apply the first approach
    // uint256 private _intentionallySkippedStorageSlotZero;
    // uint256 private _intentionallySkippedStorageSlotOne;
}
