FIRMWARE_ADDRESS = 0x10001000
BUFFER_ADDRESS = 0x10008000
BUFFER_SIZE = 262144
FLASH_SECTOR_SIZE = 4096

all:
	arm-none-eabi-gcc -Wall -g -Os -mlittle-endian -mlong-calls -mthumb -mcpu=cortex-m3 -mfloat-abi=soft -mthumb-interwork -ffunction-sections -ffreestanding -fsingle-precision-constant -Wstrict-aliasing=0 -Wl,-T,rtl8710.ld -nostartfiles -nostdlib -u main -Wl,--section-start=.text=$(FIRMWARE_ADDRESS) -DBUFFER_ADDRESS=$(BUFFER_ADDRESS) rtl8710_flasher.c spi_flash.c -o rtl8710_flasher.elf
	arm-none-eabi-objcopy -O binary rtl8710_flasher.elf rtl8710_flasher.bin
	gcc make_array.c -o make_array
	echo "#" >rtl8710.ocd
	echo "# OpenOCD script for RTL8710" >>rtl8710.ocd
	echo "# Copyright (C) 2016 Rebane, rebane@alkohol.ee" >>rtl8710.ocd
	echo "#" >>rtl8710.ocd
	echo >>rtl8710.ocd
	cat rtl8710_cpu.tcl >>rtl8710.ocd
	echo "set rtl8710_flasher_firmware_ptr $(FIRMWARE_ADDRESS)" >>rtl8710.ocd
	echo "set rtl8710_flasher_buffer $(BUFFER_ADDRESS)" >>rtl8710.ocd
	echo "set rtl8710_flasher_buffer_size $(BUFFER_SIZE)" >>rtl8710.ocd
	echo "set rtl8710_flasher_sector_size $(FLASH_SECTOR_SIZE)" >>rtl8710.ocd
	echo >>rtl8710.ocd
	echo "array set rtl8710_flasher_code {" >>rtl8710.ocd
	./make_array <rtl8710_flasher.bin >>rtl8710.ocd
	echo "}" >>rtl8710.ocd
	echo >>rtl8710.ocd
	cat rtl8710_flasher.tcl >>rtl8710.ocd
	cp rtl8710.ocd script/rtl8710.ocd

clean:
	rm -rf rtl8710_flasher.elf rtl8710_flasher.bin make_array rtl8710.ocd

test:
	openocd -f interface/stlink-v2-1.cfg -f script/rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_flash_read_id" -c "shutdown"

mac:
	openocd -f interface/stlink-v2-1.cfg -f script/rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_flash_read_mac" -c "shutdown"

dump:
	openocd -f interface/stlink-v2-1.cfg -f script/rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_flash_read_id" -c "rtl8710_flash_read dump.bin 0 1048576" -c "shutdown"

restore:
	openocd -f interface/stlink-v2-1.cfg -f script/rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_flash_auto_erase 1" -c "rtl8710_flash_auto_verify 1" -c "rtl8710_flash_write dump.bin 0" -c shutdown

verify:
	openocd -f interface/stlink-v2-1.cfg -f script/rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_flash_verify dump.bin 0" -c shutdown

reset:
	openocd -f interface/stlink-v2-1.cfg -f script/rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_reboot" -c shutdown

