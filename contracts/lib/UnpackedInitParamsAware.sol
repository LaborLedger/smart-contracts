pragma solidity 0.5.13;

import "./bytesUtilities.sol";

contract UnpackedInitParamsAware is bytesUtilities {
    /**
     * @param initParams <bytes> packed params
     * @return unpacked params
     * @dev
     * param: _collaboration      |_projectLead    |_startWeek |_managerEquity|_investorEquity|memberWeights
     * byte#:  95..64(20of32bytes)| 63..32(20bytes)| 13 12     | 11 10 9 8    | 7 6 5 4       | 3  2  1  0
     */
    function unpackInitParams(bytes memory initParams) internal pure returns (
        address _collaboration,
        address _projectLead,
        uint16 _startWeek,
        uint32 _managerEquity,
        uint32 _investorEquity,
        uint32 _weights
    ) {
        _collaboration = address(_unpackUint256FromBytes(initParams, 2));
        _projectLead = address(_unpackUint256FromBytes(initParams, 1));
        uint256  rest = _unpackUint256FromBytes(initParams, 0);

        _startWeek = uint16((rest >> 96) & 0xFFFF);
        _managerEquity = uint32((rest >> 64) & 0xFFFFFFFF);
        _investorEquity = uint32((rest >> 32) & 0xFFFFFFFF);

        _weights = uint32(rest & 0xFFFFFFFF);
    }

    function unpackWeights(uint32 weightsPacked) internal pure
        returns(uint8[4] memory weights)
    {
        weights[3] = uint8((weightsPacked >> 24) & 0xFF);
        weights[2] = uint8((weightsPacked >> 16) & 0xFF);
        weights[1] = uint8((weightsPacked >> 8) & 0xFF);
        weights[0] = uint8(weightsPacked & 0xFF);
    }
}
