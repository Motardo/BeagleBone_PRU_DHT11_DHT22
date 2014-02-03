// *
// * PRU_memAccess_DDR_PRUsharedRAM.p
// *
// * Copyright (C) 2012 Texas Instruments Incorporated - http://www.ti.com/
// *
// *
// *  Redistribution and use in source and binary forms, with or without
// *  modification, are permitted provided that the following conditions
// *  are met:
// *
// *    Redistributions of source code must retain the above copyright
// *    notice, this list of conditions and the following disclaimer.
// *
// *    Redistributions in binary form must reproduce the above copyright
// *    notice, this list of conditions and the following disclaimer in the
// *    documentation and/or other materials provided with the
// *    distribution.
// *
// *    Neither the name of Texas Instruments Incorporated nor the names of
// *    its contributors may be used to endorse or promote products derived
// *    from this software without specific prior written permission.
// *
// *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// *
// *

// *
// * ============================================================================
// * Copyright (c) Texas Instruments Inc 2010-12
// *
// * Use of this software is controlled by the terms and conditions found in the
// * license agreement under which this software has been supplied or provided.
// * ============================================================================
// *


// *****************************************************************************/
// file:   PRU_memAccess_DDR_PRUsharedRAM.p
//
// brief:  PRU Example to access DDR and PRU shared Memory. 
//
//
//  (C) Copyright 2012, Texas Instruments, Inc
//
//  author     M. Watkins
//
//  version    0.1     Created
// *****************************************************************************/

// r2 holds pin number
// r3 points to gpio registers
// r4 loop counter
// r5 loop counter for microsecond
// r6 bits recievied counter
// r7 data recieved or error code

// P8_12 -- GPIO1_12 -- GPIO44 -- 0x0830 Pad Control -- $PINS Pin_Id 12
// GPIO Pad Control Registers -- 0x44E10000
// 0x37 -- MODE7 | INPUT | PU | PE
// 0x17 -- MODE7 | OUTPUT | PU | PE
// GPIO1 Base -- 0x4804C000
// Direction OE -- 0x134
// Data In -- 0x138
// Clear Data Out -- 0x190
// Set Data Out -- 0x194

#define delay_reg r4
#define low_micros r7
#define high_micros r8
#define current_bit r9
#define current_offset r10

#define DHT_WAIT_MICROS 250 // wait for signal pin to change value
#define DHT_REQ_MICROS 20000 // hold low to start request
#define MICROSECOND_ITERS 100

#define DHT_PIN_BIT 12
#define GPIO1 0x4804C000
#define GPIO_OE 0x134
#define GPIO_DATAIN 0x138
#define GPIO_CLEAR_DATA_OUT 0x190
#define GPIO_SET_DATA_OUT 0x194

.origin 0
.entrypoint MEMACCESS_DDR_PRUSHAREDRAM

#include "BeagleBone_PRU_DHT11_DHT22.hp"

