//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract TestToken is ERC20 {
  constructor() ERC20("Test", "TST", 18) {
    _mint(msg.sender, 10000e18);
  }
}
