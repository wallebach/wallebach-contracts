// SPDX-License-Identifier: MIT
// Wallebach Contracts (contracts/proxy/ERC1967Proxy.sol)

pragma solidity 0.8.20;

import "./utils/ERC1967Upgrade.sol";
import "./utils/Proxy.sol";

contract ERC1967Proxy is ERC1967Upgrade, Proxy {
    constructor(address _logic, bytes memory _data) payable {
        assert(
            _IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        _upgradeToAndCall(_logic, _data, false);
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address implementation)
    {
        return ERC1967Upgrade._getImplementation();
    }
}
