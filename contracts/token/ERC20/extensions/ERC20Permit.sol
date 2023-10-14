// SPDX-License-Identifier: MIT
// Wallebach Contracts (token/ERC20/extensions/ERC20Permit)
pragma solidity ^0.8.20; 

import {ERC20} from "../ERC20.sol";

// Implementation of ERC-2612: Permit Extension for EIP-20 Signed Approvals
contract ERC20Permit is ERC20 {

    mapping(address owner => uint256) private _nonces;

    uint256 private _chainId;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _chainId = block.chainid;
    }

    function chainId() public view returns (uint256) {
        return _chainId;
    }

    function nonces(address owner) public view returns (uint256) {
        return _nonces[owner];
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(deadline >= block.timestamp, "Permit deadline expired");

        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                           abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                _nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ), 
                v, 
                r, 
                s
            );
            require(recoveredAddress != address(0) && recoveredAddress == owner, "Invalid address");

            _allowances[owner][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256("1"),
                chainId(),
                address(this)
            )
        );
    }
}
