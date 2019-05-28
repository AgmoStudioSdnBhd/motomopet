pragma solidity >=0.4.22 < 0.6.0;

contract MotomoPetStorageContract 
{
    function addGoldCoin(address _address, uint _amount) public {}
    function useGoldCoin(address _address, uint _amount) public {}
    function getGoldCoin(address _address) public view returns (uint amount_) {}
    function addPet(address _address, uint _petId, uint _petTypeId) public {}
    function setLevelUpReward(uint _rewardAmount) public {}
    function getLevelUpReward() public view returns (uint rewardAmount_) {}
    function updatePetLevel(address _address, uint _petId, uint _newPetLevel, uint _newExperience) public {}
    function getUserEquipmentList(address _address) public view returns (uint[] memory equipmentList_) {}
    function getUserPetList(address _address) public view returns (uint[] memory petLists_) {}
    function getPetById(address _address, uint _id) public view returns (uint petId_, uint petTypeId_, uint experience_, uint petLevel_) {}
    function getEquipmentById(address _address, uint _id) public view returns (uint equipmentId_, uint equipmentTypeId_, uint rarityId_,  bool recycled_) {}
    function addEquipment(address _address, uint _equipmentId, uint _equipmentTypeId, uint _rarityId) public {}
    function updateEquipmentStatus(address _address, uint _equipmentId, bool _recycled) public {}
}

contract RandomGeneratorContract
{
    function getRandomNumber() public returns (uint result_) {}
}

contract MotomoPetContract 
{
    //This is where i store allowed contract address to call my method
    mapping(address => bool) private motomoAdminAddress;
    
    //Reference to other contract
    RandomGeneratorContract randomGeneratorContract;
    MotomoPetStorageContract motomoPetStorageContract;
    
    //Constant
    //rarityId => recycleGoldCoin
    mapping(uint => uint) rarityRecycleGoldCoinList;
    mapping(uint => Rarity) rarityList;
    uint rarityDenominator;
    uint gachaponGoldCoinCost;
    
    //Constant. Storing equipment rarity list
    // rarityId => list of equipmentIds
    mapping(uint => uint[]) equipmentTypeRarityList;
    
    struct Rarity
    {
        RARITY rarity;
        uint probability;
    }
    
    enum RARITY 
    {
        COMMON,
        UNCOMMON,
        RARE
    }
    
    constructor (address _storageContractAddress, address _randomGeneratorContractAddress) public
    {
        randomGeneratorContract = RandomGeneratorContract(_randomGeneratorContractAddress);
        motomoPetStorageContract = MotomoPetStorageContract(_storageContractAddress);
        motomoAdminAddress[msg.sender] = true;
        
        //Default gold coin when recycling an equipment base on its rarity
        rarityRecycleGoldCoinList[uint(RARITY.COMMON)] = 25;
        rarityRecycleGoldCoinList[uint(RARITY.UNCOMMON)] = 50;
        rarityRecycleGoldCoinList[uint(RARITY.RARE)] = 75;
        
        //Default rarity list
        rarityList[0] = Rarity(RARITY.COMMON, 70);
        rarityList[1] = Rarity(RARITY.UNCOMMON, 20);
        rarityList[2] = Rarity(RARITY.RARE, 10);
        
        rarityDenominator = 100;
        
        gachaponGoldCoinCost = 200;
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
    
    //get contract constant
    function getGachaponGoldCoinCost() public view returns (uint amount_)
    {
        amount_ =  gachaponGoldCoinCost;
    }
	
    function getRarityRecycleGoldCoinByRarityId(uint _rarityId) public view returns (uint amount_)
    {
        amount_ = rarityRecycleGoldCoinList[_rarityId];
    }
    
    function getRarityProbabilityByRarityId(uint _rarityId) public view returns (uint probability_) 
    {
        probability_ = rarityList[_rarityId].probability;
    }
	
	//update contract constant
	function updateRarityRecycleGoldCoin(uint _rarityId, uint _goldCoin) public adminOnly 
	{
	    rarityRecycleGoldCoinList[_rarityId] = _goldCoin;
	}
	
	function updateRarityProbability(uint _rareProbabilty, uint _uncommonProbability, uint _denominator) public adminOnly
	{
	    require(_rareProbabilty + _uncommonProbability < _denominator);
	    rarityList[uint(RARITY.COMMON)].probability = _denominator - _rareProbabilty - _uncommonProbability;
	    rarityList[uint(RARITY.UNCOMMON)].probability = _uncommonProbability;
	    rarityList[uint(RARITY.RARE)].probability = _rareProbabilty;
	    rarityDenominator = _denominator;
	}
	
	function updateGachaponGoldCoinCost(uint _cost) public adminOnly
	{
	    gachaponGoldCoinCost = _cost;
	}
	
	//private get contract constant
	function getRarityByRandomNumber(uint _randomNumber) private view returns (uint rarity_)
	{
	    uint normalizedRandomNumber = _randomNumber % rarityDenominator;
	    if(normalizedRandomNumber < rarityList[0].probability)
	        rarity_ = uint(rarityList[0].rarity);
	    else if(normalizedRandomNumber < rarityList[0].probability + rarityList[1].probability)
	        rarity_ = uint(rarityList[1].rarity);
	    else
	        rarity_ = uint(rarityList[2].rarity);
	}
	
	//Non-proxy Method
	function userGetRandomEquipment(address _address, uint _equipmentId) public adminOnly returns (uint equipmentTypeId_) 
	{
	    //check if user has sufficient gold coin
	    uint userCoin = motomoPetStorageContract.getGoldCoin(_address);
	    require(userCoin >= gachaponGoldCoinCost, "User does not have enough gold coin");
	    
	    motomoPetStorageContract.useGoldCoin(_address, gachaponGoldCoinCost);
	    
	    // get random equipmentTypeId
	    uint randomNumber = randomGeneratorContract.getRandomNumber();
	    uint rarity = getRarityByRandomNumber(randomNumber);
	    
	    uint equipmentTypeRarityListIndex = randomNumber % equipmentTypeRarityList[rarity].length;
	    uint equipmentTypeId = equipmentTypeRarityList[rarity][equipmentTypeRarityListIndex];
	    
	    //add equipmentTypeId to user
	    motomoPetStorageContract.addEquipment(_address, _equipmentId, equipmentTypeId, rarity);
	    
	    equipmentTypeId_ = equipmentTypeId;
	}
	
	function userRecycleEquipment(address _address, uint _equipmentId) public adminOnly
	{
	    (uint equipmentId, uint equipmentTypeId, uint rarityId, bool recycled) = motomoPetStorageContract.getEquipmentById(_address, _equipmentId);
	    require(equipmentId != 0 && !recycled, "Equipment not found");
	    
	    //set user equipment to recycled
	    motomoPetStorageContract.updateEquipmentStatus(_address, _equipmentId, true);
	    
	    //increment user goldcoin
	    uint goldCoin = rarityRecycleGoldCoinList[rarityId];
	    motomoPetStorageContract.addGoldCoin(_address, goldCoin);
	}
	
	function getEquipmentTypeRarityListByRarityId(uint _rarityId) public view returns (uint[] memory equipmentTypeList_)
	{
	    equipmentTypeList_ = equipmentTypeRarityList[_rarityId];
	}
	
	function addEquipmentTypeToEquipmentTypeRarityList(uint _equipmentTypeId, uint _rarityId) public adminOnly returns (uint index_) 
	{
	    equipmentTypeRarityList[_rarityId].push(_equipmentTypeId);
	    index_ = equipmentTypeRarityList[_rarityId].length - 1;
	}
	
	function updateEquipmentTypeByRarity(uint _rarityId, uint _indexToUpdate, uint _equipmentTypeId) public adminOnly {
	    equipmentTypeRarityList[_rarityId][_indexToUpdate] = _equipmentTypeId;
	}
	
	//Proxy Method
	function addGoldCoin(address _address, uint _amount) public adminOnly
	{
	    motomoPetStorageContract.addGoldCoin(_address, _amount);
	}
	
	function getGoldCoin(address _address) public view returns (uint amount_) 
	{
	    amount_ = motomoPetStorageContract.getGoldCoin(_address);
	}
   
    function setLevelUpReward(uint _rewardAmount) public adminOnly
    {
        motomoPetStorageContract.setLevelUpReward(_rewardAmount);
    }
    
    function getLevelUpReward() public view returns (uint rewardAmount_) 
    {
        rewardAmount_ = motomoPetStorageContract.getLevelUpReward();
    }
    
    function updatePetLevel(address _address, uint _petId, uint _newPetLevel, uint _newExperience) public adminOnly 
    {
        motomoPetStorageContract.updatePetLevel(_address, _petId, _newPetLevel, _newExperience);
    }
    
    function getUserEquipmentList(address _address) public view returns (uint[] memory equipmentList_) 
    {
        equipmentList_ = motomoPetStorageContract.getUserEquipmentList(_address);
    }
    
    function getUserPetList(address _address) public view returns (uint[] memory petLists_) 
    {
        petLists_ = motomoPetStorageContract.getUserPetList(_address);
    }
    
    function addPet(address _address, uint _petId, uint _petTypeId) public adminOnly
    {
        motomoPetStorageContract.addPet(_address, _petId, _petTypeId);
    }
    
    function getPetById(address _address, uint _id) public view returns (uint petId_, uint petTypeId_, uint experience_, uint petLevel_) 
    {
        (uint petId, uint petTypeId, uint experience, uint petLevel) = motomoPetStorageContract.getPetById(_address, _id);
        petId_ = petId;
        petTypeId_ = petTypeId;
        experience_ = experience;
        petLevel_ = petLevel;
    }
    
    function getEquipmentById(address _address, uint _id) public view returns (uint equipmentId_, uint equipmentTypeId_, uint rarityId_, bool recycled_) 
    {
        (uint equipmentId, uint equipmentTypeId, uint rarityId, bool recycled) = motomoPetStorageContract.getEquipmentById(_address, _id);
        equipmentId_ = equipmentId;
        equipmentTypeId_ = equipmentTypeId;
        rarityId_ = rarityId;
        recycled_ = recycled;
    }
}