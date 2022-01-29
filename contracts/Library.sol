// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Library is Ownable {
    uint public bookCount = 0;

    struct Book {
        uint id;
        uint copies;
        uint borrowedCopies;
        address[] borrowers;
    }

    mapping (uint => Book) public books;
    
    event BookAdded(uint id, uint copies);
    event BookBorrowed(uint id, address borrower);
    event BookReturned(uint id, address borrower);

    modifier bookBorrowed(uint bookId) {
        bool borrowed = false;

        for (uint i = 0; i < books[bookId].borrowers.length; i++) {
            if (books[bookId].borrowers[i] == msg.sender) {
                borrowed = true;
                break;
            }
        }

        if (borrowed) {
            _;
        }
    }

    function removeSenderAddress(uint bookId) private {
        for (uint i = 0; i < books[bookId].borrowers.length; i++) {
            if (books[bookId].borrowers[i] == msg.sender) {
                uint length = books[bookId].borrowers.length;
                books[bookId].borrowers[i] = books[bookId].borrowers[length - 1];
                books[bookId].borrowers.pop();
                break;
            }
        }
    }

    function addBook(uint copies) public onlyOwner {
        books[bookCount].copies = copies;
        books[bookCount].borrowedCopies = 0;
        bookCount++;

        emit BookAdded(bookCount - 1, copies);
    }

    function getAvailableBooks() public view returns(Book[] memory) {
        Book[] memory availableBooks = new Book[](bookCount);
        uint currIdx = 0;
        for (uint i = 0; i < bookCount; i++) {
            if (books[i].borrowedCopies < books[i].copies) {
                availableBooks[currIdx] = books[i];
                currIdx++;
            }
        }
        return availableBooks;
    }

    function getBookBorrowers(uint bookId) public view returns(address[] memory) {
        require(bookId >= 0 && bookId < bookCount);

        return books[bookId].borrowers;
    }

    function borrowBook(uint bookId) public {
        require(bookId >= 0 && bookId < bookCount);
        require(books[bookId].borrowedCopies < books[bookId].copies);

        books[bookId].borrowers.push(msg.sender);
        books[bookId].borrowedCopies++;
        
        emit BookBorrowed(bookId, msg.sender);
    }

    function returnBook(uint bookId) public bookBorrowed(bookId) {
        require(bookId >= 0 && bookId < bookCount);

        removeSenderAddress(bookId);
        books[bookId].borrowedCopies--;
        
        emit BookReturned(bookId, msg.sender);
    }
}