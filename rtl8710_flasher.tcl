set rtl8710_flasher_command_read_id      0
set rtl8710_flasher_command_mass_erase   1
set rtl8710_flasher_command_sector_erase 2
set rtl8710_flasher_command_read         3
set rtl8710_flasher_command_write        4
set rtl8710_flasher_command_verify       5

set rtl8710_flasher_mac_address_offset   0xA088

set rtl8710_flasher_ready                0
set rtl8710_flasher_capacity             0
set rtl8710_flasher_auto_erase           0
set rtl8710_flasher_auto_verify          0
set rtl8710_flasher_auto_erase_sector    0xFFFFFFFF

proc rtl8710_flasher_init {} {
	global rtl8710_flasher_firmware_ptr
	global rtl8710_flasher_buffer
	global rtl8710_flasher_capacity
	global rtl8710_flasher_ready
	global rtl8710_flasher_code

	if {[expr {$rtl8710_flasher_ready == 0}]} {
		echo "initializing RTL8710 flasher"
		halt
		mww [expr {$rtl8710_flasher_buffer + 0x08}] 0x00000000
		mww [expr {$rtl8710_flasher_buffer + 0x00}] 0x00000001
		array2mem rtl8710_flasher_code 32 $rtl8710_flasher_firmware_ptr [array size rtl8710_flasher_code]
		reg faultmask 0x01
		reg sp 0x20000000
		reg pc $rtl8710_flasher_firmware_ptr
		resume
		rtl8710_flasher_wait
		set id [rtl8710_flasher_mrw [expr {$rtl8710_flasher_buffer + 0x0C}]]
		set rtl8710_flasher_capacity [expr {2 ** [expr {($id >> 16) & 0xFF}]}]
		set rtl8710_flasher_ready 1
		echo "RTL8710 flasher initialized"
	}
	return ""
}

proc rtl8710_flasher_mrw {reg} {
	set value ""
	mem2array value 32 $reg 1
	return $value(0)
}

proc rtl8710_flasher_wait {} {
	global rtl8710_flasher_buffer
	while {[rtl8710_flasher_mrw [expr {$rtl8710_flasher_buffer + 0x00}]]} { }
}

proc rtl8710_flasher_load_block {local_filename offset len} {
	global rtl8710_flasher_buffer
	load_image $local_filename [expr {$rtl8710_flasher_buffer + 0x20 - $offset}] bin [expr {$rtl8710_flasher_buffer + 0x20}] $len
}

proc rtl8710_flasher_read_block {offset len} {
	global rtl8710_flasher_buffer
	global rtl8710_flasher_command_read
	mww [expr {$rtl8710_flasher_buffer + 0x04}] $rtl8710_flasher_command_read
	mww [expr {$rtl8710_flasher_buffer + 0x08}] 0x00000000
	mww [expr {$rtl8710_flasher_buffer + 0x10}] $offset
	mww [expr {$rtl8710_flasher_buffer + 0x14}] $len
	mww [expr {$rtl8710_flasher_buffer + 0x00}] 0x00000001
	rtl8710_flasher_wait
	set status [rtl8710_flasher_mrw [expr {$rtl8710_flasher_buffer + 0x08}]]
	if {[expr {$status > 0}]} {
		error "read error, offset $offset"
	}
}

proc rtl8710_flasher_write_block {offset len} {
	global rtl8710_flasher_buffer
	global rtl8710_flasher_command_write
	mww [expr {$rtl8710_flasher_buffer + 0x04}] $rtl8710_flasher_command_write
	mww [expr {$rtl8710_flasher_buffer + 0x08}] 0x00000000
	mww [expr {$rtl8710_flasher_buffer + 0x10}] $offset
	mww [expr {$rtl8710_flasher_buffer + 0x14}] $len
	mww [expr {$rtl8710_flasher_buffer + 0x00}] 0x00000001
	rtl8710_flasher_wait
	set status [rtl8710_flasher_mrw [expr {$rtl8710_flasher_buffer + 0x08}]]
	if {[expr {$status > 0}]} {
		error "write error, offset $offset"
	}
}

