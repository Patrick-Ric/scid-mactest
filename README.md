# Scid vs PC - macOS GUI test

Builds Scid vs PC from the SourceForge SVN (https://sourceforge.net/p/scidvspc/code) on GitHub's macOS
runners (Tcl/Tk 8.6, Aqua) and runs an automated GUI test of "Compact database": it marks a few games of
the bundled `bases/matein2` as deleted, opens the compaction window, presses the buttons and answers the
message boxes. A run without "DONE" in its log counts as a hang. Logs and screenshots are uploaded as
artifacts.

Run it from the Actions tab ("Run workflow"), with the SVN revisions to test and optionally a patch from
`patches/`.

Scid vs PC is GPL; this repository contains only the test scripts.
