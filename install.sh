#!/usr/bin/env bash
# claude-cowork-bridge installer (Bash / Git Bash / macOS / Linux)
#
# Idempotent: copies the skill, seeds inbox/instructions only if they don't
# already exist. Safe to re-run.
#
# Two modes of invocation:
#   1. Piped:  curl -L https://raw.githubusercontent.com/PlayQodeX/claude-cowork-bridge/main/install.sh | bash
#   2. Local:  cd claude-cowork-bridge && ./install.sh

set -euo pipefail

REPO_URL="https://github.com/PlayQodeX/claude-cowork-bridge.git"

CLAUDE_DIR="${HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"
COWORK_SKILL_DIR="${SKILLS_DIR}/cowork"
INBOX_FILE="${CLAUDE_DIR}/cowork-inbox.md"
INSTRUCTIONS_FILE="${CLAUDE_DIR}/cowork-project-instructions.md"

# Resolve source directory. If invoked via curl|bash, ${BASH_SOURCE[0]} is empty
# or "/dev/stdin" and the local skill files are not present; clone to a temp dir.
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

CLEANUP_TMPDIR=""
if [[ -n "${SCRIPT_DIR}" && -f "${SCRIPT_DIR}/skills/cowork/SKILL.md" ]]; then
  SRC_DIR="${SCRIPT_DIR}"
else
  SRC_DIR="$(mktemp -d -t claude-cowork-bridge-XXXXXX)"
  CLEANUP_TMPDIR="${SRC_DIR}"
  echo "Fetching claude-cowork-bridge into ${SRC_DIR}..."
  git clone --depth 1 "${REPO_URL}" "${SRC_DIR}" >/dev/null 2>&1
fi

cleanup() {
  if [[ -n "${CLEANUP_TMPDIR}" && -d "${CLEANUP_TMPDIR}" ]]; then
    rm -rf "${CLEANUP_TMPDIR}"
  fi
}
trap cleanup EXIT

echo "Installing claude-cowork-bridge into ${CLAUDE_DIR}"

mkdir -p "${SKILLS_DIR}" "${COWORK_SKILL_DIR}"

echo "  - Skill -> ${COWORK_SKILL_DIR}/SKILL.md"
cp "${SRC_DIR}/skills/cowork/SKILL.md" "${COWORK_SKILL_DIR}/SKILL.md"

if [[ ! -f "${INBOX_FILE}" ]]; then
  echo "  - Inbox seed -> ${INBOX_FILE}"
  cp "${SRC_DIR}/templates/cowork-inbox.md" "${INBOX_FILE}"
else
  echo "  - Inbox already exists at ${INBOX_FILE} — leaving untouched"
fi

if [[ ! -f "${INSTRUCTIONS_FILE}" ]]; then
  echo "  - Cowork-side instructions -> ${INSTRUCTIONS_FILE}"
  cp "${SRC_DIR}/templates/cowork-project-instructions.md" "${INSTRUCTIONS_FILE}"
else
  echo "  - Cowork-side instructions already exist at ${INSTRUCTIONS_FILE} — leaving untouched"
fi

echo ""
echo "Done. Open Claude Code and run '/cowork' to verify the skill is registered."
echo ""
echo "Next steps:"
echo "  1. Open ${INBOX_FILE} and read the header."
echo "  2. (Optional) Open ${INSTRUCTIONS_FILE} and configure your upstream Claude conversation Project."
echo "  3. (Optional) Create ${CLAUDE_DIR}/cowork-config.json — see docs/configuration.md."
echo "  4. Paste a real finding below the '---' in the inbox and run '/cowork' in Claude Code."
