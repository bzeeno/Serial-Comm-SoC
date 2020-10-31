#include "spi_core.h"

SpiCore::SpiCore(uint32_t core_base_addr, int freq, int cpol, int cpha) {
    m_base_addr = core_base_addr;
    set_freq(freq);         // set frequency, defult = 1MHz
    set_mode(cpol, cpha);   // set mode, default mode = 0
    write_ctrl_reg();
    write_ss_n(0xffffffff); // Select no slave 
}

SpiCore::~SpiCore() {}

int SpiCore::ready() {
    int ready;
    ready = (int) ( (io_read(m_base_addr, RD_DATA_REG) & READY_FIELD) >> 8 );
    return (ready);
}

void SpiCore::write_ss_n(uint32_t ss_n) {
    m_ss_n = ss_n;
    io_write(m_base_addr, WR_SS_N, m_ss_n);       
}

void SpiCore::write_ss_n(int ss_n_bit, int s) {
    bit_write(m_ss_n, s, ss_n_bit);
    io_write(m_base_addr, WR_SS_N, m_ss_n);
}

void SpiCore::set_freq(int freq) {
    m_dvsr = (uint16_t) ( (SYS_CLK_FREQ*1000000/(2*freq)) - 1 );
}

void SpiCore::set_mode(int cpol, int cpha) {
    m_cpol = cpol;
    m_cpha = cpha;
}

void SpiCore::write_ctrl_reg() {
    uint32_t ctrl_reg_val = 0;                      // initialize to 0
    ctrl_reg_val = m_cpha << 1;                     // insert cpha
    ctrl_reg_val = ctrl_reg_val | m_cpol;           // insert cpol
    ctrl_reg_val = (ctrl_reg_val << 16) | (m_dvsr); // insert divisor value
    io_write(m_base_addr, CTRL_REG, ctrl_reg_val);  // write to register
}

uint8_t SpiCore::transfer(uint8_t o_data) {
    uint32_t read_data;

    while(!ready()) {}; // wait until ready
    io_write(m_base_addr, WR_DATA_REG, (uint32_t) o_data); 
    while(!ready()) {}; // wait until ready
    read_data = (uint8_t) ( io_read(m_base_addr, RD_DATA_REG) & RD_DATA_FIELD );
    return (read_data);
}
