pragma solidity 0.5.13;

import "./lib/Constants.sol";
import "./lib/CollaborationRoles.sol";
import "./lib/Erc165Compatible.sol";
import "./lib/interface/IErc165Compatible.sol";
import "./lib/interface/ICollaboration.sol";
import "./lib/interface/ILogger.sol";
import "./lib/Invites.sol";
import "./LaborLedgerProxy.sol";

contract CollaborationImpl is
    Initializable,
    Context,
    Constants,
    ICollaboration,
    Erc165Compatible,
    CollaborationRoles,
    Invites
{

    struct Collaboration {
        bytes32 uid;
        address laborLedger;
        address logger;
                                    // Equity pools expressed in Share Units (100%=(1)+(2)+(3))
        uint32 managerEquity;       // (1) management equity pool
        uint32 investorEquity;      // (2) investor equity pool
        uint32 laborEquity;         // (3) labor-units-based equity pool
    }

    Collaboration internal _collab;

    uint256[10] __gap;              // reserved for upgrades

    event EquityModified(
        // in Share Units
        uint32 newManagerEquity,
        uint32 newInvestorEquity,
        uint32 newLaborEquity
    );

    /**
    * @dev "constructor" to be delegatecall`ed on deployment of Proxy
    *
    * @param managerEquity <uint32> manager equity pool in Share Units
    * @param investorEquity <uint32> investor equity pool in Share Units
    */
    function initialize(
        bytes32 uid,
        address logger,
        address quorum,
        address inviter,
        uint32 managerEquity,
        uint32 investorEquity,
        uint32 laborEquity,
        address laborLedgerImpl,
        address projectLead,
        address projectArbiter,
        address defaultOperator,
        uint16 startWeek,
        uint32 weights
    ) public initializer
    {
        _collab.uid = uid;

        require(logger != address(0), "Invalid logger address");
        bytes4 result = ILogger(logger).logAddress(address(this));
        require(result == LOGADDRESS_SEL, "Invalid logger");
        _collab.logger = logger;

        CollaborationRoles._initialize(quorum, inviter);

        if (managerEquity != 0 || investorEquity != 0 || laborEquity != 0) {
            _setEquity(managerEquity, investorEquity, laborEquity);
        } else {
            _setEquity(MANAGER_EQUITY, INVESTOR_EQUITY, LABOR_EQUITY);
        }

        _collab.laborLedger = address(new LaborLedgerProxy(
            laborLedgerImpl,
            address(this),
            projectLead,
            projectArbiter,
            defaultOperator,
            startWeek,
            weights
        ));
    }

    function getUid() external view returns(bytes32)
    {
        return _collab.uid;
    }

    function getEquity() external view
        returns(uint32 laborEquityPool, uint32 managerEquityPool, uint32 investorEquityPool)
    {
        return (
            _collab.laborEquity,
            _collab.managerEquity,
            _collab.investorEquity
        );
    }

    /**
     * @dev Allows quorum to update equity pools
     * @param managerEquity New manager equity pool in Share Units
     *   It may not be greater than previous set equity
     * @param investorEquity New investor equity pool in Share Units
     * @param laborEquity New labor equity pool in Share Units
     */
    function setEquity(
        uint32 managerEquity,
        uint32 investorEquity,
        uint32 laborEquity
    ) external onlyQuorum
    {
        require(
            managerEquity <= _collab.managerEquity,
            "management equity can't increase"
        );
        _setEquity(managerEquity, investorEquity, laborEquity);
    }

    function newInvite(bytes32 inviteHash, bytes32 inviteData) external onlyInviter {
        _newInvite(inviteHash, inviteData);
    }


    function cancelInvite(bytes32 inviteHash) external onlyInviter {
        _clearInvite(inviteHash);
    }

    function clearInvite(bytes32 inviteHash) external {
        require(_msgSender() == _collab.laborLedger, "sender can't clear invites");
        _clearInvite(inviteHash);
    }

    function _setEquity(uint32 managerEquity, uint32 investorEquity, uint32 laborEquity) internal
    {
        uint totalEquity = managerEquity + investorEquity + laborEquity;
        require(totalEquity == HUNDRED_PERCENT, "must sum to exactly 1000000 (100%)");

        _collab.managerEquity = managerEquity;
        _collab.investorEquity = investorEquity;
        _collab.laborEquity = laborEquity;
        emit EquityModified(managerEquity, investorEquity, laborEquity);
    }

    function _supportInterface(bytes4 interfaceID) internal pure returns (bool) {
        return
            interfaceID == GETINVITE_SEL ||
            interfaceID == CLEARINVITE_SEL ||
            super._supportInterface(interfaceID);
    }
}
