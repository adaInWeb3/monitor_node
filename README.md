
<img width="784" alt="image" src="https://github.com/user-attachments/assets/3068415b-5443-4f1c-9f52-502925f05e66" />

# Solana RPC Node Monitoring Script

A daemon script for monitoring Solana RPC node performance, synchronization status, and resource usage.

## Features

- Real-time slot monitoring
- Parallel RPC requests for efficient performance
- Memory usage tracking
- Synchronization status with public nodes
- Slot rate calculation
- Detailed logging
- Daemon mode operation

## Prerequisites

- Bash shell environment
- `curl` command-line tool
- `bc` command-line calculator
- `top` (for macOS) or `free` (for Linux) for memory monitoring

## Installation

1. Download the script:
```bash
curl -O https://github.com/adaInWeb3/monitor_node/blob/main/m.sh
```

2. Make the script executable:
```bash
chmod +x m.sh
```

## Usage

### Basic Usage

```bash
./m.sh [RPC_URL] [CHECK_INTERVAL] [PUBLIC_RPC_URL]
```

### Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| RPC_URL | Local Solana RPC node URL | http://localhost:8899 |
| CHECK_INTERVAL | Monitoring interval in seconds | 5 |
| PUBLIC_RPC_URL | Public RPC node URL for comparison | https://mainnet.helius-rpc.com/?api-key=... |

### Examples

1. Run with default settings:
```bash
./m.sh
```

2. Specify custom RPC URL and check interval:
```bash
./m.sh http://localhost:8899 10
```

3. Use a different public RPC node:
```bash
./m.sh http://localhost:8899 5 https://api.mainnet-beta.solana.com
```

## Output Format

The script generates logs in the following format:
```
[timestamp] Local:current_slot Public:public_slot Diff:slot_diff Rate:slot_rate/sec Sync:sync_pct% Mem:memory_usage% Status:status (status_detail)
```

### Field Descriptions

- `timestamp`: Current date and time
- `current_slot`: Current slot number of local node
- `public_slot`: Current slot number of public node
- `slot_diff`: Difference between public and local slots (+ahead/-behind)
- `slot_rate`: Slots processed per second
- `sync_pct`: Synchronization percentage with public node
- `memory_usage`: Current memory usage percentage
- `status`: Node status (OK/WARNING/UNKNOWN)
- `status_detail`: Additional status information

## Log File

- Log file location: `solana_monitor.log` in the current directory
- View logs in real-time:
```bash
tail -f solana_monitor.log
```

## Monitoring Thresholds

- `MAX_SLOT_DIFF`: Maximum allowed slot difference (default: 50)
- Status changes to WARNING when slot difference exceeds this threshold

## Memory Usage

The script automatically detects the operating system and uses the appropriate command to monitor memory usage:
- macOS: Uses `top -l 1`
- Linux: Uses `free` command

## Running as Daemon

The script automatically runs in daemon mode:
1. Creates a background process
2. Redirects output to log file
3. Continues running after terminal session ends

To stop the daemon:
```bash
pkill -f "m.sh"
```

## Error Handling

- Logs errors when unable to connect to local node
- Logs warnings when unable to connect to public node
- Continues monitoring even if public node is unavailable

## Best Practices

1. Use a reliable public RPC node for accurate comparison
2. Adjust check interval based on your needs (lower for more frequent updates)
3. Monitor the log file regularly for any warnings or errors
4. Ensure sufficient system resources for continuous monitoring

## Troubleshooting

1. If the script fails to start:
   - Check if the script is executable
   - Verify all required commands are installed
   - Check RPC URL accessibility

2. If monitoring stops:
   - Check system resources
   - Verify RPC node is running
   - Check log file for errors
