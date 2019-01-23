pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Mortal.sol";
import "./Proxyable.sol";
import "./MarketPlaceState.sol";

contract MarketPlace is Ownable, Pausable, Mortal, Proxyable {

    using SafeMath for uint256;

    MarketPlaceState public marketPlaceState;

    mapping (address => bool) public storeOwners;
    bytes32[] private storefronts;
    mapping (address => bytes32[]) public storefrontsByOwner;
    mapping (bytes32 => Storefront) public storefrontsById;
    mapping(bytes32 => bytes32[]) public inventoryByStorefrontId;
    mapping(bytes32 => Item) public itemById;
    struct Storefront {
        bytes32 id;
        string name;
        address owner;
        uint balance;
    }

    struct Item {
        bytes32 id;
        string name;
        uint price;
        uint quantity;
    }

    event AdminAdded(address admin);
    event AdminRemoved(address admin);
    event StoreOwnerAdded(address storeOwner);
    event StoreOwnerRemoved(address storeOwner);
    event StoreCreated(bytes32 id, string name, address owner);
    event StoreRemoved(bytes32 id);
    event BalanceWithdrawn(bytes32 id, uint balance);
    event ItemAdded(bytes32 id, string name, uint price, uint qty);
    event ItemRemoved(bytes32 id);
    event ItemPriceUpdated(bytes32 id, uint newPrice, uint oldPrice);
    event ItemQuantityUpdated(bytes32 id, uint newQty, uint oldQty);
    event ItemSold(bytes32 storeId, bytes32 itemId, uint qty);

    modifier onlyAdmin() {require(marketPlaceState.administrators(msg.sender) == true, "Sender not authorized."); _;}
    modifier onlyStoreOwner() {require(storeOwners[msg.sender] == true, "Sender not authorized."); _;}
    modifier onlyStorefrontOwner(bytes32 id) {require(storefrontsById[id].owner == msg.sender, "Sender not authorized."); _;}

    constructor(address payable _proxy, MarketPlaceState _marketPlaceState)
    Proxyable(_proxy)
    public {
        marketPlaceState = _marketPlaceState;
    }

    function addAdmin(address _addr)
    public
    onlyAdmin()
    returns(bool) {
        if (marketPlaceState.addAdministrator(_addr) == _addr) {
            emit AdminAdded(_addr);
        }
        return true;
    }

    function isAdmin(address _addr)
    public
    view
    returns(bool) {
        return marketPlaceState.isAdministrator(_addr);
    }

    function removeAdmin(address _addr)
    public
    onlyAdmin()
    returns(bool) {
        marketPlaceState.removeAdministrator(_addr);
        emit AdminRemoved(_addr);
        return true;
    }

    function addStoreOwner(address addr)
    public
    onlyAdmin()
    returns(bool) {
        storeOwners[addr] = true;
        emit StoreOwnerAdded(addr);
        return true;
    }

    function removeStoreOwner(address addr)
    public
    onlyAdmin()
    returns(bool) {
        storeOwners[addr] = false;
        emit StoreOwnerRemoved(addr);
        return true;
    }

    function createStore(string memory name)
    public
    onlyStoreOwner()
    returns(bytes32) {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, name, now));
        Storefront memory s = Storefront(id, name, msg.sender, 0);
        storefronts.push(id);
        storefrontsByOwner[msg.sender].push(id);
        storefrontsById[id] = s;
        emit StoreCreated(id, name, msg.sender);
        return id;
    }

    function removeStore(bytes32 storeId)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {

        // Delete all the items from the store inventory
        for (uint i = 0; i < inventoryByStorefrontId[storeId].length; i++) {
            bytes32 itemId = inventoryByStorefrontId[storeId][i];
            delete itemById[itemId];
        }

        // Delete the store inventory
        delete inventoryByStorefrontId[storeId];

        // Remove from storefrontsByOwner mapping
        uint storefrontCount = storefrontsByOwner[msg.sender].length;
        for(uint i = 0; i < storefrontCount; i++) {
            if (storefrontsByOwner[msg.sender][i] == storeId) {
                storefrontsByOwner[msg.sender][i] = storefrontsByOwner[msg.sender][storefrontCount-1];
                delete storefrontsByOwner[msg.sender][storefrontCount-1];
                break;
            }
        }

        // Remove from storefronts array
        storefrontCount = storefronts.length;
        for(uint i = 0; i < storefrontCount; i++) {
            if (storefronts[i] == storeId) {
                delete storefronts[i];
                break;
            }
        }

        // Withdraw Balance
        uint storefrontBalance = storefrontsById[storeId].balance;
        if (storefrontBalance > 0) {
            msg.sender.transfer(storefrontBalance);
            storefrontsById[storeId].balance = 0;
            emit BalanceWithdrawn(storeId, storefrontBalance);
        }

        // Remove from storefrontsById
        delete storefrontsById[storeId];
        emit StoreRemoved(storeId);
        return storeId;
    }

    function addItemToInventory(bytes32 storeId, string memory itemName, uint itemPrice, uint itemQuantity)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        bytes32 itemId = keccak256(abi.encodePacked(msg.sender, itemName, now));
        Item memory i = Item(itemId, itemName, itemPrice, itemQuantity);
        itemById[itemId] = i;
        inventoryByStorefrontId[storeId].push(itemId);
        emit ItemAdded(itemId, itemName, itemPrice, itemQuantity);
        return itemId;
    }

    function removeItemFromInventory(bytes32 itemId, bytes32 storeId)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        // Remove the item from inventory mapping
        uint itemCount = inventoryByStorefrontId[storeId].length;
        for(uint i = 0; i < itemCount; i++) {
            if (inventoryByStorefrontId[storeId][i] == storeId) {
                inventoryByStorefrontId[storeId][i] = inventoryByStorefrontId[storeId][itemCount-1];
                delete inventoryByStorefrontId[storeId][itemCount-1];
                break;
            }
        }
        //Remove item from items mapping
        delete itemById[itemId];
        emit ItemRemoved(itemId);
        return itemId;
    }

    function updateItemPrice(bytes32 itemId, bytes32 storeId, uint newPrice)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        uint oldPrice = itemById[itemId].price;
        itemById[itemId].price = newPrice;
        emit ItemPriceUpdated(itemId, newPrice, oldPrice);
        return itemId;
    }

    function updateItemQuantity(bytes32 itemId, bytes32 storeId, uint newQty)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        uint oldQty = itemById[itemId].quantity;
        itemById[itemId].quantity = newQty;
        emit ItemQuantityUpdated(itemId, newQty, oldQty);
        return itemId;
    }

    function widthdrawStorefrontBalance(bytes32 storeId)
    public
    onlyStorefrontOwner(storeId)
    returns(bool) {
        uint storefrontBalance = storefrontsById[storeId].balance;
        if (storefrontBalance > 0) {
            msg.sender.transfer(storefrontBalance);
            storefrontsById[storeId].balance = 0;
            emit BalanceWithdrawn(storeId, storefrontBalance);
        }
    }

    function getStorefrontCountByOwner(address owner)
	public
	view
    returns (uint) {
        return storefrontsByOwner[owner].length;
    }

    function purchaseItem(bytes32 storeId, bytes32 itemId, uint quantity)
    public
    payable
    returns(bool) {
        Item memory item = itemById[itemId];
        uint totalPrice = item.price.mul(quantity);
        require(msg.value >= totalPrice, "msg.value must be greater or equal than total price");
        require(item.quantity >= quantity, "Item quantity is not enough");

        if (msg.value > totalPrice) {
            msg.sender.transfer(msg.value - totalPrice);
        }

        item.quantity -= quantity;
        storefrontsById[storeId].balance += totalPrice;
        emit ItemSold(storeId, itemId, quantity);
        return true;
    }


}
