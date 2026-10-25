#!/bin/bash
# run.sh <scid-dir> <name> <action> <dlg>: one GUI compaction test; prints HANG or OK
D=$1; export T_NAME=$2 T_ACTION=$3 T_DLG=$4
T=$(cd "$(dirname "$0")" && pwd)
export T_LOG=$PWD/logs/$T_NAME.log T_SHOTS=$PWD/shots
mkdir -p logs shots db home
rm -f "$T_LOG"
cp "$D"/bases/matein2.s* db/ && for f in db/matein2.*; do mv "$f" "db/$T_NAME.${f##*.}"; done
"$D"/tcscid "$T"/mark.tcl db/$T_NAME > /dev/null
cat "$D"/scid "$T"/harness.tcl > "$D"/scid-test; chmod +x "$D"/scid-test
export HOME=$PWD/home
# native dialogs: press Return every 3 s from outside (needs accessibility rights)
if [ "$T_DLG" = native ]; then
  ( for i in $(seq 1 30); do sleep 3
      osascript -e 'tell application "System Events" to keystroke return' >> logs/$T_NAME.osa 2>&1; done ) &
  KEYS=$!
fi
"$D"/scid-test db/$T_NAME > logs/$T_NAME.out 2>&1 &
P=$!
for i in $(seq 1 90); do sleep 1; kill -0 $P 2>/dev/null || break; done
if kill -0 $P 2>/dev/null; then
  screencapture -x shots/$T_NAME-99-hang.png 2>/dev/null
  kill $P; sleep 1; kill -9 $P 2>/dev/null
fi
[ -n "$KEYS" ] && kill $KEYS 2>/dev/null
if grep -q "DONE" "$T_LOG" 2>/dev/null; then R=OK; else R=HANG; fi
echo "=== $T_NAME: $R (last stage: $(tail -1 "$T_LOG" 2>/dev/null))"
echo "$T_NAME $R" >> logs/summary.txt
