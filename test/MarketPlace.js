const { assertEventEqual } = require('../utils/testUtils');
const ethers = require('ethers');
const MarketPlace = artifacts.require('MarketPlace');

contract('MarketPlace', async accounts => {
  const [owner, account1, account2, storeOwner] = accounts;
  let marketPlace;

  beforeEach(async () => {
    marketPlace = await MarketPlace.deployed();
  });

  describe('when admin', () => {
    it('allows an admin to add another admin', async () => {
      await marketPlace.addAdmin(account1, { from: owner });
      const isAdmin = await marketPlace.administratorsByAddress(account1);
      assert.equal(isAdmin, true);
    });
    it('allows an admin to remove another admin', async () => {
      await marketPlace.addAdmin(account1, { from: owner });
      let isAdmin = await marketPlace.administratorsByAddress(account1);
      assert.equal(isAdmin, true);
      await marketPlace.removeAdmin(account1, { from: owner });
      isAdmin = await marketPlace.administratorsByAddress(account1);
      assert.equal(isAdmin, false);
    });
    it('allows an admin to add a store owner', async () => {
      await marketPlace.addStoreOwner(account2, { from: owner });
      const isStoreOwner = await marketPlace.storeOwnersByAddress(account2);
      assert.equal(isStoreOwner, true);
    });
    it('allows an admin to remove a store owner', async () => {
      await marketPlace.addStoreOwner(account2, { from: owner });
      let isStoreOwner = await marketPlace.storeOwnersByAddress(account2);
      assert.equal(isStoreOwner, true);
      await marketPlace.removeStoreOwner(account2, { from: owner });
      isStoreOwner = await marketPlace.storeOwnersByAddress(account2);
      assert.equal(isStoreOwner, false);
    });
    it('allows to see all the admin addresses', async () => {
      const admins = await marketPlace.getAdministrators();
      assert.equal(admins[0], owner);
    });

    it('allows to see all the store owner addresses', async () => {
      await marketPlace.addStoreOwner(account2, { from: owner });
      const storeOwners = await marketPlace.getStoreOwners();
      assert.equal(storeOwners[0], account2);
    });
  });

  describe('when store owner', () => {
    beforeEach(async () => {
      await marketPlace.addStoreOwner(storeOwner, { from: owner });
    });
    it('allows a store owner to create a store', async () => {
      const storeName = ethers.utils.formatBytes32String('My New Store');
      const transaction = await marketPlace.createStore(storeName, {
        from: storeOwner,
      });
      assertEventEqual(transaction, 'StoreCreated', {
        name: storeName,
        storeOwner,
      });
    });
    it('allows a store owner to remove their store', async () => {
      const storeId = await marketPlace.storefrontsByOwner(storeOwner, 0);
      let store = await marketPlace.storefrontsById(storeId);
      assert.notEqual(store.id, 0);
      await marketPlace.removeStore(storeId, {
        from: storeOwner,
      });
      store = await marketPlace.storefrontsById(storeId);
      assert.equal(store.id, 0);
    });
  });

  describe('when buyer', () => {
    var storefrontId;
    beforeEach(async () => {
      await marketPlace.addStoreOwner(storeOwner, { from: owner });
      const storeName = ethers.utils.formatBytes32String('My New Store');
      const transaction = await marketPlace.createStore(storeName, {
        from: storeOwner,
      });
      storefrontId = await marketPlace.storefronts(0);
      await marketPlace.addItemToInventory(
        storefrontId,
        ethers.utils.formatBytes32String('test'),
        ethers.utils.parseEther('1'),
        ethers.utils.parseEther('20'),
        { from: storeOwner }
      );
    });
    // it.only('allows a buyer to purchase an item', async () => {
    //   const itemId = await marketPlace.inventoryByStorefrontId(storefrontId, 0);
    //   await marketPlace.purchaseItem(
    //     storefrontId,
    //     itemId,
    //     ethers.utils.parseEther('2'),
    //     { value: ethers.utils.parseEther('2') }
    //   );
    //   assert.equal(true, false);
    // });
  });
});
