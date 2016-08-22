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

#include "spi_flash.h"
#include "rtl8710.h"
#include "mask.h"

static void spi_flash_send(uint8_t byte){
	// while(!(SPI_FLASH->SR & SPI_SR_TFNF));
	SPI_FLASH->DR = byte;
}

static uint8_t spi_flash_recv(){
	while(!(SPI_FLASH->RXFLR & 0x0FFF));
	return(SPI_FLASH->DR);
}

void spi_flash_init(){
	PERI_ON->PESOC_CLK_CTRL |= PERI_ON_CLK_CTRL_ACTCK_FLASH_EN | PERI_ON_CLK_CTRL_SLPCK_FLASH_EN; // enable spi flash peripheral clock
	PERI_ON->SOC_FUNC_EN |= PERI_ON_SOC_FUNC_EN_FLASH; // enable spi flash peripheral
	mask32_set(PERI_ON->CPU_PERIPHERAL_CTRL, PERI_ON_CPU_PERIPHERAL_CTRL_SPI_FLASH_PIN_SEL, 0); // select spi flash pinout (0 - internal)
	PERI_ON->CPU_PERIPHERAL_CTRL |= PERI_ON_CPU_PERIPHERAL_CTRL_SPI_FLASH_PIN_EN; // enable spi flash pins

	SPI_FLASH->SSIENR = 0; // disable SPI FLASH operation
	SPI_FLASH->IMR = 0; // disable all interrupts
	SPI_FLASH->SER = SPI_SER_SS0; // use first "slave select" pin
	SPI_FLASH->BAUDR = 2; // baud rate, default value
	SPI_FLASH->TXFTLR = 0; // tx fifo threshold
	SPI_FLASH->RXFTLR = 0; // rx fifo threshold
	SPI_FLASH->DMACR = 0; // disable DMA
}

uint16_t spi_flash_read(uint32_t address, void *buf, uint16_t count){
	uint16_t i;
	if(!count)return(0);
	if(count > 16)count = 16;
	SPI_FLASH->CTRLR0 = mask32(SPI_CTRLR0_TMOD, 3) | mask32(SPI_CTRLR0_CMD_CH, 0) | mask32(SPI_CTRLR0_ADDR_CH, 0) | mask32(SPI_CTRLR0_DATA_CH, 0);
	SPI_FLASH->CTRLR1 = count;

	spi_flash_send(0x03); // flash command "read"
	spi_flash_send((address >> 16) & 0xFF); // address * 3
	spi_flash_send((address >> 8) & 0xFF);
	spi_flash_send((address >> 0) & 0xFF);

	SPI_FLASH->SSIENR = 1;

	for(i = 0; i < count; i++){
		((uint8_t *)buf)[i] = spi_flash_recv();
	}
	while(SPI_FLASH->SR & SPI_SR_SSI);
	SPI_FLASH->SSIENR = 0;
	return(count);
}

uint32_t spi_flash_jedec_id(){
	uint32_t id;
	SPI_FLASH->CTRLR0 = mask32(SPI_CTRLR0_TMOD, 3) | mask32(SPI_CTRLR0_CMD_CH, 0) | mask32(SPI_CTRLR0_ADDR_CH, 0) | mask32(SPI_CTRLR0_DATA_CH, 0);
	SPI_FLASH->CTRLR1 = 3;

	SPI_FLASH->SSIENR = 1;
	spi_flash_send(0x9F); // jedec id
	id = spi_flash_recv();
	id |= ((uint32_t)spi_flash_recv() << 8);
	id |= ((uint32_t)spi_flash_recv() << 16);
	while(SPI_FLASH->SR & SPI_SR_SSI);
	SPI_FLASH->SSIENR = 0;
	return(id);
}

uint8_t spi_flash_status(){
	uint8_t status;
	SPI_FLASH->CTRLR0 = mask32(SPI_CTRLR0_TMOD, 3) | mask32(SPI_CTRLR0_CMD_CH, 0) | mask32(SPI_CTRLR0_ADDR_CH, 0) | mask32(SPI_CTRLR0_DATA_CH, 0);
	SPI_FLASH->CTRLR1 = 1;

	SPI_FLASH->SSIENR = 1;
	spi_flash_send(0x05); // read status
	status = spi_flash_recv();
	while(SPI_FLASH->SR & SPI_SR_SSI);
	SPI_FLASH->SSIENR = 0;
	return(status);
}

void spi_flash_cmd(uint8_t cmd){
	SPI_FLASH->CTRLR0 = mask32(SPI_CTRLR0_TMOD, 1) | mask32(SPI_CTRLR0_CMD_CH, 0) | mask32(SPI_CTRLR0_ADDR_CH, 0) | mask32(SPI_CTRLR0_DATA_CH, 0);

	SPI_FLASH->SSIENR = 1;
	spi_flash_send(cmd);
	while(SPI_FLASH->SR & SPI_SR_SSI);
	SPI_FLASH->SSIENR = 0;
}

void spi_flash_sector_erase(uint32_t address){
	SPI_FLASH->CTRLR0 = mask32(SPI_CTRLR0_TMOD, 1) | mask32(SPI_CTRLR0_CMD_CH, 0) | mask32(SPI_CTRLR0_ADDR_CH, 0) | mask32(SPI_CTRLR0_DATA_CH, 0);

	SPI_FLASH->SSIENR = 1;
	spi_flash_send(0x20); // sector erase
	spi_flash_send((address >> 16) & 0xFF);
	spi_flash_send((address >> 8) & 0xFF);
	spi_flash_send((address >> 0) & 0xFF);
	while(SPI_FLASH->SR & SPI_SR_SSI);
	SPI_FLASH->SSIENR = 0;
}

uint16_t spi_flash_write(uint32_t address, const void *buf, uint16_t count){
	uint16_t i;
	if(!count)return(0);
	if(count > 256)count = 256;
	SPI_FLASH->CTRLR0 = mask32(SPI_CTRLR0_TMOD, 1) | mask32(SPI_CTRLR0_CMD_CH, 0) | mask32(SPI_CTRLR0_ADDR_CH, 0) | mask32(SPI_CTRLR0_DATA_CH, 0);

	SPI_FLASH->SSIENR = 1;
	spi_flash_send(0x02); // write
	spi_flash_send((address >> 16) & 0xFF);
	spi_flash_send((address >> 8) & 0xFF);
	spi_flash_send((address >> 0) & 0xFF);
	for(i = 0; i < count; i++){
		spi_flash_send(((uint8_t *)buf)[i]);
	}
	while(!(SPI_FLASH->SR & SPI_SR_TFE));
	while(SPI_FLASH->SR & SPI_SR_SSI);
	SPI_FLASH->SSIENR = 0;
	return(count);
}

void spi_flash_wait_busy(){
	while(spi_flash_status() & 0x01);
}

void spi_flash_wait_wel(){
	while(!(spi_flash_status() & 0x02));
}

