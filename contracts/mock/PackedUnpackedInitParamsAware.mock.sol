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
    ) public pure returns (bytes memory) {
        uint32 packed = packWeights(_weights);
        return packInitParams(_collaboration, _terms, _startWeek, _managerEquity, _investorEquity, packed);
    }

    function unpack(bytes memory initParams) public pure returns (
    address _collaboration,
    bytes32 _terms,
    uint16 _startWeek,
    uint32 _managerEquity,
    uint32 _investorEquity,
    uint8[4] memory _memberWeights
    ) {
        uint32 packed;
        (
            _collaboration,
            _terms,
            _startWeek,
            _managerEquity,
            _investorEquity,
            packed
        ) = unpackInitParams(initParams);
        _memberWeights = unpackWeights(packed);
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
000000000000000000000000ac7746b60aaadd97c8cfc74a6eb1d815171d1206

00000000000000000000000000000000000009fe - 2558
00061a80 - 400000
000493e0 - 300000
04030201 - [1,2,3,4]

Object.keys(unpacked).forEach(k=>console.log(`${k}: ${unpacked[k].toString()}`))
_collaboration: 0xAC7746b60aAADD97C8cfc74a6Eb1d815171d1206
_terms: 0x7468652072657374207765207465737400000000000000000000000000000000
_startWeek: 2558
_managerEquity: 400000
_investorEquity: 300000
_memberWeights: 1,2,3,4
*/
