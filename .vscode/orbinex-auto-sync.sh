#!/usr/bin/env bash
# Publishes the saved root index.html. Uses Bash bundled with Git for Windows.
# Run from the repository root, normally through the VS Code folder task.
set -u

log() { printf '[Orbinex] %s\n' "$*"; }

repo_dir=$(git rev-parse --show-toplevel 2>/dev/null) || {
  log 'Open de gekloonde Orbinex-Website-map in VS Code, niet een los HTML-bestand.'
  exit 1
}
cd "$repo_dir" || exit 1

valid_origin() {
  local origin_url push_url
  origin_url=$(git config --get-all remote.origin.url 2>/dev/null) || return 1
  case "$origin_url" in
    https://github.com/competitionrocketmg-sudo/Orbinex-Website|https://github.com/competitionrocketmg-sudo/Orbinex-Website.git|git@github.com:competitionrocketmg-sudo/Orbinex-Website.git|ssh://git@github.com/competitionrocketmg-sudo/Orbinex-Website.git) ;;
    *) return 1 ;;
  esac
  push_url=$(git config --get-all remote.origin.pushurl 2>/dev/null || true)
  [[ -z "$push_url" || "$push_url" == "$origin_url" ]]
}

valid_origin || {
  log 'Deze taak werkt alleen met competitionrocketmg-sudo/Orbinex-Website als origin.'
  exit 1
}

lock_dir=$(git rev-parse --git-path orbinex-autosync.lock)
if ! mkdir "$lock_dir" 2>/dev/null; then
  old_pid=$(cat "$lock_dir/pid" 2>/dev/null || true)
  if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
    log 'De automatische publicatie draait al.'
    exit 0
  fi
  rm -f "$lock_dir/pid"
  rmdir "$lock_dir" 2>/dev/null && mkdir "$lock_dir" 2>/dev/null || {
    log 'De taakvergrendeling kon niet worden geopend. Sluit andere Orbinex-taken.'
    exit 1
  }
fi
printf '%s\n' "$$" > "$lock_dir/pid"
cleanup() {
  rm -f "$lock_dir/pid"
  rmdir "$lock_dir" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 0' INT TERM

saved_hash() { git hash-object --path=index.html -- index.html 2>/dev/null; }

pending_only_index() {
  local remote_tip=$1 local_tip=$2 paths path
  paths=$(git log -m --format= --name-only --no-renames "$remote_tip..$local_tip" --) || return 1
  while IFS= read -r path; do
    [[ -z "$path" || "$path" == 'index.html' ]] || return 1
  done <<< "$paths"
}

published_hash=''
sync_index() {
  local expected_hash=$1 branch marker remote_tip local_tip current_hash
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  if [[ "$branch" != main ]]; then
    log 'Gepauzeerd: schakel terug naar de main-branch om te publiceren.'
    return 1
  fi
  if ! valid_origin; then
    log 'Gepauzeerd: de GitHub-bestemming is gewijzigd.'
    return 1
  fi
  for marker in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply sequencer index.lock; do
    if [[ -e "$(git rev-parse --git-path "$marker")" ]]; then
      log 'Gepauzeerd: rond eerst de andere Git-bewerking of het conflict af.'
      return 1
    fi
  done
  if [[ ! -s index.html || -L index.html ]]; then
    log 'Gepauzeerd: index.html ontbreekt, is leeg of is een symbolische link.'
    return 1
  fi
  if ! git var GIT_AUTHOR_IDENT >/dev/null 2>&1; then
    log 'Stel eerst je Git-naam en commit-e-mailadres in; zie .vscode/README.md.'
    return 1
  fi
  if ! git fetch --quiet origin main; then
    log 'Ophalen mislukt. Controleer internet en je GitHub-aanmelding; ik probeer opnieuw.'
    return 1
  fi
  remote_tip=$(git rev-parse FETCH_HEAD) || return 1
  local_tip=$(git rev-parse HEAD) || return 1
  if ! git merge-base --is-ancestor "$remote_tip" "$local_tip"; then
    log 'GitHub heeft nieuwere wijzigingen. Stop deze taak en haal die eerst op via Git: Pull.'
    return 1
  fi
  if ! pending_only_index "$remote_tip" "$local_tip"; then
    log 'Er staan lokale commits voor andere bestanden klaar. Verstuur die eerst handmatig.'
    return 1
  fi
  current_hash=$(saved_hash) || return 1
  [[ "$current_hash" == "$expected_hash" ]] || return 2

  if ! git diff --quiet HEAD -- index.html; then
    if ! git commit --only -m 'Update Orbinex website' -- index.html; then
      log 'Commit mislukt. Je lokale bestand blijft bewaard; bekijk de Git-melding hierboven.'
      return 1
    fi
  fi
  local_tip=$(git rev-parse HEAD) || return 1
  if ! pending_only_index "$remote_tip" "$local_tip"; then
    log 'Gepauzeerd: er is intussen een commit voor een ander bestand toegevoegd.'
    return 1
  fi
  if [[ "$local_tip" != "$remote_tip" ]]; then
    # Push this exact checked commit, with no force option and no extra refs.
    if ! git push --no-follow-tags origin "$local_tip:refs/heads/main"; then
      log 'Upload mislukt. De commit blijft lokaal bewaard; ik probeer opnieuw zonder te overschrijven.'
      return 1
    fi
    log 'index.html staat op GitHub. GitHub Pages verwerkt de nieuwe versie.'
  fi
  published_hash=$(git rev-parse "$local_tip:index.html") || return 1
  return 0
}

if [[ "${1:-}" == '--once' ]]; then
  initial_hash=$(saved_hash) || exit 1
  sync_index "$initial_hash"
  exit $?
fi

log 'Actief: sla index.html op met Ctrl+S. Na 5 seconden zonder nieuwe opslag wordt het gepubliceerd.'
log 'Stoppen: Ctrl+C in deze terminal of Tasks: Terminate Task.'
last_hash=''
next_attempt=0
while true; do
  current_hash=$(saved_hash || true)
  if [[ -n "$current_hash" && "$current_hash" != "$last_hash" ]]; then
    last_hash=$current_hash
    next_attempt=$((SECONDS + 5))
  fi
  if [[ -n "$current_hash" && "$current_hash" != "$published_hash" ]] && (( SECONDS >= next_attempt )); then
    sync_index "$current_hash"
    next_attempt=$((SECONDS + 60))
  fi
  sleep 1
done
