#ifndef _MASK_H_
#define _MASK_H_

#include <stdint.h>

#define mask8(mask, value)              ((((uint8_t)(value)) << __builtin_ctz((mask))) & ((uint8_t)(mask)))
#define mask8_set(target, mask, value)  do{ (target) = ((target) & ~((uint8_t)(mask))) | mask8(mask, value); }while(0)
#define mask8_get(target, mask)         (((target) & ((uint8_t)(mask))) >> __builtin_ctz((mask)))

#define mask16(mask, value)             ((((uint16_t)(value)) << __builtin_ctz((mask))) & ((uint16_t)(mask)))
#define mask16_set(target, mask, value) do{ (target) = ((target) & ~((uint16_t)(mask))) | mask16(mask, value); }while(0)
#define mask16_get(target, mask)        (((target) & ((uint16_t)(mask))) >> __builtin_ctz((mask)))

#define mask32(mask, value)             ((((uint32_t)(value)) << __builtin_ctz((mask))) & ((uint32_t)(mask)))
#define mask32_set(target, mask, value) do{ (target) = ((target) & ~((uint32_t)(mask))) | mask32(mask, value); }while(0)
#define mask32_get(target, mask)        (((target) & ((uint32_t)(mask))) >> __builtin_ctz((mask)))

#endif

