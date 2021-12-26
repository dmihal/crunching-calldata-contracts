//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IERC20.sol";
import './XferToken.sol';

contract XferFactory {
    IAddressRegistry public immutable addressRegistry;

    event NewToken(address token, address xfer);

    error TooShort();
    error TooLong();
    error AddressNotFound();

    constructor(address _registry) {
        addressRegistry = IAddressRegistry(_registry);
    }

    function createTokenContract(address token) public {
        address xfer = address(new XferToken{ salt: bytes32(0) }(token, address(addressRegistry)));
        emit NewToken(token, xfer);
    }

    function calculateTokenContract(address token) public view returns (address predictedAddress) {
        predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            bytes32(0),
            keccak256(abi.encodePacked(
                type(XferToken).creationCode,
                abi.encode(token)
            ))
        )))));
    }

    function baselineTransferFrom(address token, address to, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, to, amount);
    }

    fallback() external {
        if (msg.data.length < 5) {
            revert TooShort();
        }
        if (msg.data.length > 72) {
            revert TooLong();
        }

        address token;
        address to;
        uint256 offset;
        if (msg.data.length < 41) {
            uint256 tokenId = uint16(bytes2(msg.data[:2]));
            uint256 toId = uint16(bytes2(msg.data[2:4]));
            token = addressRegistry.getAddress(tokenId);
            to = addressRegistry.getAddress(toId);
            offset = 4;
        } else {
            token = address(bytes20(msg.data[:20]));
            to = address(bytes20(msg.data[20:40]));
            offset = 40;
        }

        uint256 amountToShift = (offset + 32 - msg.data.length) * 8;
        uint256 value = uint256(bytes32(msg.data[offset:]) >> amountToShift);

        IERC20(token).transferFrom(msg.sender, to, value);
    }
}
