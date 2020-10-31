#ifndef I2C
#define I2C

#include "init.h"

class I2cCore {
    // Register Map
    enum {
        RD_DATA_REG = 0,
        DVSR_REG    = 1,
        WR_DATA_REG = 2,
		DUMMY_REG   = 3
    };

    // Masks
    enum {
        RD_ACK_FIELD    	= 0x00000001, // RD_DATA_REG[0]
        NOT_RD_DATA_FIELD   = 0XFFFFFDFF, // RD_DATA_REG[8:1]
        READY_FIELD     	= 0x00000100, // RD_DATA_REG[9]
    };

    // Commands
    enum {
        START_CMD   = 0x00 << 9,
        TX_CMD      = 0x01 << 9,
        RX_CMD      = 0x02 << 9,
        RESTART_CMD = 0x03 << 9,
        STOP_CMD    = 0x04 << 9
    };

public:
    I2cCore(uint32_t core_base_addr, int freq = 100000);
    ~I2cCore();
    void set_freq(int freq);
    int ready();
    void start();
    void restart();
    void stop();
    void set_command(int cmd);
    int tx_byte(uint8_t tx_data, bool transmit_dev_addr = 0);
    int tx_transaction(uint8_t *bytes, uint8_t dev_addr, int num_bytes, int restart);
    int rx_byte(int final_transfer);
    int rx_transaction(uint8_t *bytes, uint8_t dev_addr, int num_bytes, int restart);
private:
    uint32_t m_base_addr;
    int m_cmd;
    uint16_t m_dvsr;
};

#endif
