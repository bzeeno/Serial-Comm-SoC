#include "i2c_core.h"

I2cCore::I2cCore(uint32_t core_base_addr, int freq) {
    m_base_addr = core_base_addr;    
    set_freq(freq);
}
I2cCore::~I2cCore() {}

void I2cCore::set_freq(int freq) {
    m_dvsr = (uint16_t) ( (SYS_CLK_FREQ*1000000) / freq / 4);
    io_write(m_base_addr, DVSR_REG, m_dvsr);
}

int I2cCore::ready() {
    return( (int)(io_read(m_base_addr, RD_DATA_REG) >> 9) & 0x01 );
}

void I2cCore::start() {
    //set_command(START_CMD);
    while(!ready()) {}
    io_write(m_base_addr, WR_DATA_REG, START_CMD);
}

void I2cCore::restart() {
    //set_command(RESTART_CMD);
    while(!ready()) {}
    io_write(m_base_addr, WR_DATA_REG, RESTART_CMD);
}

void I2cCore::stop() {
    //set_command(STOP_CMD);
    while(!ready()) {}
    io_write(m_base_addr, WR_DATA_REG, STOP_CMD);
}

void I2cCore::set_command(int cmd) {
    while(!ready()) {}
    io_write(m_base_addr, WR_DATA_REG, cmd);
}

int I2cCore::tx_byte(uint8_t tx_data, bool transmit_dev_addr) {
    int byte, rx_ack;
    byte = tx_data << 1; // place ack bit to transmit

    byte = byte | TX_CMD;

    while(!ready()) {}
    io_write(m_base_addr, WR_DATA_REG, byte); // write data

    while(!ready()) {}
    rx_ack = io_read(m_base_addr, RD_DATA_REG) & RD_ACK_FIELD;

    if (rx_ack == 0)
        return(0);
    else
        return(-1);
}

int I2cCore::tx_transaction(uint8_t *bytes, uint8_t dev_addr, int num_bytes, int restart_cmd) {
    uint8_t dev_byte; // this is the device address concatenated with the write signal (0)
    int rx_ack, tmp_ack, i;
    dev_byte = (dev_addr << 1);

    start();

    rx_ack = tx_byte(dev_byte);

    for (i=0; i<num_bytes; i++) {
        tmp_ack = tx_byte(*bytes);
        rx_ack = rx_ack + tmp_ack;
        bytes++;
    }

    if (restart_cmd == 1) {
        restart();
    }
    else {
        stop();
    }
    return(rx_ack);
}

int I2cCore::rx_byte(int final_transfer) {
	uint8_t rx_byte;
    int cmd_final; // concatenation of rx command and final transfer bool
    cmd_final = RX_CMD | final_transfer;

    while(!ready()) {}
    io_write(m_base_addr, WR_DATA_REG, cmd_final); // will hold ack bit if not final transfer; if final transfer -> will send ~ack which will end transmission

    while(!ready()) {}
    int r_data;
    r_data = io_read(m_base_addr, RD_DATA_REG);

    rx_byte = (io_read(m_base_addr, RD_DATA_REG) & NOT_RD_DATA_FIELD) >> 1;

    return(rx_byte);
}

int I2cCore::rx_transaction(uint8_t *bytes, uint8_t dev_addr, int num_bytes, int restart_cmd) {
    uint8_t dev_byte;
    int rx_ack, i;

    dev_byte = (dev_addr << 1) | 0x01; // 1 = rd operation

    start();

    rx_ack = tx_byte(dev_byte); // send address and rd op; receive ack bit from slave

    // loop to read num of bytes
    for(i = 0; i < (num_bytes - 1); i++) {
        *bytes = rx_byte(0);
        bytes++;
    }

    *bytes = rx_byte(1); // receive final byte of transaction

    if(restart_cmd == 1) {
        restart();
    }
    else {
        stop();    
    }
    return(rx_ack);
}
