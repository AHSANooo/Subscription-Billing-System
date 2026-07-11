// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDT
 * @dev A standard ERC20 token with 6 decimals to mimic live USDT deployments.
 */
contract MockUSDT is ERC20, Ownable {
    
    constructor(uint256 initialSupply) ERC20("Mock USDT", "USDT") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    // Explicitly override decimals to match USDT production rules
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev Faucet function allowing anyone to mint mock tokens for local/testnet simulation.
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}