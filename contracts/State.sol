pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract State is Ownable  {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract)
				Ownable()
        public
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    //-----------------------------------------------------------------
    // Setters
    //-----------------------------------------------------------------

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    //-----------------------------------------------------------------
    // Modifiers
    //-----------------------------------------------------------------

    modifier onlyAssociatedContract
    {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    //-----------------------------------------------------------------
    // Events
    //-----------------------------------------------------------------

    event AssociatedContractUpdated(address associatedContract);
}