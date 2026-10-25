#!/bin/bash
# run.sh <scid-dir> <name> <action> <dlg> [term|app]: one GUI compaction test; prints HANG or OK
#   term: start scid from the terminal    app: start dist/ScidvsMac.app with "open" (see mkapp.sh)
D=$(cd "$1" && pwd); export T_NAME=$2 T_ACTION=$3 T_DLG=$4; MODE=${5:-term}
T=$(cd "$(dirname "$0")" && pwd)
export T_LOG=$PWD/logs/$T_NAME.log T_SHOTS=$PWD/shots
mkdir -p logs shots db home
rm -f "$T_LOG"
for f in "$D"/bases/matein2.s*; do cp "$f" "db/$T_NAME.${f##*.}"; done
# after "make mac_app" the tcscid in <scid-dir> looks for the frameworks inside the bundle
TCSCID="$D"/tcscid; [ "$MODE" = app ] && TCSCID="$D/dist/ScidvsMac.app/Contents/MacOS/tcscid"
"$TCSCID" "$T"/mark.tcl db/$T_NAME > /dev/null || echo "!! mark.tcl failed"
# native dialogs: press Return every 3 s from outside (needs accessibility rights)
if [ "$T_DLG" = native ]; then
  ( for i in $(seq 1 30); do sleep 3
      osascript -e 'tell application "System Events" to keystroke return' >> logs/$T_NAME.osa 2>&1; done ) &
  KEYS=$!
fi
if [ "$MODE" = app ]; then
  APP="$D/dist/ScidvsMac.app"
  cat "$D"/scid "$T"/harness.tcl > "$APP"/Contents/MacOS/scid; chmod +x "$APP"/Contents/MacOS/scid
  cat > /tmp/scid-test-env.tcl <<EOF
set ::env(T_NAME) {$T_NAME}; set ::env(T_ACTION) {$T_ACTION}; set ::env(T_DLG) {$T_DLG}
set ::env(T_LOG) {$T_LOG}; set ::env(T_SHOTS) {$T_SHOTS}
EOF
  open -n "$APP" --args "$PWD/db/$T_NAME"
  isrunning() { pgrep -f "ScidvsMac.app/Contents/MacOS/tkscid" > /dev/null; }
  sleep 3
  for i in $(seq 1 90); do sleep 1; isrunning || break; done
  if isrunning; then
    screencapture -x shots/$T_NAME-99-hang.png 2>/dev/null
    pkill -f "ScidvsMac.app/Contents/MacOS/tkscid"; sleep 1; pkill -9 -f "ScidvsMac.app/Contents/MacOS/tkscid"
  fi
  rm -f /tmp/scid-test-env.tcl
else
  cat "$D"/scid "$T"/harness.tcl > "$D"/scid-test; chmod +x "$D"/scid-test
  HOME=$PWD/home "$D"/scid-test db/$T_NAME > logs/$T_NAME.out 2>&1 &
  P=$!
  for i in $(seq 1 90); do sleep 1; kill -0 $P 2>/dev/null || break; done
  if kill -0 $P 2>/dev/null; then
    screencapture -x shots/$T_NAME-99-hang.png 2>/dev/null
    kill $P; sleep 1; kill -9 $P 2>/dev/null
  fi
fi
[ -n "$KEYS" ] && kill $KEYS 2>/dev/null
if grep -q "DONE" "$T_LOG" 2>/dev/null; then R=OK; else R=HANG; fi
echo "=== $T_NAME: $R (last stage: $(tail -1 "$T_LOG" 2>/dev/null))"
echo "$T_NAME $R" >> logs/summary.txt
