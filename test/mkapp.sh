#!/bin/bash
# mkapp.sh <scid-dir>: build ScidvsMac.app like Steve's Mac release, with the
# Tcl/Tk frameworks embedded in Contents/Frameworks. Result: <scid-dir>/dist/ScidvsMac.app
set -e
cd "$1"
if ! make mac_app > mac_app.log 2>&1; then
  echo "make mac_app failed (probably the bundled engines), building the bundle without them:"
  grep -m5 -i "error" mac_app.log || true
  # same as mac_app, minus the engines
  make all_scid mac_rename > /dev/null
  A=dist/ScidvsMac.app/Contents
  mkdir -p $A/MacOS $A/Resources/data $A/Resources/books $A/Resources/bases $A/Resources/lang \
           $A/Resources/bitmaps $A/Resources/html/bitmaps/mini
  install -m 755 tkscid tcscid scid $A/MacOS/
  install -m 644 scid.eco $A/Resources/data/
  install -m 644 spelling.ssp $A/Resources/
  cp books/* $A/Resources/books/; cp bases/* $A/Resources/bases/
  cp tcl/lang/*.tcl $A/Resources/lang/; cp bitmaps/* $A/Resources/bitmaps/
  install -m 644 icons/scid.icns $A/Resources/
  install -m 644 Info.plist $A/
fi
A=dist/ScidvsMac.app/Contents
mkdir -p $A/Frameworks
cp -a /Library/Frameworks/Tcl.framework /Library/Frameworks/Tk.framework $A/Frameworks/
echo "== bundle:"; ls $A/MacOS; otool -L $A/MacOS/tkscid | grep -i "tcl\|tk"
