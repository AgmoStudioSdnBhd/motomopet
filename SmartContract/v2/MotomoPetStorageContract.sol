pragma solidity >=0.4.22 < 0.6.0;

contract MotomoPetStorageContract
{
    //This is where i store user's pet
    //Address => PetId => User Pet Information
    mapping(address => mapping(uint => Pet)) private userPet;
    mapping(address => uint[]) private userPetList;
    
    //This is where i store user's equipment
    //Address => EquipmentId => User Equipment information
    mapping(address => mapping(uint => Equipment)) private userEquipment;
    mapping(address => uint[]) private userEquipmentList;
    
    //This is where i store user's gold coin
    mapping(address => uint) private userGoldCoin;
    
    //This is where i store allowed contract address to call my method
    mapping(address => bool) private motomoAdminAddress;
    
    //Constants
    uint private petLevelUpGoldCoinReward;
	
    //Pet basic structure
    struct Pet 
    {
        uint petId;
        uint petTypeId;
        uint experience;
        uint petLevel;
    }
    
    //Equipment basic structure
    struct Equipment
    {
        uint equipmentId;
        uint equipmentTypeId;
        uint rarityId;
        bool recycled;
    }
    
    constructor() public 
    {
        motomoAdminAddress[msg.sender] = true;
    }
    
    modifier adminOnly {
        require(motomoAdminAddress[msg.sender], "Unauthorized");
        _;
    }
    
    function removeAdmin(address _address) public adminOnly 
    {
        motomoAdminAddress[_address] = false;
    }
    
    function addAdmin(address _address) public adminOnly    
    {
        motomoAdminAddress[_address] = true;
    }
    
    function isAdmin(address _address) public view returns (bool isAdmin_)
    {
        isAdmin_ = motomoAdminAddress[_address];
    }
    
    function addGoldCoin(address _address, uint _amount) public adminOnly
    {
        userGoldCoin[_address] = userGoldCoin[_address] + _amount;
    }
    
	function useGoldCoin(address _address, uint _amount) public adminOnly
	{
	    require(userGoldCoin[_address] >= _amount, "User does not have enough gold coin");
	    userGoldCoin[_address] = userGoldCoin[_address] - _amount; 
	}
	
	function getGoldCoin(address _address) public view returns (uint amount_)
	{
	    amount_ = userGoldCoin[_address];
	}
	
    function addPet(address _address, uint _petId, uint _petTypeId) public adminOnly 
    {
        require(userPet[_address][_petId].petLevel == 0, "Pet already exists");
        userPet[_address][_petId] = Pet(_petId, _petTypeId, 0, 1);
        userPetList[_address].push(_petId);
    }
	
    function testRecovery(bytes32 h, uint8 v, bytes32 r, bytes32 s) returns (address) 
	{
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = sha3(prefix, h);
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }
	
    function setLevelUpReward(uint _rewardAmount) public adminOnly 
    {
        petLevelUpGoldCoinReward = _rewardAmount;
    }
    
    function getLevelUpReward() public view returns (uint rewardAmount_)
    {
        rewardAmount_ = petLevelUpGoldCoinReward;
    }
    
    function updatePetLevel(address _address, uint _petId, uint _newPetLevel, uint _newExperience) public adminOnly
    {
        require(userPet[_address][_petId].petLevel != 0, "Pet does not exists");
        require(userPet[_address][_petId].petLevel < _newPetLevel, "Pet does not exists");
        uint levelDifference = _newPetLevel - userPet[_address][_petId].petLevel;
        userPet[_address][_petId].petLevel = _newPetLevel;
        userPet[_address][_petId].experience = _newExperience;
        userGoldCoin[_address] = userGoldCoin[_address] + (levelDifference * petLevelUpGoldCoinReward);
    }
    
    function getUserEquipmentList(address _address) public view returns (uint[] memory equipmentList_)
    {
        equipmentList_ = userEquipmentList[_address];
    }
    
    function getUserPetList(address _address) public view returns (uint[] memory petLists_)
    {
        petLists_ = userPetList[_address];
    }
    
    function getPetById(address _address, uint _id) public view returns (uint petId_, uint petTypeId_, uint experience_, uint petLevel_)
    {
        petId_ = userPet[_address][_id].petId;
        petTypeId_ = userPet[_address][_id].petTypeId;
        experience_ = userPet[_address][_id].experience;
        petLevel_ = userPet[_address][_id].petLevel;
    }
    
    function getEquipmentById(address _address, uint _id) public view returns (uint equipmentId_, uint equipmentTypeId_, uint rarityId_, bool recycled_)
    {
        equipmentId_ = userEquipment[_address][_id].equipmentId;
        equipmentTypeId_ = userEquipment[_address][_id].equipmentTypeId;
        rarityId_ = userEquipment[_address][_id].rarityId;
        recycled_ = userEquipment[_address][_id].recycled;
    }
    
    function addEquipment(address _address, uint _equipmentId, uint _equipmentTypeId, uint _rarityId) public adminOnly
    {
        require(userEquipment[_address][_equipmentId].equipmentId == 0, "Equipment already exists");
        userEquipment[_address][_equipmentId] = Equipment(_equipmentId, _equipmentTypeId, _rarityId, false);
        userEquipmentList[_address].push(_equipmentId);
    }
    
    function updateEquipmentStatus(address _address, uint _equipmentId, bool _recycled) public adminOnly
    {
        require(userEquipment[_address][_equipmentId].equipmentId != 0, "Equipment does not exists");
        userEquipment[_address][_equipmentId].recycled = _recycled;
    }
}