#!/bin/bash

source ./scripts/git-utils.sh

# Check if the script has the required parameters
if [[ $# -ne 2 ]]; then
    echo -e "\e[1;31mError invalid parameters\e[0m"
    echo -e "\e[1;mUsage: $0 <FROM_VERSION> <TO_VERSION>\e[0m"
    exit 1
fi

FROM_VERSION=$1
TO_VERSION=$2
REMOTE_NAME="upstream"

echo -e "\e[1;32mUpdating Rust version from ${FROM_VERSION} to ${TO_VERSION}\e[0m"

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

# Fetch branches from the remote
echo -e "\e[1;32mFetching 'master' branch from remote '${REMOTE_NAME}'\e[0m"
exec_git \
    "git fetch ${REMOTE_NAME} master --tags" \
    "Failed to fetch remote '${REMOTE_NAME}' branches"

# Ensure we are on the master branch
exec_git \
    "git checkout master" \
    "Failed to checkout 'master' branch"

# Verify current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "master" ]]; then
    echo -e "\e[1;31mCurrent branch is not 'master'.\e[0m"
    exit 1
fi

# Rebase master branch with upstream/master and capture its output
echo -e "\e[1;32mUpdating 'master' branch with 'upstream/master'\e[0m"
exec_git \
    "git rebase upstream/master" \
    "Failed to rebase 'master' branch with 'upstream/master'"

# Check if the remote upstream/master is ahead of the local master and ask if you want to push the changes
commits_behind=$(git rev-list --count origin/master..master)
if [[ "$commits_behind" -gt 0 ]]; then
    read -p "$(echo -e '\e[1;33mDo you want to push the updated 'master' branch? [Y/n]: \e[0m')" response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    if [[ "$response" != "n" && "$response" != "no" ]]; then
        echo -e "\e[1;32mPushing 'master' branch and tags to origin\e[0m"
        exec_git \
            "git push origin master --force" \
            "Failed to push 'master' branch to origin"
        exec_git \
            "git push origin --tags" \
            "Failed to push tags to origin"
    fi
fi

# Fetch zisk-rust-${FROM_VERSION} branch
exec_git \
    "git fetch origin zisk-rust-${FROM_VERSION}:zisk-rust-${FROM_VERSION}" \
    "Failed to fetch 'zisk-rust-${FROM_VERSION}' branch"

# Create a new branch zisk-rust-${TO_VERSION} from ${TO_VERSION} branch
echo -e "\e[1;32mCreating new branch 'zisk-rust-${TO_VERSION}' from ${TO_VERSION}\e[0m"
exec_git \
    "git checkout -b zisk-rust-${TO_VERSION} ${TO_VERSION}" \
    "Failed to create new branch 'zisk-rust-${TO_VERSION}'"

# List cherry picks
echo -e "\e[1;32mList of cherry picks to apply:\e[0m"
exec_git \
    "git cherry ${FROM_VERSION} zisk-rust-${FROM_VERSION} -v" \
    "Failed to list cherry picks"

# Store the list of cherry-pick commits to apply in an array
commits=$(exec_git \
    "git cherry ${FROM_VERSION} zisk-rust-${FROM_VERSION} -v" \
    "Failed to get cherry picks")
IFS=$'\n' read -d '' -r -a commits_array <<< "$commits"
echo "$commits"
echo -e "\e[1;32mPress a key to continue...\e[0m"
read -n1 -s

for line in "${commits_array[@]}"; do
    # Check line starts with "+" (only apply added commits)
    if [[ "$line" =~ ^\+ ]]; then
        commit=$(echo "$line" | awk '{print $2}')
        msg=$(echo "$line" | cut -d' ' -f3-)
        
        echo -e "\e[1;32mApplying cherry pick for commit: ${msg} (${commit})\e[0m"
        output=$(git cherry-pick $commit -n 2>&1)
        if ! [[ $? -eq 0 ]]; then
            if [[ "$output" == *"CONFLICT"* ]]; then
                printf "%s\n" "$output"
                echo -e "\e[1;33mThe are CONFLICTS, please resolve them and after press a key to continue\e[0m"
                read -n1 -s
            else
                echo -e "\e[1;31mFailed to apply cherry pick for commit: ${msg} (${commit})\e[0m"
                printf "%s\n" "$output"
                exit 1
            fi
        fi
    fi
done

# Final instructions
echo -e "\e[1;32mAll cherry picks applied.\e[0m"
echo
echo -e "\e[1;32mTest build Zisk tool chain using the new branch 'zisk-rust-${TO_VERSION}'.\e[0m"
echo -e "\e[1;32mWhen successfully tested, proceed to merge the changes and re-tag the 'zisk' branch using the following command:\e[0m"
echo
echo -e "\e[1m./scripts/commit-rust.sh ${TO_VERSION}\e[0m"
echo