MEMACCESS_DDR_PRUSHAREDRAM:

    // Enable OCP master port
    LBCO      r0, CONST_PRUCFG, 4, 4 //CONST_PRUCFG aka C4
    CLR     r0, r0, 4         // Clear SYSCFG[STANDBY_INIT] to enable OCP master port
    SBCO      r0, CONST_PRUCFG, 4, 4

    // Configure the programmable pointer register for PRU0 by setting c28_pointer[15:0] 
    // field to 0x0120.  This will make C28 point to 0x00012000 (PRU shared RAM).
    MOV     r0, 0x00000120
    MOV       r1, CTPPR_0
    ST32      r0, r1

    // Configure the programmable pointer register for PRU0 by setting c31_pointer[15:0] 
    // field to 0x0010.  This will make C31 point to 0x80001000 (DDR memory).
    MOV     r0, 0x00100000
    MOV       r1, CTPPR_1
    ST32      r0, r1

    //Load values from external DDR Memory into Registers R0/R1/R2
    LBCO      r0, CONST_DDR, 0, 12

    //Increment each register
    ADD       r0, r0, 1
    ADD       r1, r1, 2
    ADD       r2, r2, 3

    //Store values from read from the DDR memory into PRU shared RAM
    SBCO      r0, CONST_PRUSHAREDRAM, 0, 12

    // Check that signal is high for 200us (not busy)

    // Pull line low for 20 ms (request data)
      // Set direction to output
    MOV r3, GPIO1 | GPIO_OE  // 0x4804C134
    LBBO r2, r3, 0, 4 // read current directions for gpio port
    CLR r2, r2, DHT_PIN_BIT // clr r2.t12, make output
    SBBO r2, r3, 0, 4 // write direction
      // write zero to pin
    MOV r2, 1 << DHT_PIN_BIT
    MOV r3, GPIO1 | GPIO_CLEAR_DATA_OUT  // 0x4804C194
    SBBO r2, r3, 0, 4 // write to pin
      // delay 20 ms
    MOV r4, DHT_REQ_MICROS
    CALL delay_micros // uses r4 and r5

    // Release line, set back to input
      // write one to pin
    MOV r2, 1 << DHT_PIN_BIT
    MOV r3, GPIO1 | GPIO_SET_DATA_OUT  // 0x4804C190
    SBBO r2, r3, 0, 4 // write to pin
      // change direction to input
    MOV r3, GPIO1 | GPIO_OE  // 0x4804C134
    LBBO r2, r3, 0, 4 // read current directions for gpio port
    SET r2, r2, DHT_PIN_BIT // set r2.t12, make input
    SBBO r2, r3, 0, 4 // write direction

    // Wait for response
      //initialize counter
    MOV r6, 0
waiting:
      // delay one micro
    MOV r4, 1
    CALL delay_micros
      // read pin
    MOV r3, GPIO1 | GPIO_DATAIN  // 0x4804C138
    LBBO r2, r3, 0, 4 // read current pin states for gpio port
      // done if low, keep waiting if set
    QBBC dht_response_recieved, r2, DHT_PIN_BIT
      // increment counter, error if too many iters
    ADD r6, r6, 1
    QBEQ no_response_timeout, r6, DHT_WAIT_MICROS
    QBA waiting

    // Response recieved, so wait for 80 us high then get first bit
dht_response_recieved:
    MOV current_bit, 0
next_bit:
    // poll pin, incrementing low_micros until high
count_low_micros:
    MOV low_micros, 0
next_low_micro:
    QBEQ no_response_timeout, low_micros, DHT_WAIT_MICROS
    MOV delay_reg, 1
    CALL delay_micros
    INC low_micros
      // read pin
    MOV r3, GPIO1 | GPIO_DATAIN  // 0x4804C138
    LBBO r2, r3, 0, 4 // read current pin states for gpio port
    QBBC next_low_micro, r2, DHT_PIN_BIT
count_high_micros:
    MOV high_micros, 0
next_high_micro:
    QBEQ no_response_timeout, high_micros, DHT_WAIT_MICROS
    MOV delay_reg, 1
    CALL delay_micros
    INC high_micros
      // read pin
    MOV r3, GPIO1 | GPIO_DATAIN  // 0x4804C138
    LBBO r2, r3, 0, 4 // read current pin states for gpio port
    QBBS next_high_micro, r2, DHT_PIN_BIT
    // write data to RAM
no_response_timeout:
    LSL current_offset, current_bit, 3 // each bit uses 8 bytes (int low_micros, high_micros)
    SBCO low_micros, CONST_PRUSHAREDRAM, current_offset, 8
    INC current_bit
    QBNE next_bit, current_bit, 41 // including start bit
    QBA finished

    // delay r4 microseconds, use r5 as loop counter
delay_micros:
    QBNE one_microsecond, r4, 0
    RET
one_microsecond:
    MOV r5, MICROSECOND_ITERS
one_microsecond_loop:
    SUB r5, r5, 1
    QBLT one_microsecond_loop, r5, 0
    SUB r4, r4, 1
    QBA delay_micros

finished:
    // Send notification to Host for program completion
    MOV       r31.b0, PRU0_ARM_INTERRUPT+16

    // Halt the processor
    HALT


