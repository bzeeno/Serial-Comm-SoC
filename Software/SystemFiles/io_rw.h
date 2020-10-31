#ifndef _IO_RW_H_INCLUDED
#define _IO_RW_H_INCLUDED

// To use int types (good for embedded programming)
#include <inttypes.h> 
#ifdef __cpluscplus
extern "C" {
#endif

// macro for reading
#define io_read(base_addr, offset) ( *(volatile uint32_t *)( (base_addr) + 4*(offset) ) )
// macro for writing
#define io_write(base_addr, offset, data) (*(volatile uint32_t *)((base_addr) + 4*(offset)) = (data))
// macro for getting slot address
#define get_slot_addr(mmio_base, slot) ( (uint32_t) ( (mmio_base) + (slot)*32*4) )

#ifdef __cpluscplus
} // extern C
#endif

#endif //_IO_RW_H_INCLUDED
