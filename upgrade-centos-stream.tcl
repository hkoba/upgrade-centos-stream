#!/bin/sh
# -*- mode: tcl; coding: utf-8 -*-
# the next line restarts using wish \
exec tclsh "$0" ${1+"$@"}

# This script tries to upgrade CentOS Stream 8 to CS9.
#
# Each steps are taken from the following article:
# https://ahelpme.com/linux/centos-stream-9/how-to-upgrade-to-centos-stream-9-from-centos-stream-8/

package require cmdline

array set ::opts [cmdline::getKnownOptions ::argv {
    {n "dry-run"}
    {h "help"}
    {d "show commands in each steps"}
}]

source [file dirname [info script]]/steps.tcl

steps S -library {
    run.tcl
    centos-util.tcl
}

proc STEP args {
    S add {*}$args
}

STEP -doc {
    All installed packages should be updated to the latest versions.
} -command {
    RUN dnf update -y
}

STEP -doc {
    A cleanup of all packages, which are not required anymore.
} -command {
    set unneeded [=RUN dnf repoquery --unneeded]
    # set extras [=RUN dnf repoquery --extras]

    # XXX: filter the above

    if {$unneeded ne ""} {
        RUN dnf remove -y {*}$unneeded
    }
}

STEP -doc {
    Install the CentOS Stream 9 repositories.
} -command {
    RUN dnf install -y {*}[centos-util::latest-dist-rpms 9]

    RUN dnf -y \
        --releasever=9-stream \
        --allowerasing \
        --setopt=deltarpm=false \
        distro-sync

    RUN rpmdb --rebuilddb

    RUN dnf clean packages

    RUN dnf update -y

    RUN dnf -y groupupdate "Core" "Minimal Install"

    RUN cat {*}[glob /etc/*release]

    ** puts "OK: READY to reboot"
}

if {$::opts(h) || $::argv eq ""} {

    puts stderr "Usage: [file tail [info script]] \[-n\] STEPNO..."
    puts "Please choose steps to run from below:"
    foreach item [S List] {
        if {$::opts(d)} {
            puts "== $item"
            foreach cmd [S step expand [lindex $item 0]] {
                puts $cmd
            }
        } else {
            puts "  $item"
        }
        puts ""
    }
    exit 1

} else {
    foreach stepNo $::argv {
        foreach cmd [S step expand $stepNo] {
            {*}$cmd
        }
    }
}
