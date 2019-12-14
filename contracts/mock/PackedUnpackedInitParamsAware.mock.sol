pragma solidity 0.5.13;

import "../lib/PackedInitParamsAware.sol";
import "../lib/UnpackedInitParamsAware.sol";

contract MockPackUnpack is PackedInitParamsAware, UnpackedInitParamsAware {

    function pack(
        address _collaboration,
        bytes32 _terms,
        uint16 _startWeek,
        uint32 _managerEquity,
        uint32 _investorEquity,
        uint8[4] memory _weights
    ) public pure returns (uint256) {
        return packInitParams(_collaboration, _terms, _startWeek, _managerEquity, _investorEquity, _weights);
    }

    function unpack(uint256 initParams) public pure returns (
    address _collaboration,
    bytes32 _terms,
    uint16 _startWeek,
    uint32 _managerEquity,
    uint32 _investorEquity,
    uint8[4] memory _memberWeights
    ) {
        return unpackInitParams(initParams);
    }
}

/*
truffle(develop)>
let inst = await MockPackUnpack.new()
let packed = await inst.pack('0xac7746b60aaadd97c8cfc74a6eb1d815171d1206', web3.utils.fromAscii('the rest we test'), 2558, 400000, 300000, [1,2,3,4])
let unpacked = await inst.unpack(packed)

truffle(develop)> packed
0x
00000000000000000000000000000000000009fe00061a80000493e004030201
7468652072657374207765207465737400000000000000000000000000000000
000000000000000000000000ac7746b60aaadd97c8cfc74a6eb1d815171d1206'

00000000000000000000000000000000000009fe - 2558
00061a80 - 400000
000493e0 - 300000
04030201 - [1,2,3,4]
*/
