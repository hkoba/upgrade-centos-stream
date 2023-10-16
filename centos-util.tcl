#!/bin/sh
# -*- mode: tcl; coding: utf-8 -*-
# the next line restarts using wish \
exec tclsh "$0" ${1+"$@"}

package require http
if {![catch {package require tls}]} {
    # "-autoservername true" for "error: sslv3 alert handshake failure"
    # See: https://wiki.tcl-lang.org/page/HTTPS
    http::register https 443 [list tls::socket -autoservername true]
}

namespace eval centos-util {
    ::variable distUrl https://mirror.stream.centos.org/%d-stream/BaseOS/x86_64/os/Packages/
    ::variable distPkgs {
        centos-stream-repos-9.*.noarch.rpm
        centos-stream-release-9.*.noarch.rpm
        centos-gpg-keys-9.*.noarch.rpm
    }

    proc latest-dist-rpms {ver} {
        ::variable distUrl
        ::variable distPkgs

        set dict [list-rpms [format $distUrl $ver] $distPkgs]
        set baseUrl [dict get $dict baseUrl]
        set result []
        foreach key $distPkgs {
            lappend result $baseUrl[lindex [lsort -dictionary [dict get $dict $key]] end]
        }
        set result
    }

    proc list-rpms {url {globList {"*.rpm"}}} {
        fetchURLvar token $url
        upvar #0 $token state
        set baseUrl $state(url)
        if {[http::ncode $token] != 200} {
            error "Failed to fetch url($baseUrl): [http::data $token]"
        }
        set result [dict create baseUrl $baseUrl]
        foreach {- fn} [regexp -all -inline {<a href="([^\"]*)">} \
                            [http::data $token]] {
            foreach glob $globList {
                if {[string match $glob $fn]} {
                    dict lappend result $glob $fn
                    continue
                }
            }
        }
        set result
    }

    proc fetchURLvar {varName url} {
        upvar 1 $varName token
        set token [http::geturl $url]
        uplevel 1 [list scope_guard $varName [list http::cleanup $token]]
        while {[http::ncode $token] >= 300 && [http::ncode $token] < 400} {
            set meta [dict map {key value} [http::meta $token] {
                set key [string tolower $key]
                set value
            }]
            set url [dict get $meta location]
            puts "redirected to: $url"
            http::cleanup $token
            set token [http::geturl $url]
        }
        set token
    }

    proc scope_guard {varName command} {
        upvar 1 $varName var
        uplevel 1 [list trace add variable $varName unset \
                       [list apply [list args $command]]]
    }
}

if {![info level] && [info exists ::argv0] && [info script] eq $::argv0} {
    puts [join [centos-util::latest-dist-rpms 9] \n]
}
