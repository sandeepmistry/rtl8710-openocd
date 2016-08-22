source [find target/swj-dp.tcl]

if { [info exists CHIPNAME] } {
	set _CHIPNAME $CHIPNAME
} else {
	set _CHIPNAME rtl8710
}

if { [info exists ENDIAN] } {
	set _ENDIAN $ENDIAN
} else {
	set _ENDIAN little
}

if { [info exists WORKAREASIZE] } {
	set _WORKAREASIZE $WORKAREASIZE
} else {
	set _WORKAREASIZE 0x800
}

if { [info exists CPUTAPID] } {
	set _CPUTAPID $CPUTAPID
} else {
	set _CPUTAPID 0x2ba01477
}

swj_newdap $_CHIPNAME cpu -irlen 4 -expected-id $_CPUTAPID

set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME cortex_m -endian $_ENDIAN -chain-position $_TARGETNAME

$_TARGETNAME configure -work-area-phys 0x10001000 -work-area-size $_WORKAREASIZE -work-area-backup 0

adapter_khz 500
adapter_nsrst_delay 100

if {![using_hla]} {
	cortex_m reset_config sysresetreq
}

