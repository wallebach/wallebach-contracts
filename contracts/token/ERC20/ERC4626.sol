// SPDX-License-Identifier: MIT
// Wallebach Contracts (contracts/token/ERC20/ERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20, IERC4626} from "../../interfaces/IERC4626.sol";
import {ERC20} from "./ERC20.sol";
import {FixedPointMathLib} from "../../utils/FixedPointMathLib.sol";

contract ERC4626 is IERC4626, ERC20 {
    using FixedPointMathLib for uint256;

    IERC20 private immutable _asset;

    constructor(
        string memory name,
        string memory symbol,
        ERC20 assetToken
    ) ERC20(name, symbol) {
        _asset = assetToken;
    }

    function asset() public view returns (address) {
        return address(_asset);
    }

    function totalAssets() public view returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public returns (uint256 shares) {
        require((shares = previewDeposit(assets)) != 0, "ZERO SHARES");

        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public returns (uint256 assets) {
        assets = previewMint(shares);

        _asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public returns (uint256 shares) {
        shares = previewWithdraw(assets);

        if (msg.sender != owner) {
            uint256 allowed = _allowances[owner][msg.sender];

            if (allowed != type(uint256).max)
                _allowances[owner][msg.sender] = allowed - shares;
        }

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        transfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = _allowances[owner][msg.sender];

            if (allowed != type(uint256).max)
                _allowances[owner][msg.sender] = allowed - shares;
        }

        require((assets = previewRedeem(shares)) != 0, "ZERO ASSETS");

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        _asset.transfer(receiver, assets);
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply();

        return
            supply == 0
                ? shares
                : shares.mulDivDown(totalAssets(), totalSupply());
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function maxDeposit(address receiver) public pure returns (uint256) {
        // change visibility to 'view' if needed ↑
        receiver; // remove used function parameter warning
        return type(uint256).max;
    }

    function maxMint(address receiver) public pure returns (uint256) {
        // change visibility to 'view' if needed ↑
        receiver; // remove used function parameter warning
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf(owner);
    }
}
