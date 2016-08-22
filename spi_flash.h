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

