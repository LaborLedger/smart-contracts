pragma solidity 0.5.13;

import "./Constants.sol";
import "./IDelegatecallInit.sol";

contract DelegatecallInitAware is Constants, IDelegatecallInit {

    function _supportsInterface(bytes4 interfaceID) private pure returns (bool) {
        return  interfaceID == INIT_INTERFACE_ID;
    }
}
