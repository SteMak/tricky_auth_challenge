// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract TrickyAuth {
  address admin;
  mapping(bytes32 => address) authKeyToUser;

  modifier onlyAdmin() {
    require(admin == msg.sender, NotAdmin());
    _;
  }

  modifier onlyRegistered(bytes32 key) {
    require(authKeyToUser[key] == tx.origin, NotRegistered());
    _;
  }

  struct Proposal {
    address user;
    bytes32 key;
  }

  error NotAdmin();
  error NotRegistered();

  event Register(address user, bytes32 key);
  event RegisterMe(address user, bytes32 key);
  event Claim(address user);

  constructor() payable {
    admin = msg.sender;
  }

  // Anyone can propose a key for the admin to accept
  function proposeKey(bytes32 key) external {
    Proposal storage proposal;
    assembly {
      mstore(0x00, origin())
      mstore(0x20, key)
      proposal.slot := keccak256(0x00, 0x40)
    }
    proposal.user = tx.origin;
    proposal.key = key;
    emit RegisterMe(tx.origin, key);
  }

  // Admin accepts the key to allow the claim
  function register(bytes32 storageKey) external onlyAdmin {
    Proposal storage proposal;
    assembly {
      proposal.slot := storageKey
    }
    authKeyToUser[proposal.key] = proposal.user;
    emit Register(proposal.user, proposal.key);
  }

  // Create2 opcode protects from double distribution
  function claim(bytes32 key) external onlyRegistered(key) {
    new Destructive{ salt: bytes32(bytes20(tx.origin)), value: 0x0100000000000000 }();
    emit Claim(tx.origin);
  }
}

contract Destructive {
  address owner;

  constructor() payable {
    owner = tx.origin;
  }

  // No actual destruction happens after Cancun fork
  function claim() external {
    selfdestruct(payable(owner));
  }
}
