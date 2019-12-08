pragma solidity 0.5.13;

contract bytesUtilities {

    function _unpackUint256FromBytes(bytes memory data, uint256 index)
    internal pure returns (uint256 i)
    {
        require(data.length / 32 > index, "Reading bytes out of bounds");
        assembly {
        // skip 1st word (32 bytes) for data.length then words with lower indexes
            i := mload(add(data, add(32, mul(32, index))))
        }
    }

    function _packThreeUint256ToBytes(uint256 firstUint, uint256 secondUint, uint256 thirdUint)
    internal pure returns (bytes memory b)
    {
        b = new bytes(96);
        assembly {
            mstore(add(b, 32), firstUint)   // skip 32 bytes for b.length
            mstore(add(b, 64), secondUint)  // another 32 bytes for firstUint
            mstore(add(b, 96), thirdUint)   // another 32 bytes for secondUint
        }
    }
}
