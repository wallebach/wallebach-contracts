// SPDX-License-Identifier: MIT
// Wallebach Contracts (token/ERC20/extensions/ERC20Votes.sol)
pragma solidity ^0.8.20;

import {ERC20} from "../ERC20.sol";
import {IERC20Votes} from "../../../interfaces/IERC20Votes.sol";

contract ERC20Votes is ERC20, IERC20Votes {
    uint256 _initialSupply = 1000000000;

    struct Checkpoint {
        uint256 blockNum;
        uint256 votes;
    }

    mapping(address => address) private delegates;

    mapping(address => uint256) private numCheckpoints;

    mapping(address => mapping(uint256 => Checkpoint)) private checkpoints;

    mapping(address => uint) public nonces;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, _initialSupply);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override returns (bool) {
        super._update(from, to, value);

        _moveDelegates(from, to, value);

        return true;
    }

    function delegate(address delegatee) public {
        _delegate(msg.sender, delegatee);
    }

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "SIGNATURE IS INVALID");
        require(nonce == nonces[signatory]++, "INVALID NONCE");
        require(block.timestamp <= expiry, "SIGNATURE EXPIRED");

        return _delegate(signatory, delegatee);
    }

    function getCurrentVotes(address account) external view returns (uint256) {
        uint256 _accountCheckpoints = numCheckpoints[account];

        return
            _accountCheckpoints > 0
                ? checkpoints[account][_accountCheckpoints - 1].votes
                : 0;
    }

    function getPriorVotes(
        address account,
        uint blockNumber
    ) external view returns (uint256) {
        require(blockNumber < block.number, "Block doesn't exist yet");

        uint256 _accountCheckpoints = numCheckpoints[account];
        if (_accountCheckpoints == 0) {
            return 0;
        }

        if (
            checkpoints[account][_accountCheckpoints - 1].blockNum <=
            blockNumber
        ) {
            return checkpoints[account][_accountCheckpoints - 1].votes;
        }

        if (checkpoints[account][0].blockNum > blockNumber) {
            return 0;
        }

        uint256 min = 0;
        uint256 max = _accountCheckpoints - 1;

        while (max > min) {
            uint256 center = max - (max - min) / 2;
            Checkpoint memory currentCheckpoint = checkpoints[account][center];
            if (currentCheckpoint.blockNum == blockNumber) {
                return currentCheckpoint.votes;
            } else if (currentCheckpoint.blockNum < blockNumber) {
                min = center;
            } else {
                max = center - 1;
            }
        }
        return checkpoints[account][min].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = _balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address oldDelegate,
        address newDelegate,
        uint256 amount
    ) internal {
        if (oldDelegate != newDelegate && amount > 0) {
            if (oldDelegate != address(0)) {
                uint256 oldCheckpointNum = numCheckpoints[oldDelegate];
                uint256 oldVotes = oldCheckpointNum > 0
                    ? checkpoints[oldDelegate][oldCheckpointNum - 1].votes
                    : 0;
                uint256 oldVotesUpdated = oldVotes - amount;
                _writeCheckpoint(
                    oldDelegate,
                    oldCheckpointNum,
                    oldVotes,
                    oldVotesUpdated
                );
            }

            if (newDelegate != address(0)) {
                uint256 newCheckpointNum = numCheckpoints[newDelegate];
                uint256 newVotes = newCheckpointNum > 0
                    ? checkpoints[newDelegate][newCheckpointNum - 1].votes
                    : 0;
                uint256 newVotesUpdated = newVotes - amount;
                _writeCheckpoint(
                    newDelegate,
                    newCheckpointNum,
                    newVotes,
                    newVotesUpdated
                );
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint256 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].blockNum == block.number
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                block.number,
                newVotes
            );

            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}
