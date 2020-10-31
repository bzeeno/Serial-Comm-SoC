#define _DEBUG

#include "init.h"
#include "gpio_core.h"
#include "spi_core.h"
#include "i2c_core.h"
#include <stdio.h>
#include <math.h>

// Function Prototypes
void chasing_led(GpoCore *led_ptr, GpiCore *sw_ptr);
void gsensor_check(SpiCore* spi_ptr, GpoCore* led_ptr);
void get_temp(I2cCore *i2c_ptr);

// Class instantiation
// instantiate leds, switches
GpoCore led(get_slot_addr(BRIDGE_BASE, S2_LED));
GpiCore sw(get_slot_addr(BRIDGE_BASE, S3_SW));
// instantiate spi core
SpiCore spi(get_slot_addr(BRIDGE_BASE, S4_SPI));
// instantiate i2c core
I2cCore i2c(get_slot_addr(BRIDGE_BASE, S5_I2C));


int main() {
    while(1) {
        gsensor_check(&spi, &led);
        get_temp(&i2c);
        chasing_led(&led, &sw);
    }
}


void chasing_led(GpoCore *led_ptr, GpiCore *sw_ptr){
	const uint8_t NUM_LED = 8;
    uint16_t sleep_time; // sleep time in ms
    uint8_t dir; // direction of chasing leds
    uint8_t sw_val = 0; // val of sw1 - sw5 in binary
    int8_t speed_switches [5];

    // get switches
    for(int8_t s = 0; s<5; s++) {
        speed_switches[s] = sw_ptr->read(s+11); // get values of switches 11 to 15
    }

    // get value of switches in binary
    for(int8_t s = 0; s<5; s++) {
        sw_val = sw_val + speed_switches[s]*pow(2,s); 
    }

    // calculate speed of leds based on binary val sw_val
    // sleep_time will determine speed. lower sleep_time = faster speed
    sleep_time = -8*sw_val + 400; // equation where max sleep_time is 400, min sleep_time is 150. And, as sw_val increses, sleep_time decreases (lights speed up)  

    // get direction of chasing leds (switch 10 determines direction)
    dir = sw_ptr->read(10); // if 1 -> go right, if 0 -> go left
     
    if(dir == 1) {
        for (uint8_t i = NUM_LED+8; i > 8; i--) { // offset leds to the leftmost 8 leds
            led_ptr->write(1, i);
            sleep_ms(sleep_time);
            led_ptr->write(0, i);
            sleep_ms(sleep_time);
        }
    }
    else {
        for (uint8_t i = 8; i < NUM_LED+8; i++) { // offset leds to the leftmost 8 leds
            led_ptr->write(1, i);
            sleep_ms(sleep_time);
            led_ptr->write(0, i);
            sleep_ms(sleep_time);
            }
    }
}


void gsensor_check(SpiCore* spi_ptr, GpoCore* led_ptr) {
    const uint8_t RD_CMD = 0x0b;
    const uint8_t PART_ID_REG = 0x02;
    const uint8_t PWR_CTRL_REG = 0x2D; // power control register
    const uint8_t MSR_MODE = 0x02; // measurement mode
    const uint8_t DATA_REG = 0x08;
    const float data_range = 127.0/2.0; // 8-bit max val = 127 ; accelerometer max value = +/-2g
    int8_t x, y, z; // x,y,z values before processing
    float x_g, y_g, z_g; // x,y,z values in g's
    int id;

    // check id port
    spi_ptr->write_ss_n(0,0); // assert slave 0
    spi_ptr->transfer(RD_CMD); // read command
    spi_ptr->transfer(PART_ID_REG); // part id reg
    id = (int) spi_ptr->transfer(0x00); // send dummy byte (to read byte)
    spi_ptr->write_ss_n(1,0); // de-asssert slave 0

    // Set to measurement mode
    spi_ptr->write_ss_n(0,0); // assert slave 0
    spi_ptr->transfer(0x0A);
    spi_ptr->transfer(PWR_CTRL_REG);
    spi_ptr->transfer(0x02);
    spi_ptr->write_ss_n(1,0); // de-asssert slave 0

    // read 8-bit x,y,z values
    spi_ptr->write_ss_n(0,0); // assert slave 0
    spi_ptr->transfer(RD_CMD);
    spi_ptr->transfer(DATA_REG);
    x = spi_ptr->transfer(0x00);
    y = spi_ptr->transfer(0x00);
    z = spi_ptr->transfer(0x00);
    spi_ptr->write_ss_n(1,0); // de-assert slave 0
    // Get values in g's
    x_g = (float) x/data_range;
    y_g = (float) y/data_range;
    z_g = (float) z/data_range;

    // Light LEDs depending on rotation of FPGA
    // Range for accel to be considered = 1g
    float lower_lim = 0.8;
    float upper_lim = 1.2;

    // 0 degrees
    if( (z_g <= -lower_lim) & (z_g >= -upper_lim) ) {
        led_ptr->write(1,0);
        // turn off others
        led_ptr->write(0,1);
        led_ptr->write(0,2);
        led_ptr->write(0,3);
    }
    // 90 degrees
    else if( ((y_g <= -lower_lim) & (y_g >= -upper_lim)) | ((x_g >= lower_lim) & (x_g <= upper_lim)) ) {
        led_ptr->write(1,1);
        // turn off others
        led_ptr->write(0,0);
        led_ptr->write(0,2);
        led_ptr->write(0,3);
    }
    // 180 degrees
    else if( (z_g >= lower_lim) & (z_g <= upper_lim) ) {
        led_ptr->write(1,2);
        // turn off others
        led_ptr->write(0,0);
        led_ptr->write(0,1);
        led_ptr->write(0,3);
    }
    else if( ((y_g >= lower_lim) & (y_g <= upper_lim)) | ((x_g <= -lower_lim) & (x_g >= -upper_lim)) ) {
        led_ptr->write(1,3);
        // turn off others
        led_ptr->write(0,0);
        led_ptr->write(0,1);
        led_ptr->write(0,2);
    }
    else {
        led_ptr->write(0,0);
        led_ptr->write(0,1);
        led_ptr->write(0,2);
        led_ptr->write(0,3);
    }
}


void get_temp(I2cCore *i2c_ptr) {
    const uint8_t DEV_ADDR = 0x4b;
    uint8_t tx_bytes[2], rx_bytes[2];
    uint16_t temp; // raw temperature readings
    float temp_c; // celsius temperature

    tx_bytes[0] = 0x0b; // register to read (holds ID)
    i2c_ptr->tx_transaction(tx_bytes, DEV_ADDR, 1, 1);

    // Receive part id
    i2c_ptr->rx_transaction(rx_bytes, DEV_ADDR, 1, 0);

    uart.disp("Read ADT7420 id (Should be 0xcb): ");
    uart.disp(rx_bytes[0],16);
    uart.disp("\n\r");

    tx_bytes[0] = 0x00;
    i2c_ptr->tx_transaction(tx_bytes, DEV_ADDR, 1, 1);
    i2c_ptr->rx_transaction(rx_bytes, DEV_ADDR, 2, 0);

    // Get temp value (stored in 2 bytes)
    temp = (uint16_t) rx_bytes[0];
    temp = (temp<<8) + (uint16_t) rx_bytes[1];
    if(temp & 0x8000) {
        temp = temp >> 3;
        temp_c = (float) ((int) temp - 8192) / 16;
    }
    else {
        temp = temp >> 3;
        temp_c = (float) temp / 16;
    }
    uart.disp("Temperature [C]: ");
    uart.disp(temp_c);
    uart.disp("\n\r");

    sleep_ms(1000);

}


