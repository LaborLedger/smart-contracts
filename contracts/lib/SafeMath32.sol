pragma solidity ^0.5.0;

/**
 * @dev Equivalent of openzeppelin' SafeMath for Uint32.
 * Based on openzeppelin' SafeMath.
 */

library SafeMath32 {

    /**
     * @notice The 2nd argument is the signed integer
     */
    function addSigned(uint32 a, int32 b) internal pure returns (uint32) {
        if (b == 0) {
            return uint32(a);
        } else if(b > 0) {
            return add(a, uint32(b));
        } else {
            return sub(a, uint32(-b));
        }
    }

    /**
     * @notice The 2nd argument is the signed integer
     */
    function subSigned(uint32 a, int32 b) internal pure returns (uint32) {
        if (b == 0) {
            return uint32(a);
        } else if(b > 0) {
            return sub(a, uint32(b));
        } else {
            return add(a, uint32(-b));
        }
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath32: addition overflow");

        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b <= a, "SafeMath32: subtraction overflow");
        uint32 c = a - b;

        return c;
    }

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
        require(c / a == b, "SafeMath32: multiplication overflow");

        return c;
    }
}
