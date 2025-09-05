#!/bin/bash

# Health check monitoring script for the Terraform challenge
# Continuously polls the /health endpoint and provides formatted output

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
INTERVAL=10
COUNT=0
VERBOSE=false
FOLLOW=false

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Continuously check the App Runner service health endpoint"
    echo ""
    echo "Options:"
    echo "  -i, --interval SECONDS  Check interval in seconds (default: 10)"
    echo "  -c, --count NUMBER     Number of checks to perform (default: unlimited)"
    echo "  -v, --verbose          Show detailed response information"
    echo "  -f, --follow           Follow mode: clear screen between checks"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Check every 10 seconds indefinitely"
    echo "  $0 -i 5 -c 20         # Check every 5 seconds, 20 times"
    echo "  $0 -f -v              # Follow mode with verbose output"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -c|--count)
            COUNT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate interval
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [[ "$INTERVAL" -lt 1 ]]; then
    echo -e "${RED}Error: Invalid interval. Must be a positive integer.${NC}"
    exit 1
fi

# Validate count
if [[ "$COUNT" != "0" ]] && (! [[ "$COUNT" =~ ^[0-9]+$ ]] || [[ "$COUNT" -lt 1 ]]); then
    echo -e "${RED}Error: Invalid count. Must be a positive integer or 0 for unlimited.${NC}"
    exit 1
fi

# Check if we can get the App Runner URL
if [[ ! -d "../infra" ]]; then
    echo -e "${RED}Error: Please run this script from the scripts/ directory${NC}"
    echo "Expected to find ../infra/ directory with Terraform configuration"
    exit 1
fi

echo -e "${BLUE}Getting App Runner URL from Terraform...${NC}"
cd ../infra
APP_RUNNER_URL=$(terraform output -raw app_runner_url 2>/dev/null)

if [[ -z "$APP_RUNNER_URL" ]]; then
    echo -e "${RED}Error: Could not get App Runner URL from Terraform outputs${NC}"
    echo "Make sure 'terraform apply' has been run successfully"
    exit 1
fi

HEALTH_URL="$APP_RUNNER_URL/health"

echo -e "${BLUE}Monitoring: $HEALTH_URL${NC}"
echo -e "${BLUE}Interval: ${INTERVAL}s${NC}"
if [[ "$COUNT" != "0" ]]; then
    echo -e "${BLUE}Count: $COUNT${NC}"
else
    echo -e "${BLUE}Count: Unlimited (Ctrl+C to stop)${NC}"
fi
echo ""

# Function to check health
check_health() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local check_num=$1
    
    if [[ "$FOLLOW" == "true" ]] && [[ "$check_num" -gt 1 ]]; then
        clear
        echo -e "${BLUE}Health Check Monitor - Check #$check_num${NC}"
        echo -e "${BLUE}URL: $HEALTH_URL${NC}"
        echo -e "${BLUE}Interval: ${INTERVAL}s${NC}"
        echo ""
    fi
    
    echo -e "${YELLOW}[$timestamp] Check #$check_num${NC}"
    
    # Make the request with timeout
    local response
    local http_code
    local curl_exit_code
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 30 "$HEALTH_URL" 2>/dev/null) || curl_exit_code=$?
    
    if [[ -n "$curl_exit_code" ]]; then
        echo -e "${RED}❌ Connection failed (curl exit code: $curl_exit_code)${NC}"
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${RED}   Possible causes: DNS resolution, network connectivity, service down${NC}"
        fi
        return 1
    fi
    
    # Extract HTTP code and response body
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    # Format and display results
    if [[ "$http_code" == "200" ]]; then
        echo -e "${GREEN}✅ HTTP $http_code - OK${NC}"
        
        # Parse JSON response if possible
        if command -v jq &> /dev/null; then
            local redis_status=$(echo "$response_body" | jq -r '.redis // "unknown"' 2>/dev/null)
            if [[ "$redis_status" == "ok" ]]; then
                echo -e "${GREEN}   Redis: ✅ Connected${NC}"
                local timestamp_from_response=$(echo "$response_body" | jq -r '.timestamp // ""' 2>/dev/null)
                if [[ -n "$timestamp_from_response" && "$timestamp_from_response" != "null" ]]; then
                    echo -e "${GREEN}   Response time: $timestamp_from_response${NC}"
                fi
            else
                echo -e "${RED}   Redis: ❌ $redis_status${NC}"
            fi
        else
            # Simple text parsing if jq is not available
            if echo "$response_body" | grep -q '"redis":"ok"'; then
                echo -e "${GREEN}   Redis: ✅ Connected${NC}"
            elif echo "$response_body" | grep -q '"redis":"error"'; then
                echo -e "${RED}   Redis: ❌ Error${NC}"
            fi
        fi
        
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${BLUE}   Full response:${NC}"
            if command -v jq &> /dev/null; then
                echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
            else
                echo "$response_body"
            fi
        fi
        
    else
        echo -e "${RED}❌ HTTP $http_code - Error${NC}"
        
        if [[ "$VERBOSE" == "true" ]] || [[ "$http_code" =~ ^5 ]]; then
            echo -e "${RED}   Response body:${NC}"
            if command -v jq &> /dev/null && echo "$response_body" | jq . &>/dev/null; then
                echo "$response_body" | jq .
            else
                echo "$response_body"
            fi
        fi
        
        # Provide troubleshooting hints for common error codes
        case "$http_code" in
            500)
                echo -e "${YELLOW}   ℹ️  This is likely the Redis connection error you need to troubleshoot!${NC}"
                ;;
            502|503)
                echo -e "${YELLOW}   ℹ️  App Runner service may be starting up or unhealthy${NC}"
                ;;
            404)
                echo -e "${YELLOW}   ℹ️  Check the URL path - should be /health${NC}"
                ;;
        esac
    fi
    
    echo ""
}

# Main monitoring loop
check_counter=1

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Monitoring stopped.${NC}"; exit 0' INT

while true; do
    check_health $check_counter
    
    # Check if we've reached the desired count
    if [[ "$COUNT" != "0" ]] && [[ "$check_counter" -ge "$COUNT" ]]; then
        echo -e "${BLUE}Completed $COUNT checks. Exiting.${NC}"
        break
    fi
    
    check_counter=$((check_counter + 1))
    
    # Wait for the specified interval
    if [[ "$COUNT" == "0" ]] || [[ "$check_counter" -le "$COUNT" ]]; then
        echo -e "${BLUE}Waiting ${INTERVAL}s for next check... (Ctrl+C to stop)${NC}"
        sleep "$INTERVAL"
        echo ""
    fi
done