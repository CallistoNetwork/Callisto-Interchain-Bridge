pragma solidity ^0.5.0;


contract CallistoSwap {
	enum Status { Non, Pending, Complete }

	address payable public owner;
    address payable public newOwner;

	uint public collectedFee; // Total amount of collected fee.
	uint public txCount;
	address public authority;
	uint public fee;

	mapping(bytes32 => uint8) txStatus;	// Status of transaction.

    event OwnershipTransferred(address from, address to);
	event AuthorityAdded(address addr);
	event FeeUpdated(uint fee);
	event Donate(address donator, uint value);

    event MintCLO(bytes32 indexed id, string addressTo, address indexed addressFrom, uint amountToMint);
	event MintComplete(bytes32 id);
	event WithdrawCLO(bytes32 indexed id, address indexed addressTo, string addressFrom, uint amount);


	constructor() public {
		owner = msg.sender;
	}

	/* admin */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	modifier onlyAuthority() {
		require(msg.sender == authority);
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

	function setFee(uint _fee) public onlyOwner {
		fee = _fee;
		emit FeeUpdated(_fee);
	}

	function setAuthority(address _addr) public onlyOwner {
		authority = _addr;
		emit AuthorityAdded(_addr);
	}

	function donate() public payable {
		// thanks
		collectedFee += msg.value;
		emit Donate(msg.sender, msg.value);
	}

	function withdrawFee() public onlyOwner {
		owner.transfer(collectedFee);
	}

	function deposit(string memory _addressTo) public payable {
		require(msg.value >= fee);
		txCount++;
		collectedFee += fee;
		uint _amountToMint = msg.value - fee;
		bytes32 _id = keccak256(abi.encodePacked(txCount, _addressTo, msg.sender, msg.value));
		txStatus[_id] = uint8(Status.Pending);
		emit MintCLO(_id, _addressTo, msg.sender, _amountToMint);
	}

	function getTxStatus (bytes32 _id) public view returns (uint8) {
		return txStatus[_id];
	}

	function mintComplete (bytes32 _id) public onlyAuthority {
        require(txStatus[_id] == uint8(Status.Pending));
        txStatus[_id] = uint8(Status.Complete);
        emit MintComplete(_id);
	}

	function withdraw(address payable _addressTo, string memory _addressFrom, uint _value, bytes32 _id) public onlyAuthority {
        _addressTo.transfer(_value);
        emit WithdrawCLO(_id, _addressTo, _addressFrom, _value);
	}
}
