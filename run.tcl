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
