pragma solidity ^0.5.0;


contract CallistoSwap {
	//enum Chain { BNB,ETH,ETC,TRX,EOS }
	enum Status { Non, Pending, Complete }

	address payable public owner;
    address payable public newOwner;

	uint public threshold = 1; // the number of signatures that must be reached for a withdraw to take place
	uint public collectedFee; // Total amount of collected fee.
	uint public txCount;

	mapping(address => bool) authorities;
	mapping(uint8 => uint) fees;

	mapping(bytes32 => uint8) txStatus;	// Status of transaction.
	
	mapping(bytes32 => uint) authorityApproving; // Number of approving for tx ID by authorities
	mapping(bytes32 => mapping(address => bool)) authorityApproved; // tx ID to authority address to whether they have already signed

    event OwnershipTransferred(address from, address to);
	event AuthorityAdded(address addr);
	event AuthorityRemoved(address addr);
	event ThresholdUpdated(uint threshold);
	event FeeUpdated(uint8 chain, uint fee);
	event Donate(address donator, uint value);

    event MintCLO(bytes32 indexed id, string addressTo, address indexed addressFrom, uint amountToMint, uint8 chain);
	event MintComplete(bytes32 id, uint8 chain);
	event WithdrawCLO(bytes32 indexed id, address indexed addressTo, string addressFrom, uint amount, uint8 chain);
	event AuthorityApproved(bytes32 id, address authority);


	constructor() public {
		owner = msg.sender;
	}

	/* admin */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier onlyAuthority() {
		require(isAuthority(msg.sender));
		_;
	}

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

	function setThreshold(uint _threshold) public onlyOwner {
		threshold = _threshold;
		emit ThresholdUpdated(threshold);
	}

	function setFee(uint8 _chain, uint _fee) public onlyOwner {
		fees[_chain] = _fee;
		emit FeeUpdated(_chain, _fee);
	}

	function getFee(uint8 _chain) public view returns (uint) {
		return fees[_chain];
	}

	function addAuthority(address _addr) public onlyOwner {
		authorities[_addr] = true;
		emit AuthorityAdded(_addr);
	}

	function removeAuthority(address _addr) public onlyOwner {
		authorities[_addr] = false;
		emit AuthorityRemoved(_addr);
	}

	function isAuthority(address _addr) public view returns (bool) {
		return authorities[_addr];
	}

	function donate() public payable {
		// thanks
		collectedFee += msg.value;
		emit Donate(msg.sender, msg.value);
	}

	function withdrawFee() public onlyOwner {
		owner.transfer(collectedFee);
	}

	function deposit(string memory _addressTo, uint8 _toChain) public payable {
		require(msg.value >= fees[_toChain]);
		txCount++;
		collectedFee += fees[_toChain];
		uint _amountToMint = msg.value - fees[_toChain];
		bytes32 _id = keccak256(abi.encodePacked(txCount, _addressTo, msg.sender, msg.value));
		txStatus[_id] = uint8(Status.Pending);
		emit MintCLO(_id, _addressTo, msg.sender, _amountToMint, _toChain);
	}

	function getTxStatus (bytes32 _id) public view returns (uint8) {
		return txStatus[_id];
	}

	function mintComplete (bytes32 _id, uint8 _toChain) public onlyAuthority {
        require(txStatus[_id] == uint8(Status.Pending));
		require(!authorityApproved[_id][msg.sender]);
		authorityApproving[_id]++;
		authorityApproved[_id][msg.sender] = true;
		emit AuthorityApproved(_id, msg.sender);

		// if enough authorities have signed, execute the withdraw
		if(authorityApproving[_id] >= threshold) {
			txStatus[_id] = uint8(Status.Complete);
			emit MintComplete(_id, _toChain);
		}
	}

	function withdraw(address payable _addressTo, string memory _addressFrom, uint _value, uint8 _fromChain, bytes32 _id) public onlyAuthority {
		// make sure authority has not already signed for this withdraw
		if (txStatus[_id] == 0) txStatus[_id] = uint8(Status.Pending);
        require(txStatus[_id] == uint8(Status.Pending));
		require(!authorityApproved[_id][msg.sender]);
		authorityApproving[_id]++;
		authorityApproved[_id][msg.sender] = true;
		emit AuthorityApproved(_id, msg.sender);

		// if enough authorities have signed, execute the withdraw
		if(authorityApproving[_id] >= threshold) {
			_addressTo.transfer(_value);
			txStatus[_id] = uint8(Status.Complete);
			emit WithdrawCLO(_id, _addressTo, _addressFrom, _value, _fromChain);
		}
	}
}
