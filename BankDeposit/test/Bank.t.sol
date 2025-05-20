// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address[] public users;
    
    function setUp() public {
        bank = new Bank();
        
        // 创建10个测试用户
        users = new address[](10);
        for (uint i = 0; i < 10; i++) {
            users[i] = address(uint160(uint(keccak256(abi.encodePacked(i)))));
        }
    }
    
    // 测试1: 可以通过钱包直接存款
    function testDirectDeposit() public {
        uint256 depositAmount = 1 ether;
        
        // 用户0直接转账
        vm.deal(users[0], depositAmount);
        vm.prank(users[0]);
        (bool success, ) = address(bank).call{value: depositAmount}("");
        
        assertTrue(success);
        assertEq(bank.deposits(users[0]), depositAmount);
    }
    
    // 测试2: 记录每个地址的存款金额
    function testDepositRecording() public {
        uint256 depositAmount = 1 ether;
        
        // 用户0存款
        vm.deal(users[0], depositAmount);
        vm.prank(users[0]);
        bank.deposit{value: depositAmount}();
        
        // 用户1存款
        vm.deal(users[1], depositAmount * 2);
        vm.prank(users[1]);
        bank.deposit{value: depositAmount * 2}();
        
        assertEq(bank.deposits(users[0]), depositAmount);
        assertEq(bank.deposits(users[1]), depositAmount * 2);
    }
    
    // 测试3: 前10名用户链表
    function testTop10List() public {
        // 存款金额从大到小
        uint256[] memory amounts = new uint256[](10);
        amounts[0] = 10 ether;
        amounts[1] = 9 ether;
        amounts[2] = 8 ether;
        amounts[3] = 7 ether;
        amounts[4] = 6 ether;
        amounts[5] = 5 ether;
        amounts[6] = 4 ether;
        amounts[7] = 3 ether;
        amounts[8] = 2 ether;
        amounts[9] = 1 ether;
        
        // 按顺序存款
        for (uint i = 0; i < 10; i++) {
            vm.deal(users[i], amounts[i]);
            vm.prank(users[i]);
            bank.deposit{value: amounts[i]}();
        }
        
        // 获取前10名
        (address[] memory topUsers, uint256[] memory topAmounts) = bank.getTopDepositors();
        
        // 验证前10名
        assertEq(topUsers.length, 10);
        for (uint i = 0; i < 10; i++) {
            assertEq(topUsers[i], users[i]);
            assertEq(topAmounts[i], amounts[i]);
        }
        
        // 测试超过10名的情况
        address newUser = address(0x123);
        vm.deal(newUser, 5.5 ether);
        vm.prank(newUser);
        bank.deposit{value: 5.5 ether}();
        
        (topUsers, topAmounts) = bank.getTopDepositors();
        
        // 新用户应该排在第6位
        assertEq(topUsers[5], newUser);
        assertEq(topAmounts[5], 5.5 ether);
        // 原来的第10名(1 ether)应该被移除
        assertEq(topUsers.length, 10);
        assertEq(topAmounts[9], 2 ether); // 原来的第9名现在应该是第10名
    }
}
