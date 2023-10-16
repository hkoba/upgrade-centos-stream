package require snit

namespace eval steps {
    ::variable ourScriptFn [file normalize [info script]]
}

snit::type steps {
    variable myStepList
    variable myInterp

    option -library {}
    method library {} {
        lmap fn $options(-library) {file join [$type libDir] $fn}
    }
    typemethod libDir {} {
        file dirname [set ${type}::ourScriptFn]
    }

    constructor args {
        $self configurelist $args
        install myInterp using interp create $self.interp
        foreach lib [$self library] {
            uplevel #0 [list source $lib]
            $myInterp eval [list source $lib]
        }
    }

    method add args {
        lappend myStepList [step create %AUTO% {*}$args]
    }

    method List {} {
        lmap o $myStepList {list [incr i] [string trim [$o cget -doc]]}
    }

    method {step expand} {stepNo} {
        set cmd [$self step do $stepNo cget -command]
        $myInterp eval {
            set RESULT {}
            proc RUN args {lappend ::RESULT [list RUN {*}$args]}
            proc =RUN args {exec -ignorestderr {*}$args 2>@ stderr}
            proc **  args {lappend ::RESULT [list **  {*}$args]}
        }
        $myInterp eval $cmd
        $myInterp eval {set RESULT}
    }

    method {step do} {stepNo args} {
        [lindex $myStepList [expr {$stepNo-1}]] {*}$args
    }
}

snit::type steps::step {
    option -doc
    option -command
}
