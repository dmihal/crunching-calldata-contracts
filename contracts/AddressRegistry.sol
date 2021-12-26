//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './interfaces/IAddressRegistry.sol';

contract AddressRegistry is IAddressRegistry {
    uint256 public nextId = 1;

    mapping(uint256 => address) private idToAddress;
    mapping(address => uint256) private addressToId;

    event AddressRegistered(address indexed addr, uint256 id);

    function getId(address addr) external returns (uint256 id) {
        id = addressToId[addr];
        
        if (id == 0) {
            id = nextId;
            nextId += 1;

            idToAddress[id] = addr;
            addressToId[addr] = id;

            emit AddressRegistered(addr, id);
        }
    }

    function peekId(address addr) external view returns (uint256 id) {
        id = addressToId[addr];
    }

    function getAddress(uint256 id) external view returns (address addr) {
        return idToAddress[id];
    }

    function getMinBytes() external view returns (uint256) {
        uint256 _nextId = nextId;

        for (uint256 _bytes = 8; _bytes < 256; _bytes += 8) {
            uint maxValue = 1 << _bytes;
            if (maxValue >= _nextId) {
                return _bytes;
            }
        }
        return 256;
    }

    function getSafeMinBytes() external view returns (uint256) {
        uint256 _nextId = nextId + 5000;

        for (uint256 _bytes = 8; _bytes < 256; _bytes += 8) {
            uint maxValue = 1 << _bytes;
            if (maxValue >= _nextId) {
                return _bytes;
            }
        }
        return 256;
    }
}
