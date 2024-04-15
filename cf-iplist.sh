#!/bin/sh

# Function to display usage
usage() {
    echo "Usage: $0 -m <mode> -i <ip>"
    echo
    echo "Options:"
    echo "  -m <mode>   Mode of operation. Can be 'ban' or 'unban'."
    echo "  -i <ip>     IP address to ban or unban."
    echo
    echo "Example:"
    echo "  $0 -m ban -i 192.0.2.0"
    exit 1
}

# Function to validate an IP
validate_ip() {
    # Regular expression for IPv4
    _ipv4_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    # Regular expression for IPv6
    _ipv6_regex="^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$"
    # Check if IP matches either regular expression
    if echo "$1" | grep -Eq "$_ipv4_regex" || echo "$1" | grep -Eq "$_ipv6_regex"; then
        return 0
    else
        return 1
    fi
}

# Function to make a GET request and handle errors
make_get_request() {
    url=$1

    # Make GET request
    response=$(curl -s -w "\n%{http_code}" -X GET "$url" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json")
    
    # Handle failures
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | sed '$ d')
    if [ "$http_code" -ne 200 ]; then
        echo "Error: GET request to $url failed with status code $http_code"
        echo "Response: $response_body"
        exit 1
    fi

    # Return response body
    echo "$response_body"
}

# Function to make a POST request and handle errors
make_post_request() {
    url=$1
    data=$2

    # Make POST request
    response=$(curl -s -w "%{http_code}" -X POST "$url" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "$data")

    # Handle failures
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | jq .)
    if [ "$http_code" -ne 200 ] && [ "$http_code" -ne 201 ]; then
        echo "Error: POST request to $url failed with status code $http_code"
        echo "Response: $response_body"
        exit 1
    fi

    # Return response body
    echo "$response_body"
}



# Function to get account ID
get_account_id() {
    response=$(make_get_request "https://api.cloudflare.com/client/v4/accounts")
    account_id=$(echo "$response" | jq -r '.result[0].id')
    echo "$account_id"
}

# Function to get or create list
get_or_create_list() {
    account_id=$1
    response=$(make_get_request "https://api.cloudflare.com/client/v4/accounts/$account_id/rules/lists")
    
    # Get list ID if it exists
    list_id=$(echo "$response" | jq -r '.result[] | select(.name=="fail2ban") | .id')
    
    # Create list if it does not exist
    if [ -z "$list_id" ]; then
        data='{"name":"fail2ban","description":"List of banned IPs"}'
        response=$(make_post_request "https://api.cloudflare.com/client/v4/accounts/$account_id/rules/lists" "$data")
        list_id=$(echo "$response" | jq -r '.result.id')
    fi

    # Return list ID
    echo "$list_id"
}

# Function to ban IP
ban_ip() {
    ip=$1
    list_id=$2

    # Set data for POST request
    data="{\"items\":[{\"ip\":\"$ip\"}]}"
    
    # Make POST request to add IP to list
    response=$(make_post_request "https://api.cloudflare.com/client/v4/accounts/$account_id/rules/lists/$list_id/items" "$data")
    
    # Return success message
    echo "IP address ${ip} has been banned"
}



# Function to unban an IP
unban_ip() {
    ip=$1
    list_id=$2

    # Get list of banned IPs
    response=$(make_get_request "https://api.cloudflare.com/client/v4/accounts/$account_id/rules/lists/$list_id/items")
    
    # Update list to remove banned IP
    updated_list=$(echo "$response" | jq -c ".result |= map(select(.ip != \"$ip\") | {ip: .ip})" | jq .result)

    # Make PUT request to update list
    response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/${account_id}/rules/lists/${list_id}/items" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "$updated_list")

    # Handle success or failure
    success=$(echo "$response" | jq -r '.success')   
    if [ "$success" = "false" ]; then
        echo "Error: Failed to get unbad IP ${ip}."
        echo "Response: $response"
        exit 1
    else
        echo "IP address $ip has been unbanned"
    fi

}

# Check if environment variable is set
if [ -z "$CF_API_TOKEN" ]; then
    echo "Error: CF_API_TOKEN environment variable must be set"
    exit 1
fi

# Initialize variables
mode=""
ip=""

# Parse command line flags
while getopts "m:i:" flag
do
    case "${flag}" in
        m) mode=${OPTARG};;
        i) ip=${OPTARG};;
        *) usage;;
    esac
done

# Check if all flags are set
if [ -z "$mode" ] || [ -z "$ip" ]; then
    echo "Error: Missing required arguments"
    usage
fi

# Check if IP is valid
if ! validate_ip "$ip"; then
    echo "Error: Invalid IP address"
    exit 1
fi

# Check if mode is valid
if [ "$mode" != "ban" ] && [ "$mode" != "unban" ]; then
    echo "Error: Invalid mode. Mode should be either 'ban' or 'unban'"
    exit 1
fi

# Get account ID
account_id=$(get_account_id)

# Get or create list
list_id=$(get_or_create_list "$account_id")

# # Ban or unban IP
"${mode}"_ip "$ip" "$list_id" "$account_id"
