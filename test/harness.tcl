
### macOS compaction test harness (appended to the "scid" script)
# env: T_ACTION = games | names | both    T_DLG = tk | native    T_LOG = log file
# Logs every stage with a timestamp; "T: DONE" at the end. A missing DONE means a hang.

set ::t_t0 [clock milliseconds]
proc bgerror {msg} { t_log "ERROR: $msg" }
set ::t_shot 0
proc t_log {msg} {
  set line "T: [format %6d [expr {[clock milliseconds] - $::t_t0}]] ms  $msg"
  puts $line
  catch {set f [open $::env(T_LOG) a]; puts $f $line; close $f}
}
proc t_shot {tag} {
  incr ::t_shot
  catch {exec screencapture -x [file join $::env(T_SHOTS) [format "%s-%02d-%s.png" $::env(T_NAME) $::t_shot $tag]]}
}

if {$::env(T_DLG) eq "tk"} {
  # use Tk's own (script) message box, which this harness can click
  source [file join $::tk_library msgbox.tcl]
  rename tk_messageBox t_native_messageBox
  proc tk_messageBox {args} { return [::tk::MessageBox {*}$args] }
}

# trace the stages of the compaction procs
foreach p {compactGames compactNames compactBoth closeProgressWindow progressWindow
           updateCompactWin raiseWin ::maint::Refresh ::windows::gamelist::Refresh} {
  if {[info commands $p] ne ""} {
    trace add execution $p enter [list apply {{p args} {t_log "enter $p"}} $p]
    trace add execution $p leave [list apply {{p args} {t_log "leave $p"}} $p]
  }
}
rename tk_messageBox t_tk_messageBox
proc tk_messageBox {args} {
  set i [lsearch $args -message]
  t_log "messagebox: [string map {"\n" " "} [lindex $args [expr {$i+1}]]]"
  after 300 {t_shot msgbox}
  set r [t_tk_messageBox {*}$args]
  t_log "messagebox answered: $r"
  return $r
}

# click Tk's script message boxes (T_DLG=tk); native ones are answered from outside
proc t_poll {} {
  set ws [winfo children .]
  if {[winfo exists .compactWin]} { lappend ws {*}[winfo children .compactWin] }
  foreach w $ws {
    if {[string match *__tk__messagebox $w] && [winfo ismapped $w]} {
      foreach b {yes ok} { if {[winfo exists $w.$b]} { $w.$b invoke; break } }
    }
  }
  after 500 t_poll
}

after 4000 {
  t_log "start: games [sc_compact stats games] names [sc_compact stats names]"
  t_poll
  makeCompactWin
  after 1500 {
    t_shot open
    t_log "invoke $::env(T_ACTION)"
    switch $::env(T_ACTION) {
      games { .compactWin.games.g invoke }
      names { .compactWin.names.n invoke }
      both  { .compactWin.buttons.both invoke }
    }
    t_log "after invoke"
    after 1500 {
      t_shot end
      t_log "end: games [sc_compact stats games] names [sc_compact stats names]"
      t_log "DONE"
      ::file::ExitFast
    }
  }
}
