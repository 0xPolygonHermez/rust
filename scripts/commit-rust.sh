#!/bin/bash

source ./scripts/git-utils.sh

# Check if the script has the required parameters
if [[ $# -ne 2 ]]; then
    echo -e "\e[1;31mError invalid parameters\e[0m"
    echo -e "\e[1;mUsage: $0 <RUST_VERSION> <RUST_ZISK_VERSION>\e[0m"
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
    "git commit -m 'Update Rust to version ${TO_VERSION}'" \
    "Failed to commit changes"

echo -e "\e[1;32m Checking out 'stable' branch\e[0m"
exec_git \
    "git checkout stable" \
    "Failed to checkout 'stable' branch"

echo -e "\e[1;32mPulling 'stable' branch\e[0m"    
exec_git \
    "git pull" \
    "Failed to pull 'stable' branch"    

echo -e "\e[1;32mMerge branch 'zisk-rust-${TO_VERSION}' into 'stable' branch\e[0m"
exec_git \
    "git merge zisk-rust-${TO_VERSION}" \
    "Failed to merge branch 'zisk-rust-${TO_VERSION}' into 'stable' branch"    

echo -e "\e[1;32mPushing 'stable' branch to origin\e[0m"
exec_git \
    "git push origin stable" \
    "Failed to push 'stable' branch to origin"

echo -e "\e[1;32mTagging branch 'stable' with tag 'zisk-${RUST_ZISK_VERSION}'\e[0m"
# Create tag
exec_git \
    "git tag zisk-${RUST_ZISK_VERSION}" \
    "Failed to create local tag 'zisk-${RUST_ZISK_VERSION}'"
# Push tag to origin
exec_git \
    "git push origin zisk-${RUST_ZISK_VERSION}" \
    "Failed to push tag 'zisk-${RUST-ZISK-VERSION}' to origin"

echo -e "\e[1;32mDone\e[0m"
