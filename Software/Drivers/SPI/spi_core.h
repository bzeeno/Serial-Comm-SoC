#ifndef SPI
#define SPI

#include "init.h"

class SpiCore {
    // Register Map
    enum {
        RD_DATA_REG = 0,
        WR_SS_N     = 1,
        CTRL_REG    = 2,
        WR_DATA_REG = 3
    };
    
    // Masks
    enum {
        RD_DATA_FIELD = 0x000000ff, // RD_DATA_REG[7:0]
        READY_FIELD   = 0X00000100, // RD_DATA_REG[8]
    };

public:
    SpiCore(uint32_t core_base_addr, int freq = 100000, int cpol = 0, int cpha = 0);
    ~SpiCore();
    int ready();
    void write_ss_n(uint32_t ss_n);
    void write_ss_n(int ss_n_bit, int s);
    void set_freq(int freq);
    void set_mode(int cpol, int cpha);
    void write_ctrl_reg();
    uint8_t transfer(uint8_t o_data);

private:
    uint32_t m_base_addr;
    uint32_t m_ss_n;
    int m_cpha, m_cpol;
    uint16_t m_dvsr;
};

#endif // SPI
