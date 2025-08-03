# Community Memory Archive Smart Contract

A decentralized smart contract on the Stacks blockchain for preserving and archiving community memories, historical records, and cultural heritage.

## Overview

The Community Memory Archive enables communities to collectively store, verify, and preserve important memories and historical records on the blockchain. This ensures permanent, tamper-proof storage of cultural heritage and community stories.

## Features

### Core Functionality
- **Memory Submission**: Users can submit memories with metadata, descriptions, and IPFS content hashes
- **Community Verification**: Memories can be verified by community members (3 verifications = verified status)
- **User Profiles**: Track user contributions, reputation, and engagement
- **Comments System**: Users can add comments to memories for additional context
- **Categorization**: Organize memories by categories and tags
- **Fee-based Archive**: Small STX fee to prevent spam and fund maintenance

### Data Structures
- **Memories**: Core memory records with creator, content, verification status
- **User Profiles**: Username, reputation score, contribution statistics
- **Verifications**: Community-driven verification system
- **Comments**: Additional context and discussion for memories

## Contract Functions

### Read-Only Functions
- `get-memory(memory-id)` - Retrieve memory details
- `get-user-profile(user)` - Get user profile information
- `get-memory-verification(memory-id, verifier)` - Check verification status
- `get-memory-comment(memory-id, comment-id)` - Retrieve specific comment
- `get-total-memories()` - Get total number of archived memories
- `get-archive-fee()` - Current submission fee

### Public Functions
- `create-user-profile(username)` - Create a user profile
- `submit-memory(title, description, content-hash, category, tags)` - Submit new memory
- `verify-memory(memory-id)` - Verify a community memory
- `add-comment(memory-id, content)` - Add comment to a memory
- `update-archive-fee(new-fee)` - Update submission fee (owner only)
- `withdraw-funds(amount, recipient)` - Withdraw contract funds (owner only)

## Installation & Deployment

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- [Stacks CLI](https://docs.stacks.co/docs/blockchain/stacks-cli) for deployment
- Node.js and npm for frontend integration

### Local Development
```bash
# Clone the repository
git clone <repository-url>
cd community-memory-archive

# Initialize Clarinet project (if not already done)
clarinet new community-memory-archive
cd community-memory-archive

# Add the contract file
# Copy the contract code to contracts/community-memory-archive.clar

# Run tests
clarinet test

# Check contract
clarinet check
```

### Deployment
```bash
# Deploy to testnet
clarinet deploy --testnet

# Deploy to mainnet
clarinet deploy --mainnet
```

## Usage Examples

### Creating a User Profile
```clarity
(contract-call? .community-memory-archive create-user-profile "historian123")
```

### Submitting a Memory
```clarity
(contract-call? .community-memory-archive submit-memory 
  "First Community Festival" 
  "Documentation of our town's inaugural cultural festival in 1995"
  "QmX7Kd8h9JHgFd6Zr5Qs2Wv8Nm1Lp3Rt6Yk4Bv9Cd2Ef1Gh3"
  "Cultural Events"
  (list "festival" "1995" "community" "culture"))
```

### Verifying a Memory
```clarity
(contract-call? .community-memory-archive verify-memory u1)
```

### Adding a Comment
```clarity
(contract-call? .community-memory-archive add-comment 
  u1 
  "I was there! This was indeed a wonderful celebration of our community spirit.")
```

## Reputation System

Users earn reputation points through various activities:
- **Submit Memory**: +10 points
- **Verify Memory**: +5 points
- **Memory Gets Verified**: +20 points (for creator)
- **Add Comment**: +2 points

Higher reputation indicates more trusted community members.

## Fee Structure

- **Archive Fee**: 1 STX (1,000,000 microSTX) per memory submission
- Fees help prevent spam and fund contract maintenance
- Contract owner can adjust fees based on network conditions

## Security Features

- **Access Control**: Only contract owner can modify fees and withdraw funds
- **Verification Prevention**: Users cannot verify their own memories
- **Input Validation**: All text inputs are validated for length and content
- **Balance Checks**: Ensures sufficient funds before operations

## Error Codes

- `u100` - ERR-UNAUTHORIZED: Insufficient permissions
- `u101` - ERR-NOT-FOUND: Requested resource not found
- `u102` - ERR-ALREADY-EXISTS: Resource already exists
- `u103` - ERR-INVALID-INPUT: Invalid input parameters
- `u104` - ERR-INSUFFICIENT-BALANCE: Insufficient STX balance

## Data Storage

- **On-Chain**: Metadata, titles, descriptions, verification status
- **Off-Chain**: Large content stored via IPFS with hashes stored on-chain
- **Permanent**: All records are immutable once confirmed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For questions, issues, or contributions:
- Open an issue on GitHub
- Join our community Discord
- Check the Stacks documentation for blockchain-specific questions

## Roadmap

- [ ] Frontend web application
- [ ] Mobile app integration
- [ ] Advanced search functionality
- [ ] Memory collections/albums
- [ ] Cross-community memory sharing
- [ ] NFT integration for special memories
- [ ] Multi-language support