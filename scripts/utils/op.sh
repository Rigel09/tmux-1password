#!/usr/bin/env bash

# ------------------------------------------------------------------------------

declare -r EXPECTED_MIN_OP_CLI_VERSION="2.0.0"

# ------------------------------------------------------------------------------

op::verify_version() {
  local op_version="$(op --version)"

  semver::compare "$op_version" "$EXPECTED_MIN_OP_CLI_VERSION"

  if [[ $? -eq 2 ]]; then
    tmux::display_message \
      "1Password CLI version is not compatible with this plugin: ${op_version} < ${EXPECTED_MIN_OP_CLI_VERSION}"

    return 1
  fi

  return 0
}

op::verify_session() {
  local connected_accounts_count="$(($(op account list | wc -l) - 1))"

  if [[ "$connected_accounts_count" -le 0 ]]; then
    prompt::ask "You haven't added any accounts to 1Password CLI. Would you like to add one now?"

    if prompt::answer_is_yes; then
      op account add

      if [[ $? -ne 0 ]]; then
        return 1
      fi

      tput clear
      tmux::display_message "Successfully added new account."
    else
      return 1
    fi
  fi

  if ! op::signin; then
    return 1
  fi
}

op::signin() {
  op signin \
    --cache \
    --force \
    --raw \
    --account="$(options::op_account)" >/dev/null

  exit_code=$?

  tput clear

  return "$exit_code"
}

op::get_all_items() {
  op item list \
    --cache \
    --categories="LOGIN,PASSWORD" \
    --tags="$(options::op_filter_tags)" \
    --vault="$(options::op_valut)"
}
