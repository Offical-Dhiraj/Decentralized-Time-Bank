// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DecentralizedTimeBank {
    
    struct User {
        address userAddress;
        uint256 timeBalance;
        uint256 reputation;
        bool isActive;
        string[] skills;
    }
    
    struct ServiceRequest {
        uint256 requestId;
        address requester;
        address provider;
        string serviceDescription;
        uint256 timeRequired;
        uint256 timeOffered;
        bool isCompleted;
        bool isActive;
        uint256 timestamp;
    }
    
    mapping(address => User) public users;
    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(address => uint256[]) public userRequests;
    
    uint256 public nextRequestId = 1;
    uint256 public constant INITIAL_TIME_BALANCE = 10; // 10 hours for new users
    
    event UserRegistered(address indexed user, uint256 initialBalance);
    event ServiceRequestCreated(uint256 indexed requestId, address indexed requester, uint256 timeRequired);
    event ServiceCompleted(uint256 indexed requestId, address indexed provider, uint256 timeExchanged);
    event TimeTransferred(address indexed from, address indexed to, uint256 amount);
    event ServiceRequestCancelled(uint256 indexed requestId, address indexed requester);
    
    modifier onlyActiveUser() {
        require(users[msg.sender].isActive, "User not registered or inactive");
        _;
    }
    
    modifier onlyValidRequest(uint256 _requestId) {
        require(_requestId > 0 && _requestId < nextRequestId, "Invalid request ID");
        require(serviceRequests[_requestId].isActive, "Request not active");
        _;
    }
    
    function registerUser(string[] memory _skills) external {
        require(!users[msg.sender].isActive, "User already registered");
        
        users[msg.sender] = User({
            userAddress: msg.sender,
            timeBalance: INITIAL_TIME_BALANCE,
            reputation: 100, // Starting reputation
            isActive: true,
            skills: _skills
        });
        
        emit UserRegistered(msg.sender, INITIAL_TIME_BALANCE);
    }
    
    function createServiceRequest(
        string memory _serviceDescription, 
        uint256 _timeRequired, 
        uint256 _timeOffered
    ) external onlyActiveUser returns (uint256) {
        require(_timeRequired > 0, "Time required must be greater than 0");
        require(_timeOffered > 0, "Time offered must be greater than 0");
        require(users[msg.sender].timeBalance >= _timeOffered, "Insufficient time balance");
        
        uint256 requestId = nextRequestId++;
        
        serviceRequests[requestId] = ServiceRequest({
            requestId: requestId,
            requester: msg.sender,
            provider: address(0),
            serviceDescription: _serviceDescription,
            timeRequired: _timeRequired,
            timeOffered: _timeOffered,
            isCompleted: false,
            isActive: true,
            timestamp: block.timestamp
        });
        
        userRequests[msg.sender].push(requestId);
        
        emit ServiceRequestCreated(requestId, msg.sender, _timeRequired);
        return requestId;
    }
    
    function acceptServiceRequest(uint256 _requestId) external onlyActiveUser onlyValidRequest(_requestId) {
        ServiceRequest storage request = serviceRequests[_requestId];
        require(request.requester != msg.sender, "Cannot accept own request");
        require(request.provider == address(0), "Request already accepted");
        
        request.provider = msg.sender;
        userRequests[msg.sender].push(_requestId);
    }
    
    function completeService(uint256 _requestId) external onlyValidRequest(_requestId) {
        ServiceRequest storage request = serviceRequests[_requestId];
        require(request.provider == msg.sender, "Only provider can complete service");
        require(!request.isCompleted, "Service already completed");
        
        // Transfer time from requester to provider
        users[request.requester].timeBalance -= request.timeOffered;
        users[request.provider].timeBalance += request.timeOffered;
        
        // Update reputation
        users[request.provider].reputation += 5;
        
        request.isCompleted = true;
        request.isActive = false;
        
        emit ServiceCompleted(_requestId, request.provider, request.timeOffered);
        emit TimeTransferred(request.requester, request.provider, request.timeOffered);
    }

    function cancelServiceRequest(uint256 _requestId) external onlyActiveUser onlyValidRequest(_requestId) {
        ServiceRequest storage request = serviceRequests[_requestId];
        require(request.requester == msg.sender, "Only requester can cancel");
        require(request.provider == address(0), "Cannot cancel after request is accepted");
        require(!request.isCompleted, "Cannot cancel completed request");

        request.isActive = false;

        emit ServiceRequestCancelled(_requestId, msg.sender);
    }
    
    function getUserProfile(address _user) external view returns (
        uint256 timeBalance,
        uint256 reputation,
        bool isActive,
        string[] memory skills
    ) {
        User storage user = users[_user];
        return (user.timeBalance, user.reputation, user.isActive, user.skills);
    }
    
    function getActiveRequests() external view returns (uint256[] memory) {
        uint256[] memory activeRequests = new uint256[](nextRequestId - 1);
        uint256 count = 0;
        
        for (uint256 i = 1; i < nextRequestId; i++) {
            if (serviceRequests[i].isActive && serviceRequests[i].provider == address(0)) {
                activeRequests[count] = i;
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeRequests[i];
        }
        
        return result;
    }
}
