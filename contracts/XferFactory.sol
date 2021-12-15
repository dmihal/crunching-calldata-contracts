//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './XferToken.sol';

contract XferFactory {
    function createTokenContract(address token) external {
        new XferToken(token);
    }
}
