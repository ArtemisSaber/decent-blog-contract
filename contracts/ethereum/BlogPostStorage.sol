// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlogStorage is Ownable {
    struct Post {
        uint64 id;
        string title;
        string content;
        string cardBg;
        uint64 timestamp;
        string banner;
        address authorAddress;
        bool visible;
    }
    struct Author {
        string name;
        bool active;
        string avatar;
        address authorAddress;
    }
    event SendId(uint64 _id);
    mapping(address => uint64) ownerPostCount;
    mapping(uint64 => address) postToOwner;
    mapping(uint64 => address) authorToAddress;
    mapping(address => bool) authorActive;
    mapping(address => uint64) addressToAuthor;
    mapping(address => uint64) addressAuthorCount;
    Post[] private posts;
    Author[] private authors;
    address private _owner;
    uint256 private donateAmount;

    constructor() {
        _owner = msg.sender;
        donateAmount = 0.01 ether;
    }

    function postBlog(
        string memory title,
        string memory content,
        string memory banner,
        string memory cardBg
    ) public returns (uint64) {
        require(
            addressAuthorCount[msg.sender] > 0,
            "You must be an author to post"
        );
        require(authorActive[msg.sender], "Your account has been deactivated");
        uint64 timestamp = uint64(block.timestamp);
        Post memory post = Post({
            id: uint64(posts.length),
            title: title,
            content: content,
            timestamp: timestamp,
            banner: banner,
            authorAddress: msg.sender,
            visible: true,
            cardBg: cardBg
        });
        posts.push(post);
        uint64 id = uint64(posts.length - 1);
        postToOwner[id] = msg.sender;
        ownerPostCount[msg.sender] = ownerPostCount[msg.sender] + 1;
        emit SendId(id);
        return id;
    }

    function changeDonateAmount(uint256 newAmount) public onlyOwner {
        donateAmount = newAmount;
    }

    function getDonateAmount() public view returns (uint256) {
        return donateAmount;
    }

    function hidePost(uint64 id) public returns (bool) {
        require(
            postToOwner[id] == msg.sender,
            "You are not the author of this post"
        );
        posts[id].visible = false;
        return true;
    }

    function showPost(uint64 id) public returns (bool) {
        require(
            postToOwner[id] == msg.sender,
            "You are not the author of this post"
        );
        posts[id].visible = true;
        return true;
    }

    function addAuthor(string memory name, string memory avatar)
        public
        payable
        returns (uint64)
    {
        require(
            addressAuthorCount[msg.sender] == 0,
            "You can only add one author per address"
        );
        require(
            msg.value == donateAmount,
            "Please donate to support the development of this project"
        );
        Author memory author = Author({
            name: name,
            avatar: avatar,
            authorAddress: msg.sender,
            active: true
        });
        authors.push(author);
        uint64 id = uint64(authors.length - 1);
        authorToAddress[id] = msg.sender;
        addressToAuthor[msg.sender] = id;
        addressAuthorCount[msg.sender] = addressAuthorCount[msg.sender] + 1;
        authorActive[msg.sender] = true;
        emit SendId(id);
        return id;
    }

    function changeAvatar(uint64 id, string memory avatar)
        public
        returns (bool)
    {
        require(
            authorToAddress[id] == msg.sender,
            "You must be the author you are trying to change"
        );
        authors[id].avatar = avatar;
        return true;
    }

    function changeNickName(uint64 id, string memory name)
        public
        returns (bool)
    {
        require(
            authorToAddress[id] == msg.sender,
            "You must be the author you are trying to change"
        );
        authors[id].name = name;
        return true;
    }

    function deactivateAuthor() public returns (bool) {
        require(
            addressAuthorCount[msg.sender] > 0,
            "You must be an author to deactivate"
        );
        uint64 id = addressToAuthor[msg.sender];
        authors[id].active = false;
        authorActive[msg.sender] = false;
        return true;
    }

    function activateAuthor(address authorAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(
            addressAuthorCount[authorAddress] > 0,
            "You must be an author to activate"
        );
        uint64 id = addressToAuthor[authorAddress];
        authors[id].active = true;
        authorActive[authorAddress] = true;
        return true;
    }

    function getAuthor(address authorAddress)
        public
        view
        returns (Author memory)
    {
        require(addressAuthorCount[authorAddress] > 0, "Author does not exist");
        uint64 id = addressToAuthor[authorAddress];
        return authors[id];
    }

    function getPost(uint64 _id) public view returns (Post memory) {
        require(posts[_id].visible, "Post is hidden");
        return posts[_id];
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getPostList(
        uint256 pageSize,
        uint256 currentPage,
        uint256 skipped
    )
        public
        view
        returns (
            Post[] memory,
            uint256[] memory,
            uint256,
            uint256
        )
    {
        uint256 start = currentPage * pageSize;
        uint256 end = start + pageSize;
        uint256 length = posts.length;
        if (end > length) {
            end = length;
        }
        Post[] memory postList = new Post[](end - start);
        uint256[] memory postIdList = new uint256[](end - start);
        for (uint256 i = start; i < end; i++) {
            if (posts[i].visible) {
                if (i + skipped < posts.length) {
                    postList[i - start] = posts[i + skipped];
                    postIdList[i - start] = i + skipped;
                } else {
                    break;
                }
            } else {
                skipped = skipped + 1;
            }
        }
        return (postList, postIdList, skipped, posts.length);
    }

    function withdraw() external onlyOwner {
        address payable owner = payable(_owner);
        owner.transfer(address(this).balance);
    }
}
