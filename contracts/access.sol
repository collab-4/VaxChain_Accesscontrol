// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Transit is Ownable, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor() Ownable() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    enum transitStatus {
        PENDING,
        IN_TRANSIT,
        RECEIVED,
        RECEIVED_FINAL,
        TAMPERED
    }

    event Tampered(address indexed sender, string message);

    struct Details {
        address sender;
        address receiver;
        uint pickupTime;
        uint deliveryTime;
        transitStatus status;
    }

    mapping(uint => Details) public transits;
    mapping(address => uint[]) public transitIdsByAddress;
    function registerManager(address manager) public onlyOwner {
        grantRole(MANAGER_ROLE, manager);
    }

    function removeManager(address manager) public onlyOwner {
        revokeRole(MANAGER_ROLE, manager);
    }

    function checkManager(
        address manager
    ) public view onlyOwner returns (bool) {
        return hasRole(MANAGER_ROLE, manager);
    }
    function createTransit(uint _transitId, address _sender, address _receiver) external {
        transits[_transitId] = Details(_sender, _receiver, 0, 0, transitStatus.PENDING);
        transitIdsByAddress[_sender].push(_transitId);
        transitIdsByAddress[_receiver].push(_transitId);
    }

    function startTransit(uint _transitId, address _receiver) external {
        Details storage detail = transits[_transitId];
        require(detail.sender == msg.sender && detail.receiver == _receiver, "Invalid sender or receiver");
        require(detail.status == transitStatus.PENDING, "Invalid transit status");
        detail.status = transitStatus.IN_TRANSIT;
        detail.pickupTime = block.timestamp;
    }

    function receiveTransit(uint _transitId, address _sender) external {
        Details storage detail = transits[_transitId];
        require(detail.sender == _sender && detail.receiver == msg.sender, "Invalid sender or receiver");
        require(detail.status == transitStatus.IN_TRANSIT, "Invalid transit status");
        detail.status = transitStatus.RECEIVED;
        detail.deliveryTime = block.timestamp;
    }

    function getTransitsByAddress(address _address) public view returns (Details[] memory) {
        uint[] memory transitIds = transitIdsByAddress[_address];
        Details[] memory result = new Details[](transitIds.length);
        
        for (uint i = 0; i < transitIds.length; i++) {
            result[i] = transits[transitIds[i]];
        }
        
        return result;
    }

    function tempTampered(uint _transitID) external {
        Details storage detail = transits[_transitID];
        require(detail.status == transitStatus.IN_TRANSIT || detail.status == transitStatus.RECEIVED);
        detail.status = transitStatus.TAMPERED;
        emit Tampered(msg.sender, "TAMPERED");
    }

    function getTransitbyID(uint _transitID) public view returns (Details memory) {
        Details storage detail = transits[_transitID];
        return detail;
    }
}
