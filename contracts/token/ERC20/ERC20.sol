// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "../../interfaces/IERC20.sol";

contract ERC20 is IERC20 {
    string private _name;
    string private _symbol;

    uint256 internal _totalSupply;
    mapping(address owner => uint256) internal _balances;
    mapping(address owner => mapping(address spender => uint256))
        internal _allowances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        _spendAllowance(from, to, value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address from, address to, uint256 value) private {
        require(from != address(0), "Can't transfer from zero address");
        require(to != address(0), "Can't transfer to zero address");

        _update(from, to, value);

        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0), "Can't transfer from zero address");
        require(spender != address(0), "Can't transfer to zero address");

        _allowances[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= value);
        if (currentAllowance != type(uint256).max) {
            _approve(owner, spender, currentAllowance - value);
        }
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual returns (bool) {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            require(_balances[from] >= value, "Not enough balance");

            unchecked {
                _balances[from] -= value;
            }
        }

        if (to == address(0)) {
            _totalSupply -= value;
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _update(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0));
        _update(account, address(0), amount);
    }
}
