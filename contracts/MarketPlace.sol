pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Mortal.sol";
import "./Proxyable.sol";

contract MarketPlace is Ownable, Pausable, Mortal, Proxyable {

    using SafeMath for uint256;

    address[] public administrators;
    address[] public storeOwners;
    mapping (address => bool) public administratorsByAddress;
    mapping (address => bool) public storeOwnersByAddress;

    bytes32[] public storefronts;
    mapping (address => bytes32[]) public storefrontsByOwner;
    mapping (bytes32 => Storefront) public storefrontsById;
    mapping(bytes32 => bytes32[]) public inventoryByStorefrontId;
    mapping(bytes32 => Item) private itemsById;

    struct Storefront {
        bytes32 id;
        bytes32 name;
        address owner;
        uint balance;
    }

    struct Item {
        bytes32 id;
        bytes32 name;
        uint price;
        uint quantity;
    }

    event AdminAdded(address admin);
    event AdminRemoved(address admin);
    event StoreOwnerAdded(address storeOwner);
    event StoreOwnerRemoved(address storeOwner);
    event StoreCreated(bytes32 id, bytes32 name, address owner);
    event StoreRemoved(bytes32 id);
    event BalanceWithdrawn(bytes32 id, uint balance);
    event ItemAdded(bytes32 id, bytes32 name, uint price, uint qty);
    event ItemRemoved(bytes32 id);
    event ItemPriceUpdated(bytes32 id, uint newPrice, uint oldPrice);
    event ItemQuantityUpdated(bytes32 id, uint newQty, uint oldQty);
    event ItemSold(bytes32 storeId, bytes32 itemId, uint qty);

    modifier onlyAdmin() {require(administratorsByAddress[msg.sender] == true, "Sender not authorized."); _;}
    modifier onlyStoreOwner() {require(storeOwnersByAddress[msg.sender] == true, "Sender not authorized."); _;}
    modifier onlyStorefrontOwner(bytes32 id) {require(storefrontsById[id].owner == msg.sender, "Sender not authorized."); _;}

    constructor(address payable _proxy)
    Proxyable(_proxy)
    public {
        administratorsByAddress[msg.sender] = true;
        administrators.push(msg.sender);
    }

    function addAdmin(address addr)
    public
    onlyAdmin()
    returns(bool) {
        administratorsByAddress[addr] = true;
        administrators.push(addr);
        emit AdminAdded(addr);
        return true;
    }

    function removeAdmin(address addr)
    public
    onlyAdmin()
    returns(bool) {
        administratorsByAddress[addr] = false;
        uint adminCount = administrators.length;
        for(uint i = 0; i < adminCount; i++) {
            if (administrators[i] == addr) {
                administrators[i] = administrators[adminCount-1];
                delete administrators[adminCount-1];
                administrators.length --;
                break;
            }
        }
        emit AdminRemoved(addr);
        return true;
    }

    function getAdministrators()
    public
    view
    returns(address[] memory) {
        uint adminCount = administrators.length;
        address[] memory admins = new address[](adminCount);
        for (uint i = 0; i < adminCount; i++) {
            admins[i] = administrators[i];
        }
        return admins;
    }

    function addStoreOwner(address addr)
    public
    onlyAdmin()
    returns(bool) {
        storeOwnersByAddress[addr] = true;
        storeOwners.push(addr);
        emit StoreOwnerAdded(addr);
        return true;
    }

    function removeStoreOwner(address addr)
    public
    onlyAdmin()
    returns(bool) {
        storeOwnersByAddress[addr] = false;
        uint ownerCount = storeOwners.length;
        for(uint i = 0; i < ownerCount; i++) {
            if (storeOwners[i] == addr) {
                storeOwners[i] = storeOwners[ownerCount-1];
                delete storeOwners[ownerCount-1];
                storeOwners.length --;
                break;
            }
        }
        emit StoreOwnerRemoved(addr);
        return true;
    }

    function getStoreOwners()
    public
    view
    returns(address[] memory) {
        uint storeOwnerCount = storeOwners.length;
        address[] memory owners = new address[](storeOwnerCount);
        for (uint i = 0; i < storeOwnerCount; i++) {
            owners[i] = storeOwners[i];
        }
        return owners;
    }

    function createStore(bytes32 name)
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
            delete itemsById[itemId];
        }

        // Delete the store inventory
        delete inventoryByStorefrontId[storeId];

        // Remove from storefrontsByOwner mapping
        uint storefrontCount = storefrontsByOwner[msg.sender].length;
        for(uint i = 0; i < storefrontCount; i++) {
            if (storefrontsByOwner[msg.sender][i] == storeId) {
                storefrontsByOwner[msg.sender][i] = storefrontsByOwner[msg.sender][storefrontCount-1];
                delete storefrontsByOwner[msg.sender][storefrontCount-1];
                storefrontsByOwner[msg.sender].length --;
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

    function getOwnerStorefronts(address owner)
    public
    view
    returns(bytes32[] memory, bytes32[] memory, uint[] memory) {
        uint storeCount = storefrontsByOwner[owner].length;
        bytes32[] memory ids = new bytes32[](storeCount);
        bytes32[] memory names = new bytes32[](storeCount);
        uint[] memory balances = new uint[](storeCount);
        for(uint i = 0; i < storeCount; i++) {
            bytes32 storeId = storefrontsByOwner[owner][i];
            ids[i] = storefrontsById[storeId].id;
            names[i] = storefrontsById[storeId].name;
            balances[i] = storefrontsById[storeId].balance;
        }
        return (ids, names, balances);
    }

    function addItemToInventory(bytes32 storeId, bytes32 itemName, uint itemPrice, uint itemQuantity)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        bytes32 itemId = keccak256(abi.encodePacked(msg.sender, itemName, now));
        Item memory i = Item(itemId, itemName, itemPrice, itemQuantity);
        itemsById[itemId] = i;
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
                inventoryByStorefrontId[storeId].length --;
                break;
            }
        }
        //Remove item from items mapping
        delete itemsById[itemId];
        emit ItemRemoved(itemId);
        return itemId;
    }

    function updateItemPrice(bytes32 itemId, bytes32 storeId, uint newPrice)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        uint oldPrice = itemsById[itemId].price;
        itemsById[itemId].price = newPrice;
        emit ItemPriceUpdated(itemId, newPrice, oldPrice);
        return itemId;
    }

    function updateItemQuantity(bytes32 itemId, bytes32 storeId, uint newQty)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        uint oldQty = itemsById[itemId].quantity;
        itemsById[itemId].quantity = newQty;
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

    function getStorefrontInventory(bytes32 _storeId)
    public
    view
    returns(bytes32[] memory, bytes32[] memory, uint[] memory, uint[] memory)
    {
        bytes32[] memory inventory = inventoryByStorefrontId[_storeId];
        uint inventorySize = inventory.length;
        bytes32[] memory itemIds = new bytes32[](inventorySize);
        bytes32[] memory itemNames = new bytes32[](inventorySize);
        uint[] memory itemQuantities = new uint[](inventorySize);
        uint[] memory itemPrices = new uint[](inventorySize);
        for(uint i = 0; i < inventorySize; i++) {
            itemIds[i] = itemsById[inventory[i]].id;
            itemNames[i] = itemsById[inventory[i]].name;
            itemQuantities[i] = itemsById[inventory[i]].quantity;
            itemPrices[i] = itemsById[inventory[i]].price;
        }
        return (itemIds, itemNames, itemQuantities, itemPrices);
    }

    function purchaseItem(bytes32 storeId, bytes32 itemId, uint quantity)
    public
    payable
    returns(bool) {
        Item memory item = itemsById[itemId];
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
