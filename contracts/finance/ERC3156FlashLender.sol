// SPDX-License-Identifier: MIT
// Wallebach Contracts (wallebach-contracts/contracts/finance/ERC3156FlashLender.sol)

pragma solidity ^0.8.20;

import {IERC3156FlashBorrower} from "../interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "../interfaces/IERC3156FlashLender.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract ERC3156FlashLender is IERC3156FlashLender {
    bytes32 public constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 fee;

    mapping(address => bool) private supportedTokens;

    constructor(address[] memory supportedTokens_, uint256 fee_) {
        for (uint256 i = 0; i < supportedTokens_.length; i++) {
            supportedTokens[supportedTokens_[i]] = true;
        }
        fee = fee_;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        require(supportedTokens[token], "UNSUPPORTED TOKEN");

        uint256 _fee = _flashFee(amount);

        require(
            IERC20(token).transfer(address(receiver), amount),
            "TOKEN TRANSFER FAILED"
        );

        require(
            receiver.onFlashLoan(msg.sender, token, amount, _fee, data) ==
                CALLBACK_SUCCESS,
            "CALLBACK FAILED"
        );

        require(
            IERC20(token).transferFrom(
                address(receiver),
                address(this),
                amount + fee
            ),
            "REPAYMENT FAILED"
        );

        return true;
    }

    function flashFee(
        address token,
        uint256 amount
    ) external view override returns (uint256) {
        require(supportedTokens[token], "UNSUPPORTED TOKEN");
        return _flashFee(amount);
    }

    function _flashFee(uint256 amount) internal view returns (uint256) {
        return (amount * fee) / 10000;
    }

    function maxFlashLoan(
        address token
    ) external view override returns (uint256) {
        return
            supportedTokens[token] ? IERC20(token).balanceOf(address(this)) : 0;
    }
}
