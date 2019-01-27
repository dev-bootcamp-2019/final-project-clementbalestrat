pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Mortal.sol";
import "./SafeDecimalMath.sol";

/*
* @title Marketplace
*
* @dev This contract allows the addition and removal of admins and storefront owners.
* It also allows a storefront owner to manage storefronts and add, edit and remove items from their inventories.
* Finally, it allows purchasers to buy items from any storefronts.
* The Ownable and Pausable and SafeMath contracts are all taken from Zeppelin.
*/
contract MarketPlace is Ownable, Pausable, Mortal {

    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    /* ========== STATE VARIABLES ========== */

    // Arrays and mappings to store current administrators and storeowners
    address[] public administrators;
    mapping (address => bool) public administratorsByAddress;
    address[] public storeOwners;
    mapping (address => bool) public storeOwnersByAddress;

    /*
    * Arrays and mappings to store all the storefronts,
    * storefronts by owner and storefront by id.
    */
    bytes32[] public storefronts;
    mapping (address => bytes32[]) public storefrontsByOwner;
    mapping (bytes32 => Storefront) public storefrontsById;

    /*
    * Mappings to store inventory by storefront and
    * inventory item per id.
    */
    mapping(bytes32 => bytes32[]) public inventoryByStorefrontId;
    mapping(bytes32 => Item) private itemsById;

    /** @dev Struct which stores storefront data.
	* @param id Storefront id.
	* @param name Storefront name.
	* @param owner Storefront owner address.
	* @param balance Storefront balance.
	*/
    struct Storefront {
        bytes32 id;
        bytes32 name;
        address owner;
        uint balance;
    }

    /** @dev Struct which stores Item data.
	* @param id Item id.
	* @param name Item name.
	* @param price Item price.
	* @param quantity Item quantity.
	*/
    struct Item {
        bytes32 id;
        bytes32 name;
        uint price;
        uint quantity;
    }

    /* ========== EVENTS ========== */

    event AdminAdded(address admin);
    event AdminRemoved(address admin);
    event StoreOwnerAdded(address storeOwner);
    event StoreOwnerRemoved(address storeOwner);
    event StoreCreated(bytes32 id, bytes32 name, address storeOwner);
    event StoreRemoved(bytes32 id);
    event BalanceWithdrawn(bytes32 id, uint balance);
    event ItemAdded(bytes32 id, bytes32 name, uint price, uint quantity);
    event ItemRemoved(bytes32 id);
    event ItemPriceUpdated(bytes32 id, uint newPrice, uint oldPrice);
    event ItemQuantityUpdated(bytes32 id, uint newQuantity, uint oldQuantity);
    event ItemSold(bytes32 storeId, bytes32 itemId, uint quantity);

    /* ========== MODIFIERS ========== */

    // @dev Verifies if msg.sender is an administrator.
    modifier onlyAdmin() {require(administratorsByAddress[msg.sender] == true, "Sender not authorized."); _;}

    // @dev Verifies if msg.sender is a store owner.
    modifier onlyStoreOwner() {require(storeOwnersByAddress[msg.sender] == true, "Sender not authorized."); _;}

    /** @dev Verifies if msg.sender is the owner of a specific store.
    * @param _storeId The store ID.
    */
    modifier onlyStorefrontOwner(bytes32 _storeId) {require(storefrontsById[_storeId].owner == msg.sender, "Sender not authorized."); _;}

    /* ========== CONSTRUCTOR ========== */

    /**
    * @dev Constructor.
    * Sets msg.sender as the owner.
    * Sets msg.sender as an administrator.
    */
    constructor()
    Ownable()
    public {
        administratorsByAddress[msg.sender] = true;
        administrators.push(msg.sender);
    }

    /* ========== ADMINISTRATOR FUNCTIONS ========== */

    /** @dev Adds a new administrator.
    * @param _addr The address to add.
    * @return true if added successfully.
    */
    function addAdmin(address _addr)
    public
    onlyAdmin()
    returns(bool) {
        administratorsByAddress[_addr] = true;
        administrators.push(_addr);
        emit AdminAdded(_addr);
        return true;
    }

    /** @dev Removes an administrator.
    * @param _addr The address to remove.
    * @return true if removed successfully.
    */
    function removeAdmin(address _addr)
    public
    onlyAdmin()
    returns(bool) {
        require(_addr != owner(), "Owner cannot be removed from administrators");
        administratorsByAddress[_addr] = false;
        uint adminCount = administrators.length;
        for(uint i = 0; i < adminCount; i++) {
            if (administrators[i] == _addr) {
                administrators[i] = administrators[adminCount-1];
                delete administrators[adminCount-1];
                administrators.length --;
                break;
            }
        }
        emit AdminRemoved(_addr);
        return true;
    }

    /** @dev Get a list of all the administrators.
    * @return admins The array of all the administrators address.
    */
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

    /* ========== STORE OWNER FUNCTIONS ========== */

    /** @dev Adds a new store owner.
    * @param _addr The address to add.
    * @return true if added successfully.
    */
    function addStoreOwner(address _addr)
    public
    onlyAdmin()
    whenNotPaused()
    returns(bool) {
        storeOwnersByAddress[_addr] = true;
        storeOwners.push(_addr);
        emit StoreOwnerAdded(_addr);
        return true;
    }

    /** @dev Removes a store owner.
    * @param _addr The address to remove.
    * @return true if removed successfully.
    */
    function removeStoreOwner(address _addr)
    public
    onlyAdmin()
    whenNotPaused()
    returns(bool) {
        storeOwnersByAddress[_addr] = false;
        uint ownerCount = storeOwners.length;
        for(uint i = 0; i < ownerCount; i++) {
            if (storeOwners[i] == _addr) {
                storeOwners[i] = storeOwners[ownerCount-1];
                delete storeOwners[ownerCount-1];
                storeOwners.length --;
                break;
            }
        }
        emit StoreOwnerRemoved(_addr);
        return true;
    }

     /** @dev Get a list of all the store owners.
    * @return owners The array of all the store owners address.
    */
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

    /* ========== STORE FRONT FUNCTIONS ========== */

    /** @dev Creates a new storefront.
    * @param _name The name of the new storefront.
    * @return id The ID of the new storefront.
    */
    function createStore(bytes32 _name)
    public
    onlyStoreOwner()
    whenNotPaused()
    returns(bytes32) {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, _name, now));
        Storefront memory s = Storefront(id, _name, msg.sender, 0);
        storefronts.push(id);
        storefrontsByOwner[msg.sender].push(id);
        storefrontsById[id] = s;
        emit StoreCreated(id, _name, msg.sender);
        return id;
    }

    /** @dev Removes a storefront. Also deletes its inventory, items
    * and transfers balance fund to the owner if needed.
    * @param _storeId The storefront ID.
    * @return _storeId The deleted storefront ID.
    */
    function removeStore(bytes32 _storeId)
    public
    onlyStorefrontOwner(_storeId)
    whenNotPaused()
    returns(bytes32) {

        // Delete all the items from the store inventory.
        for (uint i = 0; i < inventoryByStorefrontId[_storeId].length; i++) {
            bytes32 itemId = inventoryByStorefrontId[_storeId][i];
            delete itemsById[itemId];
        }

        // Delete the store inventory.
        delete inventoryByStorefrontId[_storeId];

        // Remove from storefrontsByOwner mapping.
        uint storefrontCount = storefrontsByOwner[msg.sender].length;
        for(uint i = 0; i < storefrontCount; i++) {
            if (storefrontsByOwner[msg.sender][i] == _storeId) {
                storefrontsByOwner[msg.sender][i] = storefrontsByOwner[msg.sender][storefrontCount-1];
                delete storefrontsByOwner[msg.sender][storefrontCount-1];
                storefrontsByOwner[msg.sender].length --;
                break;
            }
        }

        // Remove from storefronts array.
        storefrontCount = storefronts.length;
        for(uint i = 0; i < storefrontCount; i++) {
            if (storefronts[i] == _storeId) {
                storefronts[i] = storefronts[storefrontCount - 1];
                delete storefronts[storefrontCount - 1];
                storefronts.length --;
                break;
            }
        }

        // Withdraw Balance if needed.
        uint storefrontBalance = storefrontsById[_storeId].balance;
        if (storefrontBalance > 0) {
            storefrontsById[_storeId].balance = 0;
            msg.sender.transfer(storefrontBalance);
            emit BalanceWithdrawn(_storeId, storefrontBalance);
        }

        // Remove from storefrontsById.
        delete storefrontsById[_storeId];
        emit StoreRemoved(_storeId);
        return _storeId;
    }

    /** @dev Get a list of all the storefronts owned by a specific owner.
    * @param _storefrontOwner The storefront owner ID.
    * @return (ids, names, balances) The arrays containing all the store IDs, names and balances.
    */
    function getOwnerStorefronts(address _storefrontOwner)
    public
    view
    returns(bytes32[] memory, bytes32[] memory, uint[] memory) {
        uint storeCount = storefrontsByOwner[_storefrontOwner].length;
        bytes32[] memory ids = new bytes32[](storeCount);
        bytes32[] memory names = new bytes32[](storeCount);
        uint[] memory balances = new uint[](storeCount);
        for(uint i = 0; i < storeCount; i++) {
            bytes32 storeId = storefrontsByOwner[_storefrontOwner][i];
            ids[i] = storefrontsById[storeId].id;
            names[i] = storefrontsById[storeId].name;
            balances[i] = storefrontsById[storeId].balance;
        }
        return (ids, names, balances);
    }

    /** @dev Transfers a storefront balance to its owner.
    * @param _storeId The storefront ID.
    * @return true If balance was sent successfully.
    */
    function widthdrawStorefrontBalance(bytes32 _storeId)
    public
    onlyStorefrontOwner(_storeId)
    whenNotPaused()
    returns(bool) {
        uint storefrontBalance = storefrontsById[_storeId].balance;
        if (storefrontBalance > 0) {
            storefrontsById[_storeId].balance = 0;
            msg.sender.transfer(storefrontBalance);
            emit BalanceWithdrawn(_storeId, storefrontBalance);
        }
    }

    /** @dev Get all the created Storefronts.
    * @return (ids, names, owners) The Id, name and owner for each Storefront.
    */
    function getStorefronts()
    public
    view
    returns(bytes32[] memory, bytes32[] memory, address[] memory) {
        uint storeCount = storefronts.length;
        bytes32[] memory ids = new bytes32[](storeCount);
        bytes32[] memory names = new bytes32[](storeCount);
        address[] memory owners = new address[](storeCount);
        for(uint i = 0; i < storeCount; i ++) {
            ids[i] = storefrontsById[storefronts[i]].id;
            names[i] = storefrontsById[storefronts[i]].name;
            owners[i] = storefrontsById[storefronts[i]].owner;
        }
        return(ids, names, owners);
    }

    /* ========== INVENTORY FUNCTIONS ========== */

    /** @dev Adds an Item to a Storefront inventory.
    * @param _storeId The storefront ID we want to update the inventory from.
    * @param _itemName The new item name.
    * @param _itemPrice The new item price.
    * @param _itemQuantity The new item quantity.
    * @return itemId The new item ID.
    */
    function addItemToInventory(bytes32 _storeId, bytes32 _itemName, uint _itemPrice, uint _itemQuantity)
    public
    onlyStorefrontOwner(_storeId)
    whenNotPaused()
    returns(bytes32) {
        bytes32 itemId = keccak256(abi.encodePacked(msg.sender, _itemName, now));
        Item memory i = Item(itemId, _itemName, _itemPrice, _itemQuantity);
        itemsById[itemId] = i;
        inventoryByStorefrontId[_storeId].push(itemId);
        emit ItemAdded(itemId, _itemName, _itemPrice, _itemQuantity);
        return itemId;
    }

    /** @dev Removes an Item from a Storefront inventory.
    * @param _itemId The item ID we want to delete.
    * @param _storeId The storefront ID we want to update the inventory from.
    * @return _itemId The deleted item ID.
    */
    function removeItemFromInventory(bytes32 _itemId, bytes32 _storeId)
    public
    onlyStorefrontOwner(_storeId)
    whenNotPaused()
    returns(bytes32) {
        // Remove the item from inventory mapping
        uint itemCount = inventoryByStorefrontId[_storeId].length;
        for(uint i = 0; i < itemCount; i++) {
            if (inventoryByStorefrontId[_storeId][i] == _itemId) {
                inventoryByStorefrontId[_storeId][i] = inventoryByStorefrontId[_storeId][itemCount-1];
                delete inventoryByStorefrontId[_storeId][itemCount-1];
                inventoryByStorefrontId[_storeId].length --;
                break;
            }
        }
        //Remove item from items mapping
        delete itemsById[_itemId];
        emit ItemRemoved(_itemId);
        return _itemId;
    }

    /** @dev Updates the price of an Item from a specicic Storefront.
    * @param _itemId The item ID we want to update.
    * @param _storeId The storefront ID we want to update the inventory from.
    * @param _newPrice The new price we want to set the Item to.
    * @return _itemId The updated item ID.
    */
    function updateItemPrice(bytes32 _itemId, bytes32 _storeId, uint _newPrice)
    public
    onlyStorefrontOwner(_storeId)
    whenNotPaused()
    returns(bytes32) {
        uint oldPrice = itemsById[_itemId].price;
        itemsById[_itemId].price = _newPrice;
        emit ItemPriceUpdated(_itemId, _newPrice, oldPrice);
        return _itemId;
    }

    /** @dev Updates the quantity of an Item from a specicic Storefront.
    * @param _itemId The item ID we want to update.
    * @param _storeId The storefront ID we want to update the inventory from.
    * @param _newQuantity The new quantity value we want to set the Item to.
    * @return _itemId The updated item ID.
    */
    function updateItemQuantity(bytes32 _itemId, bytes32 _storeId, uint _newQuantity)
    public
    onlyStorefrontOwner(_storeId)
    whenNotPaused()
    returns(bytes32) {
        uint oldQty = itemsById[_itemId].quantity;
        itemsById[_itemId].quantity = _newQuantity;
        emit ItemQuantityUpdated(_itemId, _newQuantity, oldQty);
        return _itemId;
    }

    /** @dev Get the inventory for a specific Storefront.
    * @param _storeId The storefront ID.
    * @return (itemIds, itemNames, itemQuantities, itemPrices) The Id, name, quantity and price for each Item.
    */
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

    /* ========== PURCHASER FUNCTIONS ========== */

    /** @dev Allows a visitor to purchase an Item from a Storefront.
    * @param _storeId The storefront ID.
    * @param _itemId The item ID.
    * @param _quantity The item quantity.
    * @return true If transaction was successful.
    */
    function purchaseItem(bytes32 _storeId, bytes32 _itemId, uint _quantity)
    public
    whenNotPaused()
    payable
    returns(bool) {
        Item memory item = itemsById[_itemId];
        uint totalPrice = item.price.multiplyDecimal(_quantity);
        require(msg.value >= totalPrice, "msg.value must be greater or equal than total price");
        require(item.quantity >= _quantity, "Item quantity is not enough");

        if (msg.value > totalPrice) {
            msg.sender.transfer(msg.value - totalPrice);
        }

        itemsById[_itemId].quantity = itemsById[_itemId].quantity.sub(_quantity);
        storefrontsById[_storeId].balance = storefrontsById[_storeId].balance.add(totalPrice);
        emit ItemSold(_storeId, _itemId, _quantity);
        return true;
    }
}
