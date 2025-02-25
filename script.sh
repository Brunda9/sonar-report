#!/bin/bash
 
# Set environment variables
SONAR_JAR="sonar-cnes-report-4.3.0.jar"
SONAR_URL="https://gbssonar.edst.ibm.com/sonar"
AUTHOR_NAME="Admin"
REPO_FILE="repos.txt"
TOKEN="squ_097bdc24b86ac60c709b32175d5bf4d6c3521d8e"
 
# Check if Java is installed
if ! command -v java &>/dev/null; then
    echo "❌ Error: Java is not installed or not in PATH."
    exit 1
fi
 
# Check if the repository file exists
if [[ ! -f "$REPO_FILE" ]]; then
    echo "❌ Error: File '$REPO_FILE' not found!"
    exit 1
fi
 
# Read and filter repositories, trim spaces, and remove Windows CRLF issues
declare -a repos
declare -a branches
declare -a missing_branches
declare -a missing_repos
 
while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | tr -d '\r')  # Remove CRLF
    [[ -z "$line" ]] && continue  # Skip empty lines
    IFS=',' read -r repo branch <<< "$line"
    # Trim spaces correctly
    repo=$(echo "$repo" | sed 's/^ *//;s/ *$//')
    branch=$(echo "$branch" | sed 's/^ *//;s/ *$//')
 
    if [[ -n "$repo" ]]; then
        repos+=("$repo")
        branches+=("$branch")
        if [[ -z "$branch" ]]; then
            missing_branches+=("$repo")
        fi
    fi
done < "$REPO_FILE"
 
# Check for missing branches
if [[ ${#missing_branches[@]} -gt 0 ]]; then
    echo "❌ Error: The following repositories are missing branch names:"
    for repo in "${missing_branches[@]}"; do
        echo "- $repo"
    done
    exit 1
fi
 
echo "✅ Processing ${#repos[@]} repositories..."
 
# Process each repository
for i in "${!repos[@]}"; do
    repo="${repos[$i]}"
    branch="${branches[$i]}"
    echo "🚀 Processing repository: $repo on branch $branch"
 
    # Execute CNES Report
    if ! java -jar "$SONAR_JAR" -a "$AUTHOR_NAME" -b "$branch" -o "$repo" -p "$repo" -s "$SONAR_URL" -t "$TOKEN"; then
        echo "⚠️ Warning: Repository '$repo' failed to process."
        missing_repos+=("$repo")
    fi
done
 
# Print missing repositories
if [[ ${#missing_repos[@]} -gt 0 ]]; then
    echo "------------------------------"
    echo "❌ The following repositories were not found in SonarQube:"
    for repo in "${missing_repos[@]}"; do
        echo "- $repo"
    done
    echo "------------------------------"
fi
 
echo "✅ Finished processing repositories!"
