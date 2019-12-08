pragma solidity 0.5.13;

interface ICollaboration {
    /**
    * @return ERC-165 Interface ID
    */
    function logLaborLedger(address laborLedger) external returns(bytes4);
}
