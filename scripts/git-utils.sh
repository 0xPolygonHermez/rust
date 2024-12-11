# git-utils.sh

# Execute a git command and print the output. Exits if the command fails.
exec_git() {
    local command="$1"
    local error_message="$2"

    output=$(eval "$command" 2>&1)

    # Exit if the command fails
    if [[ $? -ne 0 ]]; then
        # Print the error output
        echo "$output"
        # Print the error message
        echo -e "\e[1;31m${error_message}\e[0m"
        
        exit 1
    fi

    # Print the output if it's not empty
    if [[ -n "$output" ]]; then
        echo "$output"
    fi    
}
