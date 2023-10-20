// SPDX-License-Identifier: MIT
// Wallebach Contracts (contracts/proxy/utils/ERC1967Upgrade.sol)
pragma solidity 0.8.20;

import "./StorageSlot.sol";

abstract contract ERC1967Upgrade {
    // keccak-256("eip1967.proxy.implementation") - 1
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) private {
        require(
            _isContract(newImplementation),
            "Implementation can't be zero address"
        );

        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            (bool success, ) = newImplementation.delegatecall(data);
            require(success, "Delegate call failed");
        }
    }

    // keccak-256("eip1967.proxy.admin") - 1
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event AdminChanged(address previousAdmin, address newAdmin);

    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "Admin can't be zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    function _changeAdmin(address newAdmin) internal {
        _setAdmin(newAdmin);
        emit AdminChanged(_getAdmin(), newAdmin);
    }

    function _isContract(address target) internal view returns (bool) {
        return target.code.length > 0;
    }
}
