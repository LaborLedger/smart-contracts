pragma solidity 0.5.13;

import "./SafeMath32.sol";
import "./Constants.sol";
import "./Weeks.sol";
import "./WeeklySubmissions.sol";

contract AdjustableSubmissions is Constants, Weeks, WeeklySubmissions
{
    using SafeMath32 for uint32;

    // Decrease of Time Units submitted by a member for a week
    struct Adjustment {
        uint8 power;        // MEMBER_POWER | LEAD_POWER | ARBITER_POWER | QUORUM_POWER
        uint16 time;        // how much Time Units to decrease by
    }

    // member => week => adjustment
    mapping (address => mapping (uint16 => Adjustment)) private _adjusts;

    uint256[10] __gap;      // reserved for upgrades

    event TimeAdjusted(
        uint8 eventType,
        address indexed member,
        uint16 indexed week,
        uint8 power,
        uint16 time
    );

    function getAdjustment(address member, uint16 forWeek) public view
    returns (uint8 power, uint16 time)
    {
        return (_adjusts[member][forWeek].power, _adjusts[member][forWeek].time);
    }

    function _setAdjustment(address member, uint16 forWeek, uint8 power, uint16 decrease, uint16[8] memory cache)
    internal
    {
        Adjustment memory adj = _adjusts[member][forWeek];
        require(power > adj.power, "not enough power to adjust");

        (uint16 pending, uint16 onWeek, bool isAged) = _extractSubmission(cache, forWeek);
        require(pending != 0 && !isAged, "nothing to adjust");
        require(pending >= decrease, "too big adjustment");

        // A member or the Lead may adjust within two weeks followed by the submission
        // The Arbiter or the Quorum - starting from the 3rd week
        uint16 age = getCurrentWeek() - onWeek;
        require(power > LEAD_POWER ? (age > 2) : (age <= 2), "week closed for adjustments");

        _adjusts[member][forWeek].power = power;
        _adjusts[member][forWeek].time = decrease;

        emit TimeAdjusted(ADJ_UPDATED, member, forWeek, power, decrease);
    }

    function _useAdjustment(address member, uint16 forWeek, uint16 time) internal
    returns (uint16 adjusted)
    {
        adjusted = time;

        uint8 power = _adjusts[member][forWeek].power;
        uint16 decrease = _adjusts[member][forWeek].time;

        if (power != 0 || decrease != 0) {
            require(decrease == 0 || adjusted >= decrease, "invalid adjustment");
            adjusted -= decrease;

            emit TimeAdjusted(ADJ_APPLIED, member, forWeek, power, decrease);
            _adjusts[member][forWeek].power = 0;
            _adjusts[member][forWeek].time = 0;
        }
    }
}
