pragma solidity 0.5.7;


contract Prototype
{

    struct WeekEntry
    {
        bytes32 week;
        uint[7] _hours;
        uint equity;
    }

    mapping(address => uint) private members;
    mapping(address => WeekEntry[]) private submittedHours;

    function join(uint _memberId) external returns(bool _added) {
        address memberAddress = msg.sender;
        if (_memberId < 1)
        {
            _added = false;
            return _added;
        }

        if (members[memberAddress] > 0)
        {
            _added = false;
            return _added;
        }

        members[memberAddress] = _memberId;
        _added = true;
        return _added;
    }

    function submitHours(
        bytes32 _week,
        uint _equity,
        uint[7] calldata _weekHours
    )
        external
        returns(bool _saved)
    {
        uint i = 0;
        bool submitted = false;
        uint index = 0;
        WeekEntry[] memory memberSubmittedHours;

        address memberAddress = msg.sender;

        // check if member has an account at submittedHours
        if (submittedHours[memberAddress].length < 1)
        {
            _saved = false;
            return _saved;
        }

        // check if member has already submitted hours
        memberSubmittedHours = submittedHours[memberAddress];
        for (i = 0; i < memberSubmittedHours.length; i++)
        {
            if (memberSubmittedHours[i].week == _week)
            {
                submitted = true;
            }
        }

        if (submitted)
        {
            _saved = false;
            return _saved;
        }

        submittedHours[memberAddress].length += 1;
        index = submittedHours[memberAddress].length;

        submittedHours[memberAddress][index].week = _week;
        submittedHours[memberAddress][index]._hours = _weekHours;
        submittedHours[memberAddress][index].equity = _equity;

        _saved = true;

        return _saved;
    }

    function getHours(
        address _memberAddress,
        bytes32 _week
    )
        external
        view
        returns(uint _sumHours)
    {
        address memberAddress;
        uint i = 0;
        uint j = 0;
        uint sumHours = 0;
        WeekEntry[] memory memberSubmittedHours;

        if (members[_memberAddress] > 0)
        {
            memberAddress = _memberAddress;
        }
        else
        {
            _sumHours = 0;
            return _sumHours;
        }

        memberSubmittedHours = submittedHours[memberAddress];
        for (i = 0; i < memberSubmittedHours.length; i++)
        {
            if (memberSubmittedHours[i].week == _week)
            {
                for (j = 0; j < memberSubmittedHours[i]._hours.length; j++)
                {
                    sumHours += memberSubmittedHours[i]._hours[j];
                }
            }
        }

        if (sumHours > 55)
        {
            sumHours = 55;
        }

        _sumHours = sumHours;

        return _sumHours;
    }

    function getEquity(
        address _memberAddress,
        uint _memberId
    )
        external
        view
        returns(uint _equity)
    {
        address memberAddress;
        uint i = 0;
        // TODO: remove equity test environment value for production
        uint equity = 80;
        WeekEntry[] memory memberSubmittedHours;

        if (members[_memberAddress] > 0)
        {
            memberAddress = _memberAddress;
        }
        else
        {
            _equity = 0;
            return _equity;
        }

        memberSubmittedHours = submittedHours[memberAddress];
        for (i = 0; i < memberSubmittedHours.length; i++)
        {
            if (memberSubmittedHours[i].equity < equity)
            {
                equity = memberSubmittedHours[i].equity;
            }
        }

        _equity = equity;

        return _equity;
    }
}
