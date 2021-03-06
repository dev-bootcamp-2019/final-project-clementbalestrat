pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Mortal
 * @notice The mortal makes a contract killable
 */
contract Mortal is Ownable {
    /**
     * @dev Kill the contract
     */
    function kill() public onlyOwner {
        emit SelfDestructed(msg.sender);
        selfdestruct(msg.sender);
    }

    event SelfDestructed(address beneficiary);
}
