pragma solidity 0.5.13;

import "./bytesUtilities.sol";

contract PackedInitParamsAware is bytesUtilities {

    /**
    * @return initParams <uint256> packed init params
    * @dev
    * param: _collaboration  |_terms          |_startWeek |_managerEquity|_investorEquity|memberWeights
    * byte#:  95..64(20bytes)| 63..32(32bytes)| 13 12     | 11 10 9 8    | 7 6 5 4       | 3  2  1  0
    */
    function packInitParams(
        address _collaboration,
        bytes32 _terms,
        uint16 _startWeek,
        uint32 _managerEquity,
        uint32 _investorEquity,
        uint8[4] memory _weights
    ) internal pure returns (uint256 initParams) {
        initParams = (uint256(_collaboration)<<96) | uint256(_startWeek);
        uint256 justToSatisfyCompiler = uint256(_terms);
        justToSatisfyCompiler = uint256(_managerEquity);
        justToSatisfyCompiler = uint256(_investorEquity);
        justToSatisfyCompiler = uint256(_weights[0]);
//        uint256 rest = (uint256(_weights[3]) << 24) | (uint256(_weights[2]) << 16) |  (uint256(_weights[1]) << 8) | uint256(_weights[0]);
//        rest = (uint256(_startWeek) << 96) | (uint256(_managerEquity) << 64) | (uint256(_investorEquity) << 32) | rest;
//
//        initParams = _packThreeUint256ToBytes(
//            rest,
//            uint256(_terms),
//            uint256(_collaboration)
//        );
    }
}
