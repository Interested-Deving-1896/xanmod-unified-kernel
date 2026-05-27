#!/usr/bin/env bash
# lib/log.sh — shared logging helpers

# colours (disabled when not a terminal or NO_COLOR is set)
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  _RESET='\033[0m'
  _BOLD='\033[1m'
  _CYAN='\033[0;36m'
  _GREEN='\033[0;32m'
  _YELLOW='\033[0;33m'
  _RED='\033[0;31m'
else
  _RESET='' _BOLD='' _CYAN='' _GREEN='' _YELLOW='' _RED=''
fi

log_info()  { echo -e "${_GREEN}[INFO]${_RESET}  $*"; }
log_warn()  { echo -e "${_YELLOW}[WARN]${_RESET}  $*" >&2; }
log_error() { echo -e "${_RED}[ERROR]${_RESET} $*" >&2; }
log_step()  { echo -e "\n${_BOLD}${_CYAN}==> Step $1: $2${_RESET}"; }
log_debug() { [[ "${DEBUG:-0}" == "1" ]] && echo -e "[DEBUG] $*" >&2 || true; }

die() {
  log_error "$*"
  exit 1
}
