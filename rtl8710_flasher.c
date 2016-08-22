/*
 *
 * Copyright (C) 2016 Rebane, rebane@alkohol.ee
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
 * Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

#include "rtl8710.h"
#include <stdio.h>
#include "spi_flash.h"

#define MEM_START            (*(volatile uint32_t *)(BUFFER_ADDRESS + 0x00))
#define MEM_COMMAND          (*(volatile uint32_t *)(BUFFER_ADDRESS + 0x04))
#define MEM_STATUS           (*(volatile uint32_t *)(BUFFER_ADDRESS + 0x08))
#define MEM_PARAM            (*(volatile uint32_t *)(BUFFER_ADDRESS + 0x0C))
#define MEM_OFFSET           (*(volatile uint32_t *)(BUFFER_ADDRESS + 0x10))
#define MEM_LEN              (*(volatile uint32_t *)(BUFFER_ADDRESS + 0x14))
#define MEM_DATA             ((volatile uint8_t *)(BUFFER_ADDRESS + 0x20))

#define COMMAND_READ_ID      0
#define COMMAND_MASS_ERASE   1
#define COMMAND_SECTOR_ERASE 2
#define COMMAND_READ         3
#define COMMAND_WRITE        4
#define COMMAND_VERIFY       5

int __attribute__((section(".vectors"))) main(){
	uint32_t p, i, l;
	uint8_t read_buffer[16];

	__asm__("cpsid f");

	PERI_ON->PESOC_CLK_CTRL |= PERI_ON_CLK_CTRL_ACTCK_GPIO_EN | PERI_ON_CLK_CTRL_SLPCK_GPIO_EN; // enable gpio peripheral clock
	PERI_ON->SOC_PERI_FUNC1_EN |= PERI_ON_SOC_PERI_FUNC1_EN_GPIO; // enable gpio peripheral

	PERI_ON->GPIO_SHTDN_CTRL = 0xFF;
	PERI_ON->GPIO_DRIVING_CTRL = 0xFF;

	spi_flash_init();

	// read jedec info
	spi_flash_wait_busy();
	MEM_PARAM = spi_flash_jedec_id();
	spi_flash_wait_busy();

	while(1){
		MEM_START = 0x00000000;
		while(MEM_START == 0x00000000);
		if(MEM_COMMAND == COMMAND_READ_ID){
			MEM_PARAM = 0x00000000;
			spi_flash_wait_busy();
			MEM_PARAM = spi_flash_jedec_id();
			spi_flash_wait_busy();
		}else if(MEM_COMMAND == COMMAND_MASS_ERASE){
			spi_flash_wait_busy();
			spi_flash_cmd(0x06);
			spi_flash_wait_wel();
			spi_flash_cmd(0xC7);
			spi_flash_wait_busy();
			spi_flash_cmd(0x04);
			spi_flash_wait_busy();
		}else if(MEM_COMMAND == COMMAND_SECTOR_ERASE){
			spi_flash_wait_busy();
			spi_flash_cmd(0x06);
			spi_flash_wait_wel();
			spi_flash_sector_erase(MEM_OFFSET);
			spi_flash_wait_busy();
			spi_flash_cmd(0x04);
			spi_flash_wait_busy();
		}else if(MEM_COMMAND == COMMAND_READ){
			spi_flash_wait_busy();
			p = MEM_OFFSET;
			for(i = 0; i < MEM_LEN; i += 16, p += 16){
				spi_flash_read(p, (void *)&MEM_DATA[i], 16);
			}
			spi_flash_wait_busy();
		}else if(MEM_COMMAND == COMMAND_WRITE){
			for(p = 0; p < MEM_LEN; p += 256){
				spi_flash_wait_busy();
				spi_flash_cmd(0x06);
				spi_flash_wait_wel();
				spi_flash_write((MEM_OFFSET + p), (void *)&MEM_DATA[p], 256);
				spi_flash_wait_busy();
				spi_flash_cmd(0x04);
				spi_flash_wait_busy();
			}
		}else if(MEM_COMMAND == COMMAND_VERIFY){
			spi_flash_wait_busy();
			for(p = 0; p < MEM_LEN; p += 16){
				spi_flash_read((MEM_OFFSET + p), read_buffer, 16);
				l = MEM_LEN - p;
				if(l > 16)l = 16;
				for(i = 0; i < l; i++){
					if(read_buffer[i] != MEM_DATA[p + i]){
						break;
					}
				}
				if(i < l){
					MEM_STATUS = 0x00000001;
					MEM_PARAM = p;
					break;
				}
				spi_flash_wait_busy();
			}
		}else{
			MEM_STATUS = 0x00000001;
		}
	}
}

