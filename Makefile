FIRMWARE_ADDRESS = 0x10001000
BUFFER = 0x10008000
BUFFER_SIZE = 262144
FLASH_SECTOR_SIZE = 4096

all:
	arm-none-eabi-gcc -Wall -g -Os -mlittle-endian -mlong-calls -mthumb -mcpu=cortex-m3 -mfloat-abi=soft -mthumb-interwork -ffunction-sections -ffreestanding -fsingle-precision-constant -Wstrict-aliasing=0 -Wl,-T,rtl8710.ld -nostartfiles -nostdlib -u main -Wl,--section-start=.text=$(FIRMWARE_ADDRESS) -DBUFFER=$(BUFFER) rtl8710_flasher.c spi_flash.c -o rtl8710_flasher.elf
	arm-none-eabi-objcopy -O binary rtl8710_flasher.elf rtl8710_flasher.bin
	gcc make_array.c -o make_array
	cp rtl8710_cpu.ocd rtl8710.ocd
	echo "set rtl8710_flasher_firmware_ptr $(FIRMWARE_ADDRESS)" >>rtl8710.ocd
	echo "set rtl8710_flasher_buffer $(BUFFER)" >>rtl8710.ocd
	echo "set rtl8710_flasher_buffer_size $(BUFFER_SIZE)" >>rtl8710.ocd
	echo >>rtl8710.ocd
	echo "array set rtl8710_flasher_code {" >>rtl8710.ocd
	./make_array <rtl8710_flasher.bin >>rtl8710.ocd
	echo "}" >>rtl8710.ocd
	echo >>rtl8710.ocd
	cat rtl8710_flasher.ocd >>rtl8710.ocd

clean:
	rm -rf rtl8710_flasher.elf rtl8710_flasher.bin make_array rtl8710.ocd

test:
	openocd -f interface/stlink-v2-1.cfg -f rtl8710.ocd -c "init" -c "reset halt" -c "rtl8710_flash_read_id" -c "shutdown"

