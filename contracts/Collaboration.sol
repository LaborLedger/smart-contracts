pragma solidity 0.5.11;

import "./lib/Constants.sol";
import "./lib/Erc165Compatible.sol";
import "./lib/ICollaboration.sol";

contract Collaboration is Constants, Erc165Compatible, ICollaboration {

    event NewLaborLedger(address indexed laborLedger);

    function logLaborLedger(address laborLedger) external returns(bytes4) {
        emit NewLaborLedger(laborLedger);
        return  LOGLABORLEDGER__INTERFACE_ID;
    }

    function _supportsInterface(bytes4 interfaceID) private pure returns (bool) {
        return  interfaceID ==  LOGLABORLEDGER__INTERFACE_ID;
    }
}
