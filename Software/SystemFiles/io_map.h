#ifndef _IO_MAP_INCLUDED
#define _IO_MAP_INCLUDED
#ifdef __cplusplus
extern "C" {
#endif

#define SYS_CLK_FREQ 100

// io base address for for microblaze MCS
#define BRIDGE_BASE 0xc0000000

// slot module definition
#define S0_SYS_TIMER 0
#define S1_UART1     1
#define S2_LED       2
#define S3_SW        3
#define S4_SPI       4
#define S5_I2C       5

#ifdef __cplusplus 
} // extern "C"
#endif

#endif
