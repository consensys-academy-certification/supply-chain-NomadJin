// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;

contract SupplyChain {

    address payable owner = msg.sender;
    uint FEE = 1 finney;
    // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
    uint itemIdCount = 0;
    
    // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
    enum State { ForSale, Sold, Shipped, Received }
    
    // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'.
    struct Item {
      string name;
      uint price;
      State state;
      address payable seller;
      address buyer;
    }
    // Create a variable named 'items' to map itemIds to Items.
    mapping(uint => Item) items;
    
    // Create an event to log all state changes for each item.
    event itemEvent(
        uint itemId,
        string name,
        uint price,
        State state,
        address seller,
        address buyer
    );
    
    
    // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
    modifier checkState(uint _id, State _state) {
        require(items[_id].state == _state);
        _;
    }
    // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
    modifier checkCaller(uint _id, bool flag) {
        if(flag == true) {
            require(msg.sender == items[_id].seller);
        } else {
            require(msg.sender == items[_id].buyer);
        }
        _;
    }
    // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
    modifier checkValue(uint _value) {
        require(msg.value >= _value);
        _;
    }
    
    
    // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
    function addItem(string memory _name, uint _price) checkValue(FEE) public payable returns(uint) {
        
        Item memory newItem;
        newItem.name = _name;
        newItem.price = _price;
        newItem.state = State.ForSale;
        newItem.seller = msg.sender;
        newItem.buyer = address(0);
        uint newItemId = itemIdCount;
        items[itemIdCount] = newItem; 
        itemIdCount++;
        
        uint paymentChange = msg.value - FEE;
        if (paymentChange > 0) {
            address(msg.sender).transfer(paymentChange);
        }

        emit itemEvent(
            newItemId,
            items[newItemId].name,
            items[newItemId].price,
            items[newItemId].state,
            items[newItemId].seller,
            items[newItemId].buyer
        );

        return newItemId;
    }
    // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
    function buyItem(uint _id) checkState(_id, State.ForSale) checkValue(items[_id].price) public payable {
        
        items[_id].buyer = msg.sender;
        items[_id].state = State.Sold;
        items[_id].seller.transfer(items[_id].price);
       
        uint paymentChange = msg.value - items[_id].price;
        if (paymentChange > 0) {
            address(msg.sender).transfer(paymentChange);
        }

        emit itemEvent(
          _id,
          items[_id].name,
          items[_id].price,
          items[_id].state,
          items[_id].seller,
          items[_id].buyer
        );
    }
    // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
    function shipItem(uint _id) checkState(_id, State.Sold) checkCaller(_id, true) public {
        items[_id].state = State.Shipped;
        emit itemEvent(
            _id,
            items[_id].name,
            items[_id].price,
            items[_id].state,
            items[_id].seller,
            items[_id].buyer
        );
    }
    // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
    function receiveItem(uint _id) checkState(_id, State.Shipped) checkCaller(_id, false) public {
        items[_id].state = State.Received;
        emit itemEvent(
            _id,
            items[_id].name,
            items[_id].price,
            items[_id].state,
            items[_id].seller,
            items[_id].buyer
        );
    }
    // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item.
    function getItem(uint _id) view public returns(string memory, uint, State, address, address) {
        return (items[_id].name, items[_id].price, items[_id].state, items[_id].seller, items[_id].buyer);
    }
    
    // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
    function withdrawFunds() onlyOwner public {
        require(address(this).balance > 0, 'No funds available.');
        owner.transfer(address(this).balance);
    }
    
    function getCurrentBalance() view public returns(uint) {
        return address(this).balance;
    }

}
