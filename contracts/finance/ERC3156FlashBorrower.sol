// SPDX-License-Identifier: MIT
// Wallebach Contracts (finance/ERC3156FlashBorrower.sol)

pragma solidity ^0.8.20;

import {IERC3156FlashBorrower} from "../interfaces/IERC3156FlashBorrower.sol";
import {IERC3156FlashLender} from "../interfaces/IERC3156FlashLender.sol";
import {IERC20} from "../interfaces/IERC20.sol";

abstract contract ERC3156FlashBorrower is IERC3156FlashBorrower {
    IERC3156FlashLender lender;

    constructor(IERC3156FlashLender lender_) {
        lender = lender_;
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external view returns (bytes32) {
        require(msg.sender == address(lender), "UNTRUSTED LENDER");
        require(initiator == address(this), "UNKNOWN INITIATOR");

        // Suppress unused variable warning
        token;
        amount;
        fee;
        data;

        // ================================
        // IMPLEMENT CALLBACK ACTION HERE
        // ================================

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function flashBorrow(address token, uint256 amount) public {
        // CHANGE WITH ACTUAL DATA HERE
        bytes memory data = abi.encode("");

        uint256 fee = lender.flashFee(token, amount);
        uint256 currentAllowance = IERC20(token).allowance(
            address(this),
            address(lender)
        );

        uint256 repayment = amount + fee;
        IERC20(token).approve(address(lender), currentAllowance + repayment);

        lender.flashLoan(this, token, amount, data);
    }
}
