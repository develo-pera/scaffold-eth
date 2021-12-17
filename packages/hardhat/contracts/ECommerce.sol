// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ECommerce is ERC1155PresetMinterPauser {
  string private baseUrl;
  mapping (address => bool) private minters;

  /// @dev We need base url without "/{id}.json" so we can construct URL for each token separatly in overriden uri method below
  /// @param _baseUrl Base URL from which we construct the whole URL
  constructor(string memory _baseUrl) ERC1155PresetMinterPauser(string(abi.encodePacked(_baseUrl, "/{id}.json"))) {
    baseUrl = _baseUrl;
  }

  /// @notice OpenSea friendly url. Instead of relaying on client to do parse ans substitue it, we return url with correct id
  /// @param _tokenId Token ID to retrieve URL for
  function uri(uint _tokenId) override public view returns(string memory) {
    return string(
      abi.encodePacked(
        baseUrl,
        "/",
        Strings.toString(_tokenId),
        ".json"
      )
    );
  }
}
