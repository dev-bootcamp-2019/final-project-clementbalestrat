pragma solidity ^0.5.0;

import "./State.sol";

contract MarketPlaceState is State {
    mapping (address => bool) public administrators;
    
    constructor(address _associatedContract)
    State(_associatedContract)
    public {
        administrators[msg.sender] = true;
    }
    
    function addAdministrator(address _addr)
    external
    onlyAssociatedContract {
        administrators[_addr] = true;
    }

    function removeAdministrator(address _admin)
    external
    onlyAssociatedContract {
        administrators[_admin] = false;
    }


}