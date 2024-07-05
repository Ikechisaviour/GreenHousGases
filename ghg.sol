// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
contract ghg{

    struct company{
        string name;
        uint addition;
        uint subtraction;
        uint netEmission;
        bool aboveZero;
        address county;
        
    }

    struct county{
        string name;
        uint addition;
        uint subtraction;
        uint netEmission;
        bool aboveZero;
        
    }

    string public empty;
    uint buyAmount = 11;
    uint sellAmount = 9;

    mapping (address => company) companys;
    mapping (address => county) countys;
    mapping (address => string) used;

    function register(address _address, string memory _institution, string memory _name) external {
        bytes32 first = keccak256(abi.encodePacked(used[_address]));
        bytes32 second = keccak256(abi.encodePacked(empty));
        require(first == second, "address already registered");
        if(keccak256(abi.encodePacked(_institution)) == keccak256(abi.encodePacked("company"))){
            companys[_address].name = _name;
            used[_address] = "company";
        }else if(keccak256(abi.encodePacked(_institution)) == keccak256(abi.encodePacked("county"))){
            countys[_address].name = _name;
            used[_address] = "county";
        }
        
    }

    function companyUpdate(address _county, uint _ghgQty, bool _ghgadding) external {
        require(keccak256(abi.encodePacked(used[msg.sender])) == keccak256(abi.encodePacked("company")));
        if(_ghgadding == true){
        companys[msg.sender].addition = companys[msg.sender].addition + _ghgQty;
        countys[_county].addition = countys[_county].addition + _ghgQty;
        }else if(_ghgadding == false){
        companys[msg.sender].subtraction = companys[msg.sender].subtraction + _ghgQty;
        countys[_county].subtraction = countys[_county].subtraction + _ghgQty;
        }

        recalculateGhg(_county);
    }

    function recalculateGhg(address _county) private {
        if(companys[msg.sender].addition > companys[msg.sender].subtraction){
            companys[msg.sender].netEmission = companys[msg.sender].addition -companys[msg.sender].subtraction;
            companys[msg.sender].aboveZero = true;
            countys[_county].netEmission = companys[_county].addition -companys[_county].subtraction;
            countys[_county].aboveZero = true;
        }else if(companys[msg.sender].addition < companys[msg.sender].subtraction){
            companys[msg.sender].netEmission = companys[msg.sender].subtraction -companys[msg.sender].addition;
            companys[msg.sender].aboveZero = false;
            countys[_county].netEmission = companys[_county].subtraction -companys[_county].addition;
            countys[_county].aboveZero = false;
        }else {}
    }

    function payForEmission () payable external {
        require(buyAmount * companys[msg.sender].netEmission >= msg.value && companys[msg.sender].aboveZero == true, 
        "ghg emission is below zero or amount is more than you owe");
        uint removing =  msg.value/buyAmount;
        companys[msg.sender].subtraction + removing;
        address currentCounty = companys[msg.sender].county;
        countys[currentCounty].subtraction + removing;
        
        recalculateGhg(currentCounty);
        
    }
    
    function setBuyAmount(uint _amount) external {
        buyAmount = _amount;
    }

    function setSellAmount(uint _amount) external {
        sellAmount = _amount;
    }

    function getpaidForGHGRemoval () payable external {
        require(companys[msg.sender].aboveZero == true);
        address payable receiver = payable(msg.sender);
        receiver.transfer(companys[msg.sender].netEmission * sellAmount);
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
    
}
