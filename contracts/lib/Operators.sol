pragma solidity 0.5.13;

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";

/**
 * @notice Inspired by and borrowed (with minor alterations) from:
 *   "openzeppelin/contracts-ethereum-package/contracts/token/ERC777/ERC777.sol"
 */
contract Operators is Context {

    address private _defaultOperator;

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // reserved for upgrades
    uint256[10] __gap;

    event AuthorizedOperator(address indexed operator, address indexed account);
    event RevokedOperator(address indexed operator, address indexed account);

    function _initialize(address defaultOperator) internal {
        require(defaultOperator != address(0), "Zero default operator address");
        _defaultOperator = defaultOperator;
    }

    function isOperatorFor(
        address operator,
        address account
    ) public view returns (bool) {
        return operator == account ||
        ((operator == _defaultOperator) && !_revokedDefaultOperators[account][operator]) ||
        _operators[account][operator];
    }

    function defaultOperator() public view returns (address) {
        return _defaultOperator;
    }

    function authorizeOperator(address operator) external {
        require(_msgSender() != operator, "authorizing self as operator");

        if (_defaultOperator == operator) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    function revokeOperator(address operator) external {
        require(operator != _msgSender(), "revoking self as operator");

        if (_defaultOperator == operator) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

}
