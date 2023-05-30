// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;


/** 
    @notice The contract allows anyone to stake and unstake Ether. When a seller publish a new item
    in the shop, the funds are locked during the sale. If the user is considered malicious
    by the DAO, the funds are slashed. 
    @dev Security review is pending... should we deploy this?
    @custom:ctf This contract is part of the exercises at https://github.com/jcr-security/solidity-security-teaching-resources
*/
contract VulnerableVault { 

    // The balance of the users in the vault
    mapping (address => uint256) balance;
    // The amount of funds locked for selling purposes
    mapping (address => uint256) lockedFunds;
    // The address of the powerseller NFT contract
    address powerseller_nft;
    // The address of the Shop contract
    address shop_addr;

    /************************************** Events and modifiers *****************************************************/

    event Stake(address user, uint amount);
    event Unstake(address user, uint amount);
    event Rewards(address user, uint amount);
    

    ///@notice Check if the user has enough unlocked funds staked
    modifier enoughStaked(uint amount) {
		require(
            (balance[msg.sender] - amount) > 0,
            "Amount cannot be unstaked"
        );

        _;
    }

    ///@notice Check if the user has enough unlocked funds staked
    modifier onlyShop() {
		require(
            msg.sender == shop_addr,
            "Unauthorized"
        );
        _;
    }


    /************************************** External  ****************************************************************/ 

    /**
        @notice Constructor, initializes the contract
        @param token The address of the powerseller NFT contract
        @param shop The address of the Shop contract
    */
    constructor(address token, address shop) {
        powerseller_nft = token;
        shop_addr = shop;
    }


    ///@notice Stake attached funds in the vault for later locking, the users must do it on their own
    function doStake() external payable {
        require(msg.value > 0, "Amount cannot be zero");
        balance[msg.sender] += msg.value;
        
        emit Stake(msg.sender, msg.value);
    }
	

    ///@notice Unstake unlocked funds from the vault, the user must do it on their own
    ///@param amount The amount of funds to unstake 
    function doUnstake(uint amount) external enoughStaked(msg.sender, amount) {	
        require(amount > 0, "Amount cannot be zero");

        balance[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Unstake failed");

        emit Unstake(msg.sender, amount);
	}


    /**
    @notice Claim rewards generated by slashing malicious users. 
        First checks if the user is elegible through the checkPrivilege function that will revert if not. 
     */
    function claimRewards() external {	
        uint amount;

        powerseller_nft.call(
            abi.encodeWithSignature(
                "checkPrivilege(address)",
                msg.sender
            )
        );

        /*
        * Rewards distribution logic goes here
        */

        emit Rewards(msg.sender, amount);
	}


    /************************************** Views  *******************************************************/

    ///@notice Get the balance of the vault
	function vaultBalance () public view returns (uint256) {
		return address(this).balance;
	}
	
    ///@notice Get the staked balance of a user
    ///@param user The address of the user to query
	function userBalance (address user) public view returns (uint256) {
		return balance[user];
	}

}
