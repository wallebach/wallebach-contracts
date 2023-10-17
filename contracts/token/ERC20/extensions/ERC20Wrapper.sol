// SPDX-License-Identifier: MIT
// Wallebach Contracts (last updated v5.0.0) (/token/ERC20/extensions/ERC20Wrapper.sol)

pragma solidity ^0.8.20;

import {IERC20, ERC20} from "../ERC20.sol";

contract ERC20Wrapper is ERC20 {
    IERC20 _underlying;

    constructor(
        string memory name,
        string memory symbol,
        IERC20 underlyingToken
    ) ERC20(name, symbol) {
        _underlying = underlyingToken;
    }

    function underlying() public view returns (IERC20) {
        return _underlying;
    }

    function depositFor(address account, uint256 value) public returns (bool) {
        require(
            account != address(this),
            "Can't transfer from this wrapper contract"
        );
        require(
            msg.sender != address(this),
            "Can't send from this wrapper contract"
        );
        _underlying.transferFrom(account, address(this), value);

        return true;
    }

    function withdrawTo(address account, uint256 value) public returns (bool) {
        require(
            account != address(this),
            "Can't withdraw to this wrapper contract"
        );
        _burn(msg.sender, value);

        _underlying.transfer(account, value);

        return true;
    }
}
