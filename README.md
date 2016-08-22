# RTL-8710 openocd support
OpenOCD support for RTL8710 and integrated flash.
## pins:
### SWD
* SWDIO:   GE3  
* SWCLK:   GE4  
### JTAG
* TRST:    GE0  
* TDI:     GE1  
* TDO:     GE2  
* TMS:     GE3  
* TCK:     GE4  
## building:
make
## available OpenOCD commands:
### rtl8710_flash_read_id
read and parse the jedec id bytes from flash
### rtl8710_flash_mass_erase
erase whole flash
### rtl8710_flash_read [filename] [offset] [size]
dump (size) bytes from flash offset (offset) to file (filename)
### rtl8710_flash_write [filename] [offset]
write file (filename) to flash offset (offset)
### rtl8710_flash_verify [filename] [offset]
compare file (filename) with flash offset (offset)
### rtl8710_flash_auto_erase [1/0]
set auto_erase option on/off. flash pages will be autoerased when writing
### rtl8710_flash_auto_verify [1/0]
set auto_verify option on/off. each block of data will be auto verified when writing
## examples:
```
openocd -f interface/stlink-v2-1.cfg -f rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_flash_read_id" -c "rtl8710_flash_read dump.bin 0 1048576" -c "shutdown"
```
```
openocd -f interface/stlink-v2-1.cfg -f rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_flash_auto_erase 1" -c "rtl8710_flash_auto_verify 1" -c "rtl8710_flash_write dump.bin 0" -c "shutdown"
```
