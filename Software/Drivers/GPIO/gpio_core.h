#ifndef _GPIO_H_INCLUDED
#define _GPIO_H_INCLUDED

#include "init.h"

/******** GPO CORE ********/
class GpoCore {
public:
    // register map
    enum {
        DATA_REG = 0 // data register
    };
    GpoCore(uint32_t core_base_addr); // constructor
    ~GpoCore(); // Destructor (not used)
    // methods
    void write(uint32_t data); // write 32-bit word
    void write(int bit_value, int bit_pos); // write 1 bit
private:
    uint32_t base_addr;
    uint32_t wr_data; // GPO data reg
};


/******** GPI CORE ********/
class GpiCore {
public:
    enum {
        DATA_REG = 0
    };
    GpiCore(uint32_t core_base_addr); // constructor
    ~GpiCore();
    // methods
    uint32_t read(); // read 32-bit word
    int read(int bit_pos); // read 1 bit
private:
    uint32_t base_addr;
};

#endif //_GPIO_H_INCLUDED


