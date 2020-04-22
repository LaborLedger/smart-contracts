pragma solidity 0.5.13;

import "./lib/Constants.sol";
import "./lib/CollaborationRoles.sol";
import "./lib/Erc165Compatible.sol";
import "./lib/interface/IErc165Compatible.sol";
import "./lib/interface/ICollaboration.sol";
import "./lib/Invites.sol";
import "./LaborLedgerProxy.sol";
import "./lib/Operators.sol";
import "./lib/SafeMath32.sol";

contract CollaborationImpl is
Initializable,
Context,
Constants,
ICollaboration,
Erc165Compatible,
CollaborationRoles,
Operators,
Invites
{
    using SafeMath32 for uint32;

    struct Collaboration {
        bytes32 uid;
        address laborLedger;
        address token;

        // Equity pools expressed in Share Units (100%=(1)+(2)+(3))
        uint32 managerEquity;       // (1) management equity pool
        uint32 investorEquity;      // (2) investor equity pool
        uint32 laborEquity;         // (3) labor-units-based equity pool
    }

    Collaboration internal _collab;

    uint256[10] __gap;              // reserved for upgrades

    event LaborLedger(address indexed account);

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
        address proxyAdmin,
        bytes32 uid,
        address quorum,
        address inviter,
        uint32 managerEquity,
        uint32 investorEquity,
        uint32 laborEquity,
        address laborLedgerImpl,
        address projectLead,
        address projectArbiter,
        address defaultOperator,
        uint16 startWeek
    ) public initializer
    {
        _collab.uid = uid;

        CollaborationRoles._initialize(quorum, inviter);
        Operators._initialize(defaultOperator);

        if (managerEquity != 0 || investorEquity != 0 || laborEquity != 0) {
            _setEquity(managerEquity, investorEquity, laborEquity, true);
        } else {
            _setEquity(MANAGER_EQUITY, INVESTOR_EQUITY, LABOR_EQUITY, true);
        }

        _collab.laborLedger = address(new LaborLedgerProxy(
            laborLedgerImpl,
            proxyAdmin,
            address(this),
            projectLead,
            projectArbiter,
            defaultOperator,
            startWeek
        ));
        emit LaborLedger(_collab.laborLedger);
    }

    function getUid() external view returns(bytes32)
    {
        return _collab.uid;
    }

    function getLaborLedger() external view returns(address)
    {
        return _collab.laborLedger;
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

    function getMemberLaborEquity(address member) external view returns(uint32 equity)
    {
        if (_collab.laborEquity != 0) {
            (uint32 share, ) = ILaborLedger(_collab.laborLedger).getMemberLaborShare(member);
            if (share != 0) {
                equity = uint32(uint256(_collab.laborEquity) * uint256(share) / HUNDRED_PERCENT256);
            }
        }
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
        _setEquity(managerEquity, investorEquity, laborEquity, false);
    }

    function setEquity(
        address quorum,
        uint32 managerEquity,
        uint32 investorEquity,
        uint32 laborEquity
    ) external
    {
        require(isQuorum(quorum), "unauthorized quorum");
        require(isOperatorFor(_msgSender(), quorum), "unauthorized operator");
        _setEquity(managerEquity, investorEquity, laborEquity, false);
    }

    function newInvite(bytes32 inviteHash, bytes32 inviteData) external onlyInviter
    {
        _newInvite(inviteHash, inviteData);
    }

    function newInvite(address inviter, bytes32 inviteHash, bytes32 inviteData) external
    {
        require(isInviter(inviter), "unauthorized inviter");
        require(isOperatorFor(_msgSender(), inviter), "unauthorized inviter");
        _newInvite(inviteHash, inviteData);
    }

    function cancelInvite(bytes32 inviteHash) external onlyInviter
    {
        _cancelInvite(inviteHash);
    }

    function cancelInvite(address inviter, bytes32 inviteHash) external
    {
        require(isInviter(inviter), "unauthorized inviter");
        require(isOperatorFor(_msgSender(), inviter), "unauthorized inviter");
        _cancelInvite(inviteHash);
    }

    function clearInvite(bytes calldata invite) external
    {
        _clearInvite(invite);
    }

    function _setEquity(
        uint32 managerEquity,
        uint32 investorEquity,
        uint32 laborEquity,
        bool skipManagerPoolCheck
    ) internal
    {
        require(
            skipManagerPoolCheck || managerEquity <= _collab.managerEquity,
            "management equity can't increase"
        );

        uint totalEquity = managerEquity + investorEquity + laborEquity;
        require(totalEquity == HUNDRED_PERCENT, "must sum to exactly 1000000 (100%)");

        _collab.managerEquity = managerEquity;
        _collab.investorEquity = investorEquity;
        _collab.laborEquity = laborEquity;
        emit EquityModified(managerEquity, investorEquity, laborEquity);
    }

    function _supportInterface(bytes4 interfaceID) internal pure returns (bool)
    {
        return
            interfaceID == GETINVITE_SEL ||
            interfaceID == CLEARINVITE_SEL ||
            super._supportInterface(interfaceID);
    }
}
