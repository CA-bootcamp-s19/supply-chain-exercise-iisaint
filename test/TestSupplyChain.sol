pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract testBob {
  SupplyChain sc = SupplyChain(DeployedAddresses.SupplyChain());

  function callShipping(uint _sku) public returns (bool r) {
    (r, ) = address(sc).call(abi.encodeWithSelector(sc.shipItem.selector, _sku));
  }

  function callReceiving(uint _sku) public returns (bool r) {
    (r, ) = address(sc).call(abi.encodeWithSelector(sc.receiveItem.selector, _sku));
  }

  function() external payable {

  }
}

contract TestSupplyChain {

  // Test for failing conditions in this contracts:
  // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

  // Truffle will send the TestSupplyChain 1 ether after deploying the contract.
  uint public initialBalance = 0.001 ether;

  string itemName = "book";
  uint itemPrice = 1000;

  SupplyChain sc = SupplyChain(DeployedAddresses.SupplyChain());

  address alice = address(this);
  testBob bob = new testBob();

  // buyItem

  // test for failure if user does not send enough funds
  function testBuyItemNotEnoughFunds() public {
    bool r;
    
    // add an item for sale
    r = sc.addItem(itemName, itemPrice);
    Assert.isTrue(r, "add item failed");

    // check item
    checkItem(itemName, 0, itemPrice, 0, alice, address(0));

    // buy the item, but does not send enough funds
    (r, ) = address(sc).call.value(1)(abi.encodeWithSelector(sc.buyItem.selector, 0));
    Assert.isFalse(r, "should be falied");
  }
  // test for purchasing an item that is not for Sale
  function testBuyItemNotForSale() public {
    bool r;

    // buy item 0
    (r, ) = address(sc).call.value(itemPrice)(abi.encodeWithSelector(sc.buyItem.selector, 0));
    Assert.isTrue(r, "buy item failed");

    // check item
    checkItem(itemName, 0, itemPrice, 1, alice, alice);

    // buy the item again
    (r, ) = address(sc).call.value(itemPrice)(abi.encodeWithSelector(sc.buyItem.selector, 0));
    Assert.isFalse(r, "should be failed");
  }

  // shipItem

  // test for calls that are made by not the seller
  function testShipItemNotSeller() public {
    // ship item 0 from another address
    bool r = bob.callShipping(0);
    Assert.isFalse(r, "should be failed");
  }
  
  // test for trying to ship an item that is not marked Sold
  function testShipItemNotSold() public {
    bool r;

    // add an item for sale
    r = sc.addItem(itemName, itemPrice);
    Assert.isTrue(r, "add item failed");

    // check item
    checkItem(itemName, 1, itemPrice, 0, alice, address(0));

    (r, ) = address(sc).call(abi.encodeWithSelector(sc.shipItem.selector, 1));
    Assert.isFalse(r, "should be failed");
  }

  // receiveItem

  // test calling the function from an address that is not the buyer
  function testReceiveItemNotBuyer() public {
    bool r;
  
    (r, ) = address(sc).call(abi.encodeWithSelector(sc.shipItem.selector, 0));
    Assert.isTrue(r, "ship item falied");

    // check item 0
    checkItem(itemName, 0, itemPrice, 2, alice, alice);

    r = bob.callReceiving(0);
    Assert.isFalse(r, "should be failed");
  }
  // test calling the function on an item not marked Shipped
  function testReceiveItemNotShipped() public {
    bool r;

    (r, ) = address(sc).call(abi.encodeWithSelector(sc.receiveItem.selector, 0));
    Assert.isTrue(r, "receive item failed");

    // check item
    checkItem(itemName, 0, itemPrice, 3, alice, alice);

    // receive item from buyer
    (r, ) = address(sc).call.value(itemPrice)(abi.encodeWithSelector(sc.receiveItem.selector, 0));
    Assert.isFalse(r, "should be failed");
  }

  // helper function
  function checkItem(string memory _name, uint _sku, uint _price, uint _state, address _seller, address _buyer) internal {
    (string memory name, uint sku, uint price, uint state, address seller, address buyer) = sc.fetchItem(_sku);
    Assert.equal(name, _name, "name does not match");
    Assert.equal(sku, _sku, "sku does not match");
    Assert.equal(price, _price, "price does not match");
    Assert.equal(state, _state, "state does not match");
    Assert.equal(seller, _seller, "seller does not match");
    Assert.equal(buyer, _buyer, "buyer does not match");
  }

  // fallback function to receive refund from supply chain contract
  function () external payable {

  }
}
