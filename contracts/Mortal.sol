
pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/**
 * @title Mortal
 * @notice The mortal makes a contract killable
 */
contract Mortal is Ownable {
    /**
     * @notice Kill the contract
     */
    function finish() public onlyOwner {
        selfdestruct(msg.sender);
    }
}
