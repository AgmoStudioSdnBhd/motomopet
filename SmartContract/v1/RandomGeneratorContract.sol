pragma solidity >=0.4.22 <0.6.0;

contract RandomGeneratorContract {
	
    mapping(address => uint) private addressNonce;
    
	event randomNumber(uint _result);
	
    function getRandomNumber(address _address) public returns (uint result_)
    {
		uint result;
        addressNonce[_address]++;
        result = uint(keccak256(abi.encodePacked(addressNonce[msg.sender], _address, block.number, block.timestamp)));
		
		emit randomNumber(result);
		result_ = result;
    }
}