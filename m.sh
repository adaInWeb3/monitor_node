#!/bin/bash

# Solana RPC Node Slot Monitoring Script
# Runs as a daemon process by default

# Configuration parameters
RPC_URL=${1:-"http://localhost:8899"}
CHECK_INTERVAL=${2:-5}
PUBLIC_RPC_URL=${3:-"https://api.mainnet-beta.solana.com"}
LOG_FILE="solana_monitor.log"
MAX_SLOT_DIFF=50
TEMP_DIR="/tmp/solana_monitor"

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create temp directory if it doesn't exist
mkdir -p $TEMP_DIR

# Function to get memory usage percentage
get_memory_usage() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    memory_usage=$(top -l 1 | grep "Memory" | awk '{print $7}' | cut -d'%' -f1)
  else
    # Linux
    memory_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
  fi
  echo $memory_usage
}

# Check if already running in daemon mode
if [ -z "$DAEMON_ACTIVE" ]; then
  # Create or clear log file
  > "$LOG_FILE"
  
  # Add header to log file (simple format)
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Solana RPC Node Monitoring Started ===" >> "$LOG_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Local RPC: $RPC_URL" >> "$LOG_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Check Interval: ${CHECK_INTERVAL} seconds" >> "$LOG_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ===========================" >> "$LOG_FILE"
  
  echo -e "${GREEN}Starting in daemon mode...${NC}"
  echo -e "${BLUE}Log file:${NC} $(pwd)/$LOG_FILE"
  echo -e "${YELLOW}View logs with:${NC}"
  echo -e "  tail -f $LOG_FILE"
  
  # Start daemon process
  export DAEMON_ACTIVE=1
  nohup "$0" "$RPC_URL" "$CHECK_INTERVAL" "$PUBLIC_RPC_URL" > /dev/null 2>&1 &
  
  echo -e "${GREEN}Daemon started, PID: $!${NC}"
  exit 0
fi

# Core function: Get current slot (latest state)
get_current_slot() {
  local rpc_url=$1
  local output_file=$2
  # Query latest state slot (default commitment if not specified)
  local result=$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getSlot", "params":[{"commitment":"confirmed"}]}' $rpc_url)
  local slot=$(echo $result | grep -o '"result":[0-9]*' | cut -d':' -f2)
  echo $slot > $output_file
}

# Core function: Calculate slots per second
calculate_slot_rate() {
  local slot_diff=$1
  local time_diff=$2
  
  if [ $time_diff -eq 0 ]; then
    echo "N/A"
  else
    echo "scale=2; $slot_diff / $time_diff" | bc
  fi
}

# Main loop
last_slot=0
last_check_time=$(date +%s)

# Pause a few seconds to ensure first data comparison is accurate
sleep 2

while true; do
  current_time=$(date +%s)
  local_slot_file="$TEMP_DIR/local_slot.txt"
  public_slot_file="$TEMP_DIR/public_slot.txt"
  
  # Request both slots in parallel
  get_current_slot "$RPC_URL" "$local_slot_file" &
  local_pid=$!
  get_current_slot "$PUBLIC_RPC_URL" "$public_slot_file" &
  public_pid=$!
  
  # Get memory usage while waiting for slot requests
  memory_usage=$(get_memory_usage)
  
  # Wait for both requests to complete
  wait $local_pid
  wait $public_pid
  
  # Read results
  current_slot=$(cat "$local_slot_file" 2>/dev/null)
  public_slot=$(cat "$public_slot_file" 2>/dev/null)
  
  # Check local node
  if [ -z "$current_slot" ] || ! [[ "$current_slot" =~ ^[0-9]+$ ]]; then
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    log_msg="[$timestamp] ERROR: Unable to get slot information from local node"
    echo "$log_msg" >> "$LOG_FILE"
    sleep $CHECK_INTERVAL
    continue
  fi
  
  # Check public node (log warning if it fails)
  if [ -z "$public_slot" ] || ! [[ "$public_slot" =~ ^[0-9]+$ ]]; then
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    log_msg="[$timestamp] WARNING: Unable to get slot information from public node"
    echo "$log_msg" >> "$LOG_FILE"
    public_slot="N/A"
  fi
  
  # Calculate slot difference and rate
  time_diff=$((current_time - last_check_time))
  
  slot_growth=0
  if [ $last_slot -ne 0 ]; then
    slot_growth=$((current_slot - last_slot))
  fi
  
  slot_rate=$(calculate_slot_rate $slot_growth $time_diff)
  
  # Calculate diff with public node
  if [[ "$public_slot" =~ ^[0-9]+$ ]]; then
    slot_diff=$((public_slot - current_slot))
    sync_pct=$(echo "scale=2; ($current_slot / $public_slot) * 100" | bc)
    
    # Format diff display
    if [ $slot_diff -gt 0 ]; then
      diff_display="-${slot_diff}"
    elif [ $slot_diff -lt 0 ]; then
      # If negative, take absolute value and display as ahead
      abs_diff=$((slot_diff * -1))
      diff_display="+${abs_diff}"
    else
      diff_display="0"
    fi
    
    # Check if node is behind
    if [ $slot_diff -gt $MAX_SLOT_DIFF ]; then
      status="WARNING"
      status_detail="node behind by ${slot_diff} slots"
    else
      status="OK"
      status_detail=""
    fi
  else
    slot_diff="N/A"
    diff_display="unknown"
    sync_pct="N/A"
    status="UNKNOWN"
    status_detail="cannot compare with public node"
  fi
  
  # Use simple one-line text format for output
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Simplified log format with memory usage
  log_msg="[$timestamp] Local:$current_slot Public:$public_slot Diff:$diff_display Rate:${slot_rate}/sec Sync:${sync_pct}% Mem:${memory_usage}% Status:$status ${status_detail:+($status_detail)}"
  
  # Write to log file
  echo "$log_msg" >> "$LOG_FILE"
  
  # Update variables
  last_slot=$current_slot
  last_check_time=$current_time
  
  # Wait for next check
  sleep $CHECK_INTERVAL
done