proc rtl8710_flasher_verify_block {offset len} {
	global rtl8710_flasher_buffer
	global rtl8710_flasher_command_verify
	mww [expr {$rtl8710_flasher_buffer + 0x04}] $rtl8710_flasher_command_verify
	mww [expr {$rtl8710_flasher_buffer + 0x08}] 0x00000000
	mww [expr {$rtl8710_flasher_buffer + 0x10}] $offset
	mww [expr {$rtl8710_flasher_buffer + 0x14}] $len
	mww [expr {$rtl8710_flasher_buffer + 0x00}] 0x00000001
	rtl8710_flasher_wait
	set status [rtl8710_flasher_mrw [expr {$rtl8710_flasher_buffer + 0x08}]]
	if {[expr {$status > 0}]} {
		set status [rtl8710_flasher_mrw [expr {$rtl8710_flasher_buffer + 0x0C}]]
		set status [expr {$status + $offset}]
		error "verify error, offset $status"
	}
}

proc rtl8710_flash_read_id {} {
	global rtl8710_flasher_buffer
	global rtl8710_flasher_capacity
	global rtl8710_flasher_command_read_id
	rtl8710_flasher_init
	mww [expr {$rtl8710_flasher_buffer + 0x04}] $rtl8710_flasher_command_read_id
	mww [expr {$rtl8710_flasher_buffer + 0x08}] 0x00000000
	mww [expr {$rtl8710_flasher_buffer + 0x00}] 0x00000001
	rtl8710_flasher_wait
	set id [rtl8710_flasher_mrw [expr {$rtl8710_flasher_buffer + 0x0C}]]
	set manufacturer_id [format "0x%02X" [expr {$id & 0xFF}]]
	set memory_type [format "0x%02X" [expr {($id >> 8) & 0xFF}]]
	set memory_capacity [expr {2 ** [expr {($id >> 16) & 0xFF}]}]
	echo "manufacturer ID: $manufacturer_id, memory type: $memory_type, memory capacity: $memory_capacity bytes"
}

proc rtl8710_flash_mass_erase {} {
	global rtl8710_flasher_buffer
	global rtl8710_flasher_command_mass_erase
	rtl8710_flasher_init
	mww [expr {$rtl8710_flasher_buffer + 0x04}] $rtl8710_flasher_command_mass_erase
	mww [expr {$rtl8710_flasher_buffer + 0x08}] 0x00000000
	mww [expr {$rtl8710_flasher_buffer + 0x00}] 0x00000001
	rtl8710_flasher_wait
}

proc rtl8710_flash_sector_erase {offset} {
	global rtl8710_flasher_buffer
	global rtl8710_flasher_command_sector_erase
	rtl8710_flasher_init
	mww [expr {$rtl8710_flasher_buffer + 0x04}] $rtl8710_flasher_command_sector_erase
	mww [expr {$rtl8710_flasher_buffer + 0x08}] 0x00000000
	mww [expr {$rtl8710_flasher_buffer + 0x10}] $offset
	mww [expr {$rtl8710_flasher_buffer + 0x00}] 0x00000001
	rtl8710_flasher_wait
}

proc rtl8710_flash_read {local_filename loc size} {
	global rtl8710_flasher_buffer
	global rtl8710_flasher_buffer_size
	rtl8710_flasher_init
	for {set offset 0} {$offset < $size} {set offset [expr {$offset + $rtl8710_flasher_buffer_size}]} {
		set len [expr {$size - $offset}]
		if {[expr {$len > $rtl8710_flasher_buffer_size}]} {
			set len $rtl8710_flasher_buffer_size
		}
		set flash_offset [expr {$loc + $offset}]
		echo "read offset $flash_offset"
		rtl8710_flasher_read_block $flash_offset $len
		dump_image /tmp/_rtl8710_flasher.bin [expr {$rtl8710_flasher_buffer + 0x20}] $len
		exec dd conv=notrunc if=/tmp/_rtl8710_flasher.bin "of=$local_filename" bs=1 "seek=$offset"
		echo "read $len bytes"
	}
}

