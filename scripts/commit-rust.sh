#!/bin/bash

source ./scripts/git-utils.sh

# Check if the script has the required parameters
if [[ $# -ne 1 ]]; then
    echo -e "\e[1;31mError invalid parameters\e[0m"
    echo -e "\e[1;mUsage: $0 <TO_VERSION>\e[0m"
    exit 1
fi

TO_VERSION=$1

unstaged_files=$(git diff --name-only)
if ! [[ -z "$unstaged_files" ]]; then
    echo -e "\e[1;32mUnstaged files in the working directory:\e[0m"
    echo "$unstaged_files"
    read -p "$(echo -e '\e[1;33mThere are unstaged files in the working directory. Continue? [y/N] \e[0m')" response
    if [[ "$response" != "y" && "$response" != "yes" ]]; then
        echo -e "\e[1;32mExiting...\e[0m"
        exit 1
    fi
fi

echo -e "\e[1;32mCommitting all staged files to branch 'zisk-rust-${TO_VERSION}'\e[0m"
echo -e "\e[1;32mCommit message 'Add Zisk changes to Rust version ${TO_VERSION}'\e[0m"
exec_git \
    "git commit -m 'Add Zisk changes to Rust version ${TO_VERSION}'" \
    "Failed to commit changes"

echo -e "\e[1;32mPushing branch 'zisk-rust-${TO_VERSION}' to origin\e[0m"
exec_git \
    "git push origin zisk-rust-${TO_VERSION}" \
    "Failed to push branch zisk-rust-${TO_VERSION} to origin"

echo -e "\e[1;32mTagging branch 'zisk-rust-${TO_VERSION}' with tag 'zisk'\e[0m"

# Delete local tag
if git tag | grep -q "^zisk$"; then
    exec_git \
        "git tag -d zisk" \
        "Failed to delete local tag 'zisk'"
fi

# Delete remote tag
if git ls-remote --tags origin | grep -q "refs/tags/zisk$"; then
    exec_git \
        "git push --delete origin zisk" \
        "Failed to delete remote tag 'zisk'"
fi

# Create tag
exec_git \
    "git tag zisk" \
    "Failed to create local tag 'zisk'"

# Push tag to origin
exec_git \
    "git push origin zisk" \
    "Failed to push tag 'zisk' to origin"

echo -e "\e[1;32mDone\e[0m"
