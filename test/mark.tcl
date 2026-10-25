# tcscid mark.tcl <base>: add 2 games with new names, mark them and 1 old game deleted
set b [sc_base open [lindex $argv 0]]
foreach {wh bl} {{Neu, Anton} {Neu, Berta} {Neu, Carl} {Neu, Dora}} {
  sc_game new
  sc_game tags set -white $wh -black $bl -event "Testturnier" -site "Testort"
  sc_move addSan e4 e5
  sc_game save 0
}
set n [sc_base numGames]
sc_search header -gameNumber [list [expr {$n-2}] $n] -filter RESET
sc_game flag delete filter 1
sc_base close
