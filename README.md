# TimelockManager

TimelockManager is an address reputation system smart contract for timelock contract manager trustworthiness scoring built on the Stacks blockchain using the Clarity language.

## Description

TimelockManager provides a comprehensive reputation tracking system for addresses that manage timelock contracts. The system monitors performance, calculates trustworthiness scores, and maintains historical records of timelock operations to enable informed decision-making when selecting timelock managers.

## Features

- **Manager Registration**: Register new timelock managers with initial reputation scores
- **Performance Tracking**: Monitor timelock operation success and failure rates
- **Dynamic Reputation Scoring**: Calculate reputation scores based on historical performance
- **Activity Management**: Track manager activity and enable/disable manager status
- **Performance History**: Maintain detailed records of all timelock operations
- **Trustworthiness Assessment**: Evaluate manager reliability based on configurable thresholds
- **Event Logging**: Comprehensive logging system for all contract operations
- **Access Control**: Owner-based authorization for critical operations

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Clarity Version**: 2
- **Contract Framework**: Clarinet

### Key Constants

- **Initial Reputation Score**: 50/100
- **Minimum Reputation Score**: 0
- **Maximum Reputation Score**: 100
- **Reputation Calculation**: Based on success rate with minimum baseline of 10

### Data Structures

#### Manager Reputation
```clarity
{
    score: uint,              // Current reputation score (0-100)
    total-locks: uint,        // Total number of timelock operations
    successful-locks: uint,   // Number of successful operations
    failed-locks: uint,       // Number of failed operations
    last-activity: uint,      // Block height of last activity
    is-active: bool          // Manager active status
}
```

#### Performance History
```clarity
{
    start-block: uint,        // Block when timelock started
    end-block: uint,          // Expected end block
    was-successful: bool,     // Operation outcome
    timestamp: uint          // Block height timestamp
}
```

## Installation

### Prerequisites

- [Clarinet CLI](https://docs.hiro.so/clarinet) installed
- Node.js and npm for testing
- Stacks CLI for deployment

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd TimelockManager
```

2. Install dependencies:
```bash
cd TimelockManager_contract
npm install
```

3. Verify installation:
```bash
clarinet check
```

## Usage Examples

### Register a New Manager

```clarity
(contract-call? .TimelockManager register-manager 'SP1234567890ABCDEF...)
```

### Start a Timelock Operation

```clarity
(contract-call? .TimelockManager start-timelock 'SP1234567890ABCDEF... u144) ;; 144 blocks duration
```

### Complete a Timelock Operation

```clarity
(contract-call? .TimelockManager complete-timelock 'SP1234567890ABCDEF... u1 true) ;; Success
(contract-call? .TimelockManager complete-timelock 'SP1234567890ABCDEF... u2 false) ;; Failure
```

### Check Manager Reputation

```clarity
(contract-call? .TimelockManager get-reputation-score 'SP1234567890ABCDEF...)
```

### Verify Trustworthiness

```clarity
(contract-call? .TimelockManager is-trustworthy-manager 'SP1234567890ABCDEF... u75) ;; 75% threshold
```

## Contract Functions Documentation

### Public Functions

#### `register-manager (manager principal)`
Registers a new timelock manager with initial reputation score.
- **Parameters**: `manager` - Principal address to register
- **Returns**: `(ok principal)` on success
- **Errors**: `ERR-ALREADY-EXISTS` if manager already registered

#### `start-timelock (manager principal) (duration uint)`
Records the start of a timelock operation.
- **Parameters**:
  - `manager` - Manager principal address
  - `duration` - Duration in blocks
- **Returns**: `(ok uint)` - Lock ID on success
- **Errors**: `ERR-MANAGER-NOT-FOUND`, `ERR-INVALID-PARAMETERS`, `ERR-NOT-AUTHORIZED`

#### `complete-timelock (manager principal) (lock-id uint) (successful bool)`
Records the completion of a timelock operation and updates reputation.
- **Parameters**:
  - `manager` - Manager principal address
  - `lock-id` - Timelock operation ID
  - `successful` - Operation outcome
- **Returns**: `(ok bool)` on success
- **Authorization**: Manager or contract owner only

#### `deactivate-manager (manager principal)`
Deactivates a manager (owner only).
- **Parameters**: `manager` - Manager to deactivate
- **Returns**: `(ok true)` on success
- **Authorization**: Contract owner only

### Read-Only Functions

#### `get-manager-reputation (manager principal)`
Returns complete reputation data for a manager.

#### `get-reputation-score (manager principal)`
Returns only the reputation score for a manager.

#### `is-trustworthy-manager (manager principal) (threshold uint)`
Checks if manager meets trustworthiness threshold.

#### `get-lock-performance (manager principal) (lock-id uint)`
Returns performance data for a specific timelock operation.

#### `get-total-managers`
Returns total number of registered managers.

#### `get-contract-stats`
Returns contract statistics and configuration.

## Testing

Run the test suite:

```bash
npm test
```

Run tests with coverage report:

```bash
npm run test:report
```

Watch mode for development:

```bash
npm run test:watch
```

## Deployment Guide

### Local Development Network

1. Start local devnet:
```bash
clarinet integrate
```

2. Deploy contract:
```bash
clarinet deploy --devnet
```

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy to testnet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy to mainnet:
```bash
clarinet deploy --mainnet
```

## Security Notes

### Access Control
- Only registered managers can start timelock operations
- Only managers or contract owner can complete timelock operations
- Only contract owner can deactivate managers
- Contract owner is immutable (set at deployment)

### Reputation System Security
- Reputation scores are calculated deterministically based on performance
- Minimum baseline score prevents complete reputation destruction
- Historical performance data is immutable once recorded
- Active status prevents inactive managers from starting new operations

### Best Practices
- Validate all inputs before processing
- Use assertion checks for authorization
- Implement proper error handling
- Log all significant events for auditability
- Regular monitoring of manager performance recommended

### Known Limitations
- No pagination for manager queries (suitable for moderate number of managers)
- Reputation calculation uses simple success rate formula
- No slashing or penalty mechanisms beyond reputation scoring
- Manager removal requires owner intervention

## Error Codes

- `u400` - Invalid parameters
- `u401` - Not authorized
- `u402` - Invalid score
- `u404` - Manager not found
- `u409` - Already exists

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For questions, issues, or contributions, please refer to the project's issue tracker or documentation.