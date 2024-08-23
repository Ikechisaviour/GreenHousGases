// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
pragma abicoder v2;

// pragma experimental ABIEncoderV2;

contract ghg{

    struct company{
        string name;
        uint addition;
        uint subtraction;
        uint paidToCompany;
        uint paidFromCompany;
        uint netEmission;
        bool aboveZero;
        address county;
        
    }

    struct county{
        string name;
        uint addition;
        uint subtraction;
        uint paidToCounty;
        uint paidFromCounty;
        uint netEmission;
        bool aboveZero;
        string [] companies;
        
    }

    uint public trace1;
    uint public trace2;

    address authority = msg.sender;

    string empty;
    uint buyAmount = 11;
    uint sellAmount = 9;

    mapping (address => company) companys;
    mapping (address => county) countys;
    mapping (address => string) used;
    mapping (string => bool) usedName;

    function countyRegister(address _address, string memory _name) external {
        //should only be called by the authority
        bytes32 first = keccak256(abi.encodePacked(used[_address]));
        bytes32 second = keccak256(abi.encodePacked(empty));
        //# require(msg.sender == authority, "You are not the authority in this smart contract");
        require(first == second, "address already registered");
        require(usedName[_name] == false, "this name has been used before");
            
        countys[_address].name = _name;
        used[_address] = "county";
        usedName[_name] = true;

    }

    function companyRegister(address _address, string memory _name) external {
        //should only be called by the county
        bytes32 first = keccak256(abi.encodePacked(used[_address]));
        bytes32 second = keccak256(abi.encodePacked(empty));
        // checkin if the string is empty or assigned an address
        require(keccak256(abi.encodePacked(used[msg.sender])) == keccak256(abi.encodePacked("county")), "You are not a county");
        require(first == second, "address already registered");
        require(usedName[_name] == false, "this name has been used before");
        companys[_address].name = _name;
        countys[msg.sender].companies.push(_name);
        companys[_address].county = msg.sender;
        used[_address] = "company";
        usedName[_name] = true;
    }

    function companyUpdate(uint _ghgQty, bool _ghgadding) external {
        //should only be called by a company
        require(keccak256(abi.encodePacked(used[msg.sender])) == keccak256(abi.encodePacked("company")), "the address is not a company");
        address currentCounty = companys[msg.sender].county;
        if(_ghgadding == true){
        companys[msg.sender].addition = companys[msg.sender].addition + _ghgQty;
        countys[currentCounty].addition = countys[currentCounty].addition + _ghgQty;
        }else if(_ghgadding == false){
        companys[msg.sender].subtraction = companys[msg.sender].subtraction + _ghgQty;
        countys[currentCounty].subtraction = countys[currentCounty].subtraction + _ghgQty;
        }

        recalculateGhg(currentCounty);
    }

    function recalculateGhg(address _county) private {
        if((companys[msg.sender].addition + companys[msg.sender].paidToCompany) >= (companys[msg.sender].subtraction + companys[msg.sender].paidFromCompany)){
            companys[msg.sender].netEmission = (companys[msg.sender].addition + companys[msg.sender].paidToCompany) - (companys[msg.sender].subtraction + companys[msg.sender].paidFromCompany);
            companys[msg.sender].aboveZero = true;
        }else if(companys[msg.sender].addition < companys[msg.sender].subtraction){
            companys[msg.sender].netEmission = (companys[msg.sender].subtraction + companys[msg.sender].paidFromCompany) - (companys[msg.sender].addition + companys[msg.sender].paidToCompany);
            companys[msg.sender].aboveZero = false;
        }else {}

        if((countys[_county].addition + countys[_county].paidToCounty) > (countys[_county].subtraction + countys[_county].paidFromCounty)){            
            countys[_county].netEmission = (countys[_county].addition + countys[_county].paidToCounty) - (countys[_county].subtraction + countys[_county].paidFromCounty);
            countys[_county].aboveZero = true;
        }else if((countys[_county].addition + countys[_county].paidToCounty) < (countys[_county].subtraction + countys[_county].paidFromCounty)){            
            countys[_county].netEmission = (countys[_county].subtraction + countys[_county].paidFromCounty) - (countys[_county].addition + countys[_county].paidToCounty);
            countys[_county].aboveZero = false;
        }else {}
    }

    function payForEmission () payable external {
        //should only be called by a company
        require(buyAmount * companys[msg.sender].netEmission >= msg.value && companys[msg.sender].aboveZero == true, 
        "ghg emission is below zero or amount is more than you owe");
        uint removing =  msg.value/buyAmount;
        companys[msg.sender].paidFromCompany = companys[msg.sender].paidFromCompany + removing;
        address currentCounty = companys[msg.sender].county;     
        countys[currentCounty].paidFromCounty = countys[currentCounty].paidFromCounty + removing;
        recalculateGhg(currentCounty);
    }
    
    function setBuyAmount(uint _amount) external {
        //should be called by the authority
        buyAmount = _amount;
    }

    function setSellAmount(uint _amount) external {
        //should be called by the authority
        sellAmount = _amount;
    }

    function getpaidForGHGRemoval () payable external {
        //should be called by a company
        require(companys[msg.sender].aboveZero == false, "");
        address payable receiver = payable(msg.sender);
        receiver.transfer(companys[msg.sender].netEmission * sellAmount);
        companys[msg.sender].paidToCompany = companys[msg.sender].paidToCompany + companys[msg.sender].netEmission;
        companys[msg.sender].netEmission = 0;
    }

    function viewTotalEmission (address _address) public view returns(string memory, uint, bool){
        uint myReturnN;
        bool myReturnB;
        if (keccak256(abi.encodePacked(used[_address])) == keccak256(abi.encodePacked("company"))){
            myReturnN = companys[_address].netEmission;
            myReturnB = companys[_address].aboveZero;
        }else if (keccak256(abi.encodePacked(used[_address])) == keccak256(abi.encodePacked("county"))){
            myReturnN = countys[_address].netEmission;
            myReturnB = countys[_address].aboveZero;

        }
        return(used[_address], myReturnN, myReturnB);
    }

    function viewinfo (address _address) public view returns(string memory, string memory){
        string memory myNameReturn;
        if (keccak256(abi.encodePacked(used[_address])) == keccak256(abi.encodePacked("company"))){
            myNameReturn = companys[_address].name;          
        }else if (keccak256(abi.encodePacked(used[_address])) == keccak256(abi.encodePacked("county"))){
            myNameReturn = countys[_address].name;

        }
        return(used[_address], myNameReturn);
    }

    function viewSellPrice () external view returns(uint){
        return sellAmount;
    }

    function viewBuyPrice () external view returns(uint){
        return buyAmount;
    }

    function viewCompanyDetail() external view returns(company memory){
        return(companys[msg.sender]);
    }

    function viewCountyDetail() external view returns(county memory){
        return(countys[msg.sender]);
    }

    function viewCompanyCountyName(address _address) external view returns(string memory){
        return(countys[companys[_address].county].name);
    }
      
    receive() external payable{}

}
