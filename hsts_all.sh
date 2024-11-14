#!/bin/bash

# Set the input file containing DNS names
input_file="dns_names.txt"
# Set the output CSV file
output_file="hsts_results.csv"

# Function to check if a domain supports HSTS and if it includes subdomains
check_hsts() {
    local domain=$1
    # Use curl to fetch headers and capture the "strict-transport-security" header
    hsts_header=$(curl -L --connect-timeout 5 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"  -s -I "https://$domain" | grep -i "strict-transport-security")

    # Check if HSTS is enabled
    if echo "$hsts_header" | grep -iq "strict-transport-security"; then
        hsts="Yes"
        # Check if includeSubDomains is present in the HSTS header
        if echo "$hsts_header" | grep -iq "includeSubDomains"; then
            hsts_include_subdomains="Yes"
        else
            hsts_include_subdomains="No"
        fi
    else
        hsts="No"
        hsts_include_subdomains="No"
    fi

    echo "$hsts,$hsts_include_subdomains"
}

# Function to get the parent domain
get_parent_domain() {
    local domain=$1
    # Extract the parent domain (e.g., "sub.example.com" -> "example.com")
    parent=$(echo "$domain" | awk -F. '{print $(NF-1)"."$NF}')
    echo "$parent"
}

# Write CSV header
echo "Domain,Parent Domain,HSTS Enabled,HSTS Include Subdomains,HSTS Enabled (Parent),HSTS Include Subdomains (Parent)" > "$output_file"

# Check if input file exists
if [[ ! -f "$input_file" ]]; then
    echo "Input file '$input_file' not found!"
    exit 1
fi

# Read domains from the input file and process each
while IFS= read -r domain; do
    # Skip empty lines
    if [[ -z "$domain" ]]; then
        continue
    fi

    # Check HSTS for the domain
    hsts_info=($(check_hsts "$domain"))
    hsts=${hsts_info[0]}
    hsts_include_subdomains=${hsts_info[1]}

    # Get parent domain
    parent_domain=$(get_parent_domain "$domain")

    # Check HSTS for the parent domain
    parent_hsts_info=($(check_hsts "$parent_domain"))
    parent_hsts=${parent_hsts_info[0]}
    parent_hsts_include_subdomains=${parent_hsts_info[1]}

    # Write results to CSV
    echo "$domain,$parent_domain,$hsts,$hsts_include_subdomains,$parent_hsts,$parent_hsts_include_subdomains" >> "$output_file"
    echo "Checked: $domain"
done < "$input_file"

echo "Results saved to $output_file"
