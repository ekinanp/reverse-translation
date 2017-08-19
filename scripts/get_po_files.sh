#!/usr/bin/env bash

REPOS_DIR_ROOT="translated-repos"
REPOS=(
  "pe-console-ui"
  "jdbc-util"
  "clj-rbac-client"
  "pe-console-auth-ui"
  "classifier"
  "pe-rbac-service"
  "pe-activity-service"
  "orchestrator"
  "pcp-broker"
  "clj-pcp-client"
  "bouncer-validators"
  "clj-pxp-puppet"
  "orchestrator-client"
  "puppet-forge-web"
  "puppet"
  "puppet-access"
  "higgs"
  )
PO_FILES_DIR_ROOT="resources/ja"
PUPPET_GIT_URL="git@github.com:puppetlabs"

is_japanese_po_file() {
  file="$1"
  if [[ -z `grep "Language: ja_JP" "$file"` ]]; then
    return 1
  fi 

  return 0
}

get_all_po_files() {
  repo="$1"
  repo_dir="${REPOS_DIR_ROOT}/${repo}"
  cwd=`pwd`

  # if repo_dir exists, then git pull to get
  # latest changes, else clone it.
  if [[ -d "$repo_dir" ]]; then
    cd "$repo_dir"
    git pull
    cd "$cwd"
  else
    cd "$REPOS_DIR_ROOT"
    git clone "${PUPPET_GIT_URL}/${repo}.git" 
    cd "$cwd"
  fi
 
  # at this point, we should be at the directory
  # we were in when calling this routine. our repo
  # should have been created.
  counter=0
  for po_file in `find "${repo_dir}" -name "*.po"`; do
    if is_japanese_po_file "$po_file"; then
      cp "$po_file" "${PO_FILES_DIR_ROOT}/${repo}${counter}.po"
      counter=$((counter+1))
    fi
  done
}

mkdir ${PO_FILES_DIR_ROOT}

# Core loop to do the processing work
for repo in "${REPOS[@]}"; do
  get_all_po_files "$repo"
done
