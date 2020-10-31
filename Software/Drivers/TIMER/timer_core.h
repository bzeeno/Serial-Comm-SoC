#ifndef _TIMER_H_INCLUDED
#define _TIMER_H_INCLUDED

#include "io_rw.h"
#include "io_map.h"

class TimerCore {
    // register map
    enum {
        COUNTER_LOWER_REG = 0,  // lower 32 bits of counter
        COUNTER_UPPER_REG = 1,  // upper 16 bits of counter
        CTRL_REG = 2            // control register
    };
    
    // masks
    enum {
        GO_FIELD = 0x00000001, // bit 0 of ctrl_reg: enable
        CLR_FIELD = 0x00000002  // bit 1 of ctrl_reg: clear
    };

public:
    TimerCore(uint32_t core_base_addr); // constructor
    ~TimerCore();                       // destructor

    // methods
    void pause();                       // pause counter
    void go();                          // resume counter
    void clear();                       // clear counter to 0
    uint64_t read_tick();               // get num clocks elapsed
    uint64_t read_time();               // get time elapsed [microseconds]
    void sleep(uint64_t us);            // sleep for us microseconds
private:
    uint32_t base_addr;
    uint32_t ctrl;
};

#endif // _TIMER_H_INCLUDED
