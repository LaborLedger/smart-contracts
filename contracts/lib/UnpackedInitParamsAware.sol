pragma solidity 0.5.13;

import "./bytesUtilities.sol";

contract UnpackedInitParamsAware is bytesUtilities {
    /**
     * @param initParams <bytes> packed params
     * @return unpacked params
     * @dev
     * param: _collaboration  |_terms          |_startWeek |_managerEquity|_investorEquity|memberWeights
     * byte#:  95..64(20bytes)| 63..32(32bytes)| 13 12     | 11 10 9 8    | 7 6 5 4       | 3  2  1  0
     */
    function unpackInitParams(bytes memory initParams) internal pure returns (
        address _collaboration,
        bytes32 _terms,
        uint16 _startWeek,
        uint32 _managerEquity,
        uint32 _investorEquity,
        uint8[4] memory _weights
    ) {
        _collaboration = address(_unpackUint256FromBytes(initParams, 2));
        _terms = bytes32(_unpackUint256FromBytes(initParams, 1));
        uint256  rest = _unpackUint256FromBytes(initParams, 0);

        _startWeek = uint16((rest >> 96) & 0xFFFF);
        _managerEquity = uint32((rest >> 64) & 0xFFFFFFFF);
        _investorEquity = uint32((rest >> 32) & 0xFFFFFFFF);

        _weights = [0, 0, 0, 0];
        if (rest & 0xFFFFFFFF != 0) {
            _weights[3] = uint8((rest >> 24) & 0xFF);
            _weights[2] = uint8((rest >> 16) & 0xFF);
            _weights[1] = uint8((rest >> 8) & 0xFF);
            _weights[0] = uint8(rest & 0xFF);
        }
    }
}
