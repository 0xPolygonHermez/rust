#!/bin/bash

source ./scripts/git-utils.sh

# Check if the script has the required parameters
if [[ $# -ne 1 ]]; then
    echo -e "\e[1;31mError invalid parameters\e[0m"
    echo -e "\e[1;mUsage: $0 <TO_VERSION>\e[0m"
    exit 1
fi

TO_VERSION=$1
REMOTE_NAME="upstream"

echo -e "\e[1;32mUpdating Rust version to ${TO_VERSION}\e[0m"

# Check and add the remote if it doesn't exist
echo -e "\e[1;32mChecking if remote '${REMOTE_NAME}' exists\e[0m"
if ! git remote | grep -q "^${REMOTE_NAME}$"; then
    echo -e "\e[1;32mRemote '${REMOTE_NAME}' does not exist. Adding it\e[0m"
    exec_git \
        "git remote add ${REMOTE_NAME} git@github.com:rust-lang/rust.git" \
        "Failed to add remote '${REMOTE_NAME}'"
else
    echo -e "\e[1;32mRemote '${REMOTE_NAME}' already exists.\e[0m"
fi

# Fetch stable branch on remote upstream
echo -e "\e[1;32mFetching '${REMOTE_NAME}/stable' branch'\e[0m"
exec_git \
    "git fetch ${REMOTE_NAME} stable" \
    "Failed to fetch '${REMOTE_NAME}/stable' branch"

# Checkout local stable branch
echo -e "\e[1;32mChecking out 'stable' branch\e[0m"
exec_git \
    "git checkout stable" \
    "Failed to checkout 'stable' branch"

# Verify current branch is stable
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "stable" ]]; then
    echo -e "\e[1;31mCurrent branch is not 'stable'.\e[0m"
    exit 1
fi

# Pull local stable branch
echo -e "\e[1;32mPulling 'stable' branch\e[0m"
exec_git \
    "git pull" \
    "Failed to pull 'stable' branch"

# Create and checkout new branch zisk-rust-${TO_VERSION} from stable branch
echo -e "\e[1;32mCreating and check out new branch 'zisk-rust-${TO_VERSION}' from 'stable' branch\e[0m"
exec_git \
    "git checkout -b zisk-rust-${TO_VERSION}" \
    "Failed to create new branch 'zisk-rust-${TO_VERSION}'"

# Verify current branch is zisk-rust-${TO_VERSION}
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "zisk-rust-${TO_VERSION}" ]]; then
    echo -e "\e[1;31mCurrent branch is not 'zisk-rust-${TO_VERSION}'.\e[0m"
    exit 1
fi

# Rebase zisk-rust-${TO_VERSION} branch rebasing it with upstream/stable
echo -e "\e[1;32mRebasing 'zisk-rust-${TO_VERSION}' branch with 'upstream/stable'\e[0m"
exec_git \
    "git rebase upstream/stable" \
    "Failed to rebase 'zisk-rust-${TO_VERSION}' branch with 'upstream/stable'"

# Final instructions
echo -e "\e[1;32mTest build Zisk tool chain using the new branch 'zisk-rust-${TO_VERSION}'\e[0m"
echo -e "\e[1;32mWhen successfully tested, execute the following command to commit/merge the changes to 'stable' branch and generate the release:\e[0m"
echo
echo -e "\e[1m./scripts/release-rust.sh ${TO_VERSION}\e[0m"
echo
