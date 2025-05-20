// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Bank {
    // 存款记录
    mapping(address => uint256) public deposits;
    
    // 链表节点
    struct Node {
        address user;
        uint256 amount;
        address next;
    }
    
    // 链表头
    address public head;
    
    // 地址到节点的映射
    mapping(address => Node) public nodes;
    
    // 存款事件
    event Deposited(address indexed user, uint256 amount);
    
    // 接收ETH存款
    receive() external payable {
        deposit();
    }
    
    // 存款函数
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新存款总额
        deposits[msg.sender] += msg.value;
        
        // 更新前10名链表
        updateTopList(msg.sender, deposits[msg.sender]);
        
        emit Deposited(msg.sender, msg.value);
    }
    
    // 更新前10名链表
    function updateTopList(address _user, uint256 _amount) private {
        // 如果用户已在链表中
        if (nodes[_user].user != address(0)) {
            // 从链表中移除
            removeFromList(_user);
        }
        
        // 插入到合适位置
        insertToList(_user, _amount);
        
        // 如果链表超过10个节点，移除最后一个
        if (getListLength() > 10) {
            removeLastFromList();
        }
    }
    
    // 从链表中移除节点
    function removeFromList(address _user) private {
        Node storage node = nodes[_user];
        
        // 如果是头节点
        if (head == _user) {
            head = node.next;
        } else {
            // 找到前驱节点
            address prev = head;
            while (nodes[prev].next != _user) {
                prev = nodes[prev].next;
            }
            nodes[prev].next = node.next;
        }
        
        delete nodes[_user];
    }
    
    // 插入到链表
    function insertToList(address _user, uint256 _amount) private {
        // 如果链表为空
        if (head == address(0)) {
            head = _user;
            nodes[_user] = Node(_user, _amount, address(0));
            return;
        }
        
        // 如果新金额大于头节点
        if (_amount > nodes[head].amount) {
            nodes[_user] = Node(_user, _amount, head);
            head = _user;
            return;
        }
        
        // 找到插入位置
        address current = head;
        while (nodes[current].next != address(0) && _amount <= nodes[nodes[current].next].amount) {
            current = nodes[current].next;
        }
        
        nodes[_user] = Node(_user, _amount, nodes[current].next);
        nodes[current].next = _user;
    }
    
    // 移除链表最后一个节点
    function removeLastFromList() private {
        if (head == address(0)) return;
        
        address current = head;
        address prev = address(0);
        
        while (nodes[current].next != address(0)) {
            prev = current;
            current = nodes[current].next;
        }
        
        if (prev == address(0)) {
            head = address(0);
        } else {
            nodes[prev].next = address(0);
        }
        
        delete nodes[current];
    }
    
    // 获取链表长度
    function getListLength() public view returns (uint256) {
        uint256 length = 0;
        address current = head;
        
        while (current != address(0)) {
            length++;
            current = nodes[current].next;
        }
        
        return length;
    }
    
    // 获取前10名存款用户
    function getTopDepositors() public view returns (address[] memory, uint256[] memory) {
        uint256 length = getListLength();
        address[] memory users = new address[](length);
        uint256[] memory amounts = new uint256[](length);
        
        address current = head;
        for (uint256 i = 0; i < length; i++) {
            users[i] = nodes[current].user;
            amounts[i] = nodes[current].amount;
            current = nodes[current].next;
        }
        
        return (users, amounts);
    }
}
