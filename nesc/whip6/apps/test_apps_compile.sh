#!/bin/bash
#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2016 InviNets Sp z o.o.
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files. If you do not find these files, copies can be found by writing
# to technology@invinets.com.
#


# I don't think it's worth testing these
DISABLED_BOARDS=(cc2531 cc2531emk)

DISABLED_APPS=()


# Exit on any failed command.
set -e

cd "`dirname "$0"`"

SUCCESSES=
FAILURES=

containsElement() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

APPS=${*:-*}

if ! smake --list-boards > /dev/null; then
    echo "Failed to list available boards."
    exit 1;
fi

BASE_DIR="$PWD"
for app in $APPS; do
  cd "$BASE_DIR"
  boards="$(echo "$app" | cut -d/ -f2 -s)"
  app="$(echo "$app" | cut -d/ -f1)"
  [ -d "$app" ] || continue
  cd "$app"
  [ -f build.spec ] || continue
  containsElement "$app" "${DISABLED_APPS[@]}" && continue
  [ -z "$boards" ] && boards="$(smake --list-boards || true)"
  for board in $boards; do
    containsElement "$board" "${DISABLED_BOARDS[@]}" && continue
    label="$app/$board"
    echo "--- TESTING $label"
    if smake $board; then
      SUCCESSES="$SUCCESSES $label"
    else
      FAILURES="$FAILURES $label"
    fi
  done
done

# Disable printing executed commands
set +x

print_list() {
  local i
  for i in $*; do
    echo "  $i"
  done
}

if [ -n "$SUCCESSES" ]; then
  echo "Successful builds:"
  print_list $SUCCESSES
fi

if [ -n "$FAILURES" ]; then
  echo "Failed builds:"
  print_list $FAILURES
  exit 1
else
  echo "All OK."
  exit 0
fi
