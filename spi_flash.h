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

#ifndef _SPI_FLASH_H_
#define _SPI_FLASH_H_

#include <stdint.h>

void spi_flash_init();
uint16_t spi_flash_read(uint32_t address, void *buf, uint16_t count);
uint16_t spi_flash_write(uint32_t address, const void *buf, uint16_t count);
uint32_t spi_flash_jedec_id();
uint8_t spi_flash_status();
void spi_flash_cmd(uint8_t cmd);
void spi_flash_sector_erase(uint32_t address);
void spi_flash_wait_busy();
void spi_flash_wait_wel();

#endif

