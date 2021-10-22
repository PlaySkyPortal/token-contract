// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "./abstract/Ownable.sol";

/**
 * @title LAPISMigrator
 * @notice This contract implements the migration from old to new LAPIS token.
 */
contract LAPISMigrator is Ownable {
    IERC20 public immutable oldLAPIS;
    IERC20 public immutable newLAPIS;

    uint256 public deadline;
    uint256 public totalLAPISMigrated;

    /**
     * @dev emitted on migration
     * @param sender the caller of the migration
     * @param amount the amount being migrated
     */
    event LAPISMigrated(address indexed sender, uint256 indexed amount);

    /**
     * @param _oldLAPIS the address of the old LAPIS token
     * @param _newLAPIS the address of the new LAPIS token
     * @param _deadline timestamp of the deadline for the migration
     */
    constructor(
        IERC20 _oldLAPIS,
        IERC20 _newLAPIS,
        uint256 _deadline
    ) {
        oldLAPIS = _oldLAPIS;
        newLAPIS = _newLAPIS;
        deadline = _deadline;
    }

    /**
     * @dev executes the migration from old LAPIS to new LAPIS.
     * Users need to give allowance to this contract to transfer old LAPIS before executing
     * this transaction.
     * Migration needs to be done before the deadline.
     * @param _amount the amount of old LAPIS to be migrated
     */
    function migrateLAPIS(uint256 _amount) external {
        require(deadline >= block.timestamp, "Migration finished");

        totalLAPISMigrated += _amount;
        oldLAPIS.transferFrom(msg.sender, address(this), _amount);
        newLAPIS.transfer(msg.sender, _amount);
        emit LAPISMigrated(msg.sender, _amount);
    }

    /**
     * @dev recover BNB from the contract
     */
    function recoverBNB() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev recover BEP20 token from the contract.
     * Old and new LAPIS tokens can be withdraw to be burned
     * after the migration deadline.
     * @param _token Bep20 token address
     */
    function recoverBep20(address _token) external onlyOwner {
        require((_token != address(oldLAPIS) && _token != address(newLAPIS)) || deadline < block.timestamp, "Not possible yet");
        uint256 amt = IERC20(_token).balanceOf(address(this));
        require(amt > 0, "Nothing to recover");
        IBadErc20(_token).transfer(owner, amt);
    }
}

interface IBadErc20 {
    function transfer(address _recipient, uint256 _amount) external;
}
