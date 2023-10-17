// SPDX-License-Identifier: MIT
// Wallebach Contracts (wallebach-contracts/contracts/interfaces/IERC20Votes.sol)

pragma solidity ^0.8.20;

interface IERC20Votes {
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    event DelegateVotesChanged(
        address indexed delegate,
        uint previousBalance,
        uint newBalance
    );

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(
        address account,
        uint blockNumber
    ) external view returns (uint256);
}
