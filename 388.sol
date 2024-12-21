// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationalRPG {
    // Struct for players
    struct Player {
        uint id;
        string name;
        uint experience;
        uint level;
        uint tokens;
        uint achievements;
        address playerAddress;
    }

    // Struct for educational tasks
    struct Task {
        uint id;
        string question;
        string answer;
        uint experienceReward;
        uint tokenReward;
        bool isCompleted;
    }

    // Struct for achievements
    struct Achievement {
        uint id;
        string title;
        string description;
        uint requiredLevel;
        uint rewardTokens;
    }

    // Struct for items
    struct Item {
        uint id;
        string name;
        string description;
        uint price;
    }

    // Mappings for players, tasks, achievements, and items
    mapping(address => Player) public players;
    mapping(uint => Task) public tasks;
    mapping(uint => Achievement) public achievements;
    mapping(uint => Item) public items;

    // Arrays for task, player, achievement, and item storage
    address[] public playerAddresses;
    uint[] public taskIds;
    uint[] public achievementIds;
    uint[] public itemIds;

    // Counters for player, task, achievement, and item IDs
    uint public playerCount;
    uint public taskCount;
    uint public achievementCount;
    uint public itemCount;

    // Admin address
    address public admin;

    // Events
    event PlayerRegistered(uint id, string name, address playerAddress);
    event TaskCreated(uint id, string question, uint experienceReward, uint tokenReward);
    event TaskCompleted(uint taskId, address playerAddress, uint experienceEarned, uint tokensEarned);
    event PlayerLeveledUp(address playerAddress, uint newLevel);
    event TokensRedeemed(address playerAddress, uint amount);
    event AchievementUnlocked(address playerAddress, uint achievementId, string title);
    event ItemPurchased(address playerAddress, uint itemId, string itemName);
    event ItemCreated(uint id, string name, string description, uint price);

    // Constructor to set admin
    constructor() {
        admin = msg.sender;
    }

    // Modifier for admin-only functions
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Register a new player
    function registerPlayer(string memory _name) public {
        require(bytes(_name).length > 0, "Player name cannot be empty");
        require(players[msg.sender].id == 0, "Player already registered");

        playerCount++;
        players[msg.sender] = Player(playerCount, _name, 0, 1, 0, 0, msg.sender);
        playerAddresses.push(msg.sender);

        emit PlayerRegistered(playerCount, _name, msg.sender);
    }

    // Create a new educational task (only admin)
    function createTask(string memory _question, string memory _answer, uint _experienceReward, uint _tokenReward) public onlyAdmin {
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(bytes(_answer).length > 0, "Answer cannot be empty");
        require(_experienceReward > 0, "Experience reward must be greater than 0");
        require(_tokenReward > 0, "Token reward must be greater than 0");

        taskCount++;
        tasks[taskCount] = Task(taskCount, _question, _answer, _experienceReward, _tokenReward, false);
        taskIds.push(taskCount);

        emit TaskCreated(taskCount, _question, _experienceReward, _tokenReward);
    }

    // Create a new achievement (only admin)
    function createAchievement(string memory _title, string memory _description, uint _requiredLevel, uint _rewardTokens) public onlyAdmin {
        require(bytes(_title).length > 0, "Achievement title cannot be empty");
        require(bytes(_description).length > 0, "Achievement description cannot be empty");
        require(_requiredLevel > 0, "Required level must be greater than 0");
        require(_rewardTokens > 0, "Reward tokens must be greater than 0");

        achievementCount++;
        achievements[achievementCount] = Achievement(achievementCount, _title, _description, _requiredLevel, _rewardTokens);
        achievementIds.push(achievementCount);
    }

    // Create a new item (only admin)
    function createItem(string memory _name, string memory _description, uint _price) public onlyAdmin {
        require(bytes(_name).length > 0, "Item name cannot be empty");
        require(bytes(_description).length > 0, "Item description cannot be empty");
        require(_price > 0, "Item price must be greater than 0");

        itemCount++;
        items[itemCount] = Item(itemCount, _name, _description, _price);
        itemIds.push(itemCount);

        emit ItemCreated(itemCount, _name, _description, _price);
    }

    // Complete a task by answering the question
    function completeTask(uint _taskId, string memory _answer) public {
        require(players[msg.sender].id != 0, "Player is not registered");
        require(_taskId > 0 && _taskId <= taskCount, "Invalid task ID");

        Task storage task = tasks[_taskId];
        require(!task.isCompleted, "Task is already completed");
        require(keccak256(abi.encodePacked(task.answer)) == keccak256(abi.encodePacked(_answer)), "Incorrect answer");

        task.isCompleted = true;

        Player storage player = players[msg.sender];
        player.experience += task.experienceReward;
        player.tokens += task.tokenReward;

        // Level up logic
        while (player.experience >= player.level * 100) {
            player.level++;
            emit PlayerLeveledUp(msg.sender, player.level);
        }

        emit TaskCompleted(_taskId, msg.sender, task.experienceReward, task.tokenReward);
    }

    // Redeem tokens for rewards
    function redeemTokens(uint _amount) public {
        require(players[msg.sender].id != 0, "Player is not registered");
        Player storage player = players[msg.sender];
        require(player.tokens >= _amount, "Insufficient tokens");

        player.tokens -= _amount;

        emit TokensRedeemed(msg.sender, _amount);
    }

    // Purchase an item
    function purchaseItem(uint _itemId) public {
        require(players[msg.sender].id != 0, "Player is not registered");
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");

        Player storage player = players[msg.sender];
        Item storage item = items[_itemId];

        require(player.tokens >= item.price, "Insufficient tokens to purchase item");

        player.tokens -= item.price;

        emit ItemPurchased(msg.sender, _itemId, item.name);
    }

    // Unlock achievements based on level
    function unlockAchievements() public {
        require(players[msg.sender].id != 0, "Player is not registered");
        Player storage player = players[msg.sender];

        for (uint i = 0; i < achievementIds.length; i++) {
            Achievement storage achievement = achievements[achievementIds[i]];
            if (player.level >= achievement.requiredLevel) {
                player.achievements++;
                player.tokens += achievement.rewardTokens;
                emit AchievementUnlocked(msg.sender, achievement.id, achievement.title);
            }
        }
    }

    // Get all registered players
    function getAllPlayers() public view returns (Player[] memory) {
        Player[] memory allPlayers = new Player[](playerAddresses.length);
        for (uint i = 0; i < playerAddresses.length; i++) {
            allPlayers[i] = players[playerAddresses[i]];
        }
        return allPlayers;
    }

    // Get all tasks
    function getAllTasks() public view returns (Task[] memory) {
        Task[] memory allTasks = new Task[](taskIds.length);
        for (uint i = 0; i < taskIds.length; i++) {
            allTasks[i] = tasks[taskIds[i]];
        }
        return allTasks;
    }

    // Get all achievements
    function getAllAchievements() public view returns (Achievement[] memory) {
        Achievement[] memory allAchievements = new Achievement[](achievementIds.length);
        for (uint i = 0; i < achievementIds.length; i++) {
            allAchievements[i] = achievements[achievementIds[i]];
        }
        return allAchievements;
    }

    // Get all items
    function getAllItems() public view returns (Item[] memory) {
        Item[] memory allItems = new Item[](itemIds.length);
        for (uint i = 0; i < itemIds.length; i++) {
            allItems[i] = items[itemIds[i]];
        }
        return allItems;
    }

    // Get player details
    function getPlayerDetails(address _playerAddress) public view returns (Player memory) {
        require(players[_playerAddress].id != 0, "Player is not registered");
        return players[_playerAddress];
    }

    // Get task details
    function getTaskDetails(uint _taskId) public view returns (Task memory) {
        require(_taskId > 0 && _taskId <= taskCount, "Invalid task ID");
        return tasks[_taskId];
    }

    // Get achievement details
    function getAchievementDetails(uint _achievementId) public view returns (Achievement memory) {
        require(_achievementId > 0 && _achievementId <= achievementCount, "Invalid achievement ID");
        return achievements[_achievementId];
    }

    // Get item details
    function getItemDetails(uint _itemId) public view returns (Item memory) {
        require(_itemId > 0 && _itemId <= itemCount, "Invalid item ID");
        return items[_itemId];
    }
}
