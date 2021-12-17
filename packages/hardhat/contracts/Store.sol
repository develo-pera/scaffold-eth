// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ECommerce.sol";

contract Store is Ownable, ERC1155Holder {
  using Counters for Counters.Counter;

  ECommerce private ECommerceContract;
  /// @dev Item ids start from 1, not 0.
  /// See mintNewItem for more.
  Counters.Counter internal itemIdTracker;

  mapping(uint => uint) public itemPrice;
  mapping(address => bool) private storeManagers;

  struct ShippingAddress {
    string street;
    string city;
    string zipCode;
    string country;
  }

  struct OrderDetails {
    string sku;
    ShippingAddress shippingAddress;
  }

  event AddNewItem(uint itemId);
  event BuyItems(uint indexed itemId, address indexed buyer, uint itemsAmount);
  event RedeemItem(uint indexed itemId, address indexed redeemer, OrderDetails orderDetails);
  event AddNewManager(address indexed managerAddress);
  event RemoveManager(address indexed managerAddress);

  modifier onlyStoreManager(address _sender) {
    require(storeManagers[_sender], "Not allowed!");
    _;
  }

  modifier validItemId(uint _tokenId) {
    require(_tokenId > 0 && _tokenId <= itemIdTracker.current(), "Invalid product id");
    _;
  }

  constructor(address _ECommerceAddress) {
    ECommerceContract = ECommerce(_ECommerceAddress);
  }

  /// @notice This function shouldn't exists. It's created solely for demo purposes so
  /// anyone can make themselves store managers and try adding new itens to the store
  /// through client admin dashboard.
  function makeMeStoreManager() public {
    storeManagers[msg.sender] = true;

    emit AddNewManager(msg.sender);
  }

  /// @notice Creates new product.
  /// @dev Item ids will start from 1, not 0.
  /// @param _itemPrice Product price in wei.
  /// @param _amount Number of copies available for sale.
  function mintNewItem(uint _itemPrice, uint _amount) public onlyStoreManager(msg.sender) {
    require(_itemPrice > 0, "Invalid item price");
    require(_amount > 0, "Invalid amount");

    itemIdTracker.increment();
    uint itemId = itemIdTracker.current();

    itemPrice[itemId] = _itemPrice;
    ECommerceContract.mint(address(this), itemId, _amount, "");

    emit AddNewItem(itemId);
  }

  /// @notice Charges and transfer product to msg.sender.
  /// @dev We check for _amount and msg.value before checking for availability
  /// so we can revert early if there's a problem in order to save the gas for
  /// the buyer.
  /// @param _tokenId ID of the product msg.sender wants to buy.
  /// @param _amount Number of product copies to buy.
  function buyItems(uint _tokenId, uint _amount) public payable validItemId(_tokenId) {
    require(_amount > 0, "Invalid amount");
    require(msg.value >= itemPrice[_tokenId] * _amount, "Not enough funds");

    uint availableItems = ECommerceContract.balanceOf(address(this), _tokenId);
    require(availableItems >= _amount, "Out of stock");

    ECommerceContract.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");

    emit BuyItems(_tokenId, msg.sender, _amount);
  }

  /// @notice Burns the token and emits event with shipping details for the item.
  /// For now we only accept redeeming a single copy of the single item. In the future
  /// we should enable redeeming multiple copies of multiple products in one transaction.
  /// @dev before calling this msg.senders should allow Store contract to manage their
  /// tokens by calling approveForAll on ECommerce contract.
  /// @param _tokenId Product ID to redeem.
  /// @param _orderDetails Product SKU and shipping address.
  function redeemItem(uint _tokenId, OrderDetails memory _orderDetails) public validItemId(_tokenId) {
    ECommerceContract.burn(msg.sender, _tokenId, 1);

    emit RedeemItem(_tokenId, msg.sender, _orderDetails);
  }

  /// @notice Adds new store manager.
  /// @param _newManagerAddress New manager's address.
  function addStoreManager(address _newManagerAddress) public onlyOwner {
    require(!storeManagers[_newManagerAddress], "Already added!");

    storeManagers[_newManagerAddress] = true;

    emit AddNewManager(_newManagerAddress);
  }

  /// @notice Removes store manager.
  /// @param _managerAddress New manager's address.
  function removeStoreManager(address _managerAddress) public onlyOwner {
    require(storeManagers[_managerAddress], "Not a manager!");

    storeManagers[_managerAddress] = false;

    emit RemoveManager(_managerAddress);
  }

  /// @notice Checks if given address is store manager.
  /// @param _checkAddress Address to check.
  /// @return boolean
  function isStoreManager(address _checkAddress) public view returns(bool) {
    return storeManagers[_checkAddress];
  }

  /// @notice Returns id for the next item that is yet to be created
  /// @dev We need this to construct correct metadata and url for frontend on client
  /// @return uint
  function getNewItemId() public view returns(uint) {
    return itemIdTracker.current() + 1;
  }

  /// @notice Withdraws whole available contract balance to owner's account
  /// @dev Because only owner can call this method and that is EOA,
  /// not another contract and the fact that we are transferring the whole
  /// contract balance means we are safe from reentrancy attack. That
  /// being said we can just use plain transfer function here.
  function withdraw() public onlyOwner {
    payable(address(msg.sender)).transfer(address(this).balance);
  }
}