proc rtl8710_flash_write {local_filename loc} {
	global rtl8710_flasher_buffer_size
	global rtl8710_flasher_sector_size
	global rtl8710_flasher_auto_erase
	global rtl8710_flasher_auto_verify
	global rtl8710_flasher_auto_erase_sector
	rtl8710_flasher_init
	set sector 0
	set size [file size $local_filename]
	for {set offset 0} {$offset < $size} {set offset [expr {$offset + $rtl8710_flasher_buffer_size}]} {
		set len [expr {$size - $offset}]
		if {[expr {$len > $rtl8710_flasher_buffer_size}]} {
			set len $rtl8710_flasher_buffer_size
		}
		set flash_offset [expr {$loc + $offset}]
		echo "write offset $flash_offset"
		rtl8710_flasher_load_block $local_filename $offset $len
		if {[expr {$rtl8710_flasher_auto_erase != 0}]} {
			for {set i $flash_offset} {$i < [expr {$flash_offset + $len}]} {incr i} {
				set sector [expr {$i / $rtl8710_flasher_sector_size}]
				if {[expr {$rtl8710_flasher_auto_erase_sector != $sector}]} {
					echo "erase sector $sector"
					rtl8710_flash_sector_erase [expr {$sector * $rtl8710_flasher_sector_size}]
					set rtl8710_flasher_auto_erase_sector $sector
				}
			}
		}
		rtl8710_flasher_write_block $flash_offset $len
		echo "wrote $len bytes"
		if {[expr {$rtl8710_flasher_auto_verify != 0}]} {
			echo "verify offset $flash_offset"
			rtl8710_flasher_verify_block $flash_offset $len
		}
	}
}

proc rtl8710_flash_verify {local_filename loc} {
	global rtl8710_flasher_buffer_size
	rtl8710_flasher_init
	set size [file size $local_filename]
	for {set offset 0} {$offset < $size} {set offset [expr {$offset + $rtl8710_flasher_buffer_size}]} {
		set len [expr {$size - $offset}]
		if {[expr {$len > $rtl8710_flasher_buffer_size}]} {
			set len $rtl8710_flasher_buffer_size
		}
		set flash_offset [expr {$loc + $offset}]
		echo "read offset $flash_offset"
		rtl8710_flasher_load_block $local_filename $offset $len
		echo "verify offset $flash_offset"
		rtl8710_flasher_verify_block $flash_offset $len
	}
}

proc rtl8710_flash_read_mac {} {
	global rtl8710_flasher_mac_address_offset
	global rtl8710_flasher_buffer
	rtl8710_flasher_init
	rtl8710_flasher_read_block $rtl8710_flasher_mac_address_offset 6
	set mac ""
	mem2array mac 8 [expr {$rtl8710_flasher_buffer + 0x20}] 6
	set res "MAC address: "
	append res [format %02X $mac(0)]
	append res ":" [format %02X $mac(1)]
	append res ":" [format %02X $mac(2)]
	append res ":" [format %02X $mac(3)]
	append res ":" [format %02X $mac(4)]
	append res ":" [format %02X $mac(5)]
	echo $res
}

proc rtl8710_flash_auto_erase {on} {
	global rtl8710_flasher_auto_erase
	if {[expr {$on != 0}]} {
		set rtl8710_flasher_auto_erase 1
		echo "auto erase on"
	} else {
		set rtl8710_flasher_auto_erase 0
		echo "auto erase off"
	}
}

proc rtl8710_flash_auto_verify {on} {
	global rtl8710_flasher_auto_verify
	if {[expr {$on != 0}]} {
		set rtl8710_flasher_auto_verify 1
		echo "auto verify on"
	} else {
		set rtl8710_flasher_auto_verify 0
		echo "auto verify off"
	}
}

proc rtl8710_reboot {} {
	mww 0xE000ED0C 0x05FA0007
}

