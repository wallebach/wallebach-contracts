// SPDX-License-Identifier: MIT
// Wallebach Contracts (token/ERC20/extensions/ERC20FlashMint.sol)

pragma solidity ^0.8.20;

import {IERC3156FlashBorrower} from "../../../interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "../../../interfaces/IERC3156FlashLender.sol";
import {ERC20} from "../ERC20.sol";

contract ERC20FlashMint is ERC20, IERC3156FlashLender {
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 fee;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 fee_
    ) ERC20(name_, symbol_) {
        fee = fee_;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        require(amount <= maxFlashLoan(token), "MAX LOAN EXCEEDED");

        uint256 _fee = _flashFee(amount);
        _mint(address(receiver), amount);

        require(
            receiver.onFlashLoan(msg.sender, token, amount, _fee, data) ==
                CALLBACK_SUCCESS,
            "CALLBACK FAILED"
        );

        uint256 _allowance = allowance(address(receiver), address(this));
        require(_allowance >= (amount + _fee), "REPAY NOT APPROVED");

        _spendAllowance(address(receiver), address(this), amount + _fee);
        _burn(address(receiver), amount + _fee);

        return true;
    }

    function maxFlashLoan(address token) public view returns (uint256) {
        return token == address(this) ? type(uint256).max - totalSupply() : 0;
    }

    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256) {
        require(token == address(this), "TOKEN NOT SUPPORTED");
        return _flashFee(amount);
    }

    function _flashFee(uint256 amount) private view returns (uint256) {
        return (amount * fee) / 10000;
    }
}
