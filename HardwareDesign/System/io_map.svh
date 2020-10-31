`ifndef _IO_MAP
`define _IO_MAP

// system clock rate 
`define SYS_CLK_FREQ 100

// io base address for microBlaze mcs
`define BRIDGE_BASE 0xc0000000

// slot module definition
`define S0_SYS_TIMER 0
`define S1_UART1     1
`define S2_LED       2
`define S3_SW        3
`define S4_SPI       4
`define S5_I2C       5

`endif