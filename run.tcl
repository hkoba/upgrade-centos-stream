proc RUN args {
    puts "# $args"
    if {$::opts(n)} return
    =RUN {*}$args >@ stdout
}

proc =RUN args {
    exec -ignorestderr {*}$args 2>@ stderr
}

proc ** args {
    puts "# $args"
    if {$::opts(n)} return
    {*}$args
}

proc ?RUN? args {
    puts "# $args"
    if {$::opts(n)} return
    catch {exec -ignorestderr {*}$args >@ stdout 2>@ stderr}
}
