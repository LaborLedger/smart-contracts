pragma solidity 0.5.13;

import "./bytesUtilities.sol";

contract PackedInitParamsAware is bytesUtilities {

    /**
    * @return initParams <bytes32> packed init params
    * @dev
    * param: _collaboration        |_projectLead    |_startWeek |_managerEquity|_investorEquity|memberWeights
    * byte#:  95..64(20from32bytes)| 63..32(20bytes)| 13 12     | 11 10 9 8    | 7 6 5 4       | 3  2  1  0
    */
    function packInitParams(
        address _collaboration,
        address _projectLead,
        uint16 _startWeek,
        uint32 _managerEquity,
        uint32 _investorEquity,
        uint32 _packedWeights
    ) internal pure returns (bytes memory initParams) {
        uint256 b = (uint256(_startWeek)<<96) | (uint256(_managerEquity)<<64);
        b = b | (uint256(_investorEquity)<<32) | uint256(_packedWeights);

        initParams = _packThreeUint256ToBytes(
            b,
            uint256(_projectLead),
            uint256(_collaboration)
        );
    }

    function packWeights(uint8[4] memory _weights) internal pure
        returns(uint32 packed)
    {
        packed = uint32(_weights[3])<<24 | uint32(_weights[2])<<16 | uint32(_weights[1])<<8 | uint32(_weights[0]);
    }
}
