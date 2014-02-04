/*
 * PRU_memAccess_DDR_PRUsharedRAM.c
 *
 * Copyright (C) 2012 Texas Instruments Incorporated - http://www.ti.com/ 
 * 
 * 
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions 
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright 
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the 
 *    documentation and/or other materials provided with the   
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/

/*
 * ============================================================================
 * Copyright (c) Texas Instruments Inc 2010-12
 *
 * Use of this software is controlled by the terms and conditions found in the
 * license agreement under which this software has been supplied or provided.
 * ============================================================================
 */

/******************************************************************************
* PRU_memAccess_DDR_PRUsharedRAM.c
*
* The PRU reads three values from external DDR memory and stores these values 
* in shared PRU RAM using the programmable constant table entries.  The example 
* initially loads 3 values into the external DDR RAM.  The PRU configures its 
* Constant Table Programmable Pointer Register 0 and 1 (CTPPR_0, 1) to point 
* to appropriate locations in the DDR memory and the PRU shared RAM.  The 
* values are then read from the DDR memory and stored into the PRU shared RAM 
* using the values in the 28th and 31st entries of the constant table.
*
******************************************************************************/

/******************************************************************************
 * BeagelBone_PRU_DHT11_DHT22.c
 *
 * The PRU reads 41 bits of temperature and humidity data from the DHT11 (one
 * start bit and 40 data bits. Each bit's low time and high time in microseconds
 * is stored in the PRU shared memory. The C code analyzes the data and calculates
 * the temperature and humidity
 */

/******************************************************************************
* Include Files                                                               *
******************************************************************************/

// Standard header files
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <string.h>

// Driver header file
#include "prussdrv.h"
#include <pruss_intc_mapping.h>	 

/******************************************************************************
* Explicit External Declarations                                              *
******************************************************************************/

/******************************************************************************
* Local Macro Declarations                                                    *
******************************************************************************/

#define PRU_NUM 	 0
//#define ADDEND1	 	 0x98765400u
//#define ADDEND2		 0x12345678u
//#define ADDEND3		 0x10210210u

//#define DDR_BASEADDR     0x80000000
//#define OFFSET_DDR	 0x00001000
#define OFFSET_SHAREDRAM 2048		//equivalent with 0x00002000

#define PRUSS0_SHARED_DATARAM    4

/******************************************************************************
* Local Typedef Declarations                                                  *
******************************************************************************/


/******************************************************************************
* Local Function Declarations                                                 *
******************************************************************************/

static unsigned short LOCAL_examplePassed ( unsigned short pruNum );

/******************************************************************************
* Local Variable Definitions                                                  *
******************************************************************************/


/******************************************************************************
* Intertupt Service Routines                                                  *
******************************************************************************/


/******************************************************************************
* Global Variable Definitions                                                 *
******************************************************************************/

static void *sharedMem;
static unsigned int *sharedMem_int;

/******************************************************************************
* Global Function Definitions                                                 *
******************************************************************************/

int main (void)
{
    unsigned int ret;
    tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
    
    printf("\nINFO: Starting %s example.\r\n", "PRU_memAccess_DDR_PRUsharedRAM");
    /* Initialize the PRU */
    prussdrv_init ();		
    
    /* Open PRU Interrupt */
    ret = prussdrv_open(PRU_EVTOUT_0);
    if (ret)
    {
        printf("prussdrv_open open failed\n");
        return (ret);
    }
    
    /* Get the interrupt initialized */
    prussdrv_pruintc_init(&pruss_intc_initdata);

    /* Execute example on PRU */
    printf("\tINFO: Executing example.\r\n");
    prussdrv_exec_program (PRU_NUM, "./dht11.bin");

    /* Wait until PRU0 has finished execution */
    printf("\tINFO: Waiting for HALT command.\r\n");
    prussdrv_pru_wait_event (PRU_EVTOUT_0);
    printf("\tINFO: PRU completed transfer.\r\n");
    prussdrv_pru_clear_event (PRU0_ARM_INTERRUPT);

    /* Check if example passed */
    if ( LOCAL_examplePassed(PRU_NUM) )
    {
        printf("Example executed successfully.\r\n");
    }
    else
    {
        printf("Example failed.\r\n");
    }
    
    /* Disable PRU and close memory mapping*/
    prussdrv_pru_disable(PRU_NUM); 
    prussdrv_exit ();

    return(0);
}

/*****************************************************************************
* Local Function Definitions                                                 *
*****************************************************************************/

static unsigned short LOCAL_examplePassed ( unsigned short pruNum )
{
    unsigned int i, resultByteNum, checkSum;
    unsigned char resultBytes[8];

     /* Allocate Shared PRU memory. */
    prussdrv_map_prumem(PRUSS0_SHARED_DATARAM, &sharedMem);
    sharedMem_int = (unsigned int*) sharedMem;

    resultByteNum = 0;

    for (i = 0; i < 81; i += 2)
    {
    	unsigned int word, highMicros;
    	unsigned char theByte;

    	printf("Result: %d -- Low: %d, High: %d\n", i / 2, sharedMem_int[OFFSET_SHAREDRAM + i], sharedMem_int[OFFSET_SHAREDRAM + i + 1]);
    	highMicros = sharedMem_int[OFFSET_SHAREDRAM + i + 1];
    	theByte = resultBytes[resultByteNum] &= 0x000000FF;
    	theByte = theByte << 1; // shift what is already there
    	if (highMicros >= 40)
    	{
    		theByte = theByte | 0x01; // set lsb
    	}
    	else
    	{
    		//bit = 0;
    	}
    	resultBytes[resultByteNum] = theByte;

    	word = i % 16;
    	if (word == 0)
    	{
    		printf("\n");
    		resultByteNum++;
    	}
    }

    for (i = 1; i <=5; i++)
    {
    	printf("Byte: %d -- %d\n", i, resultBytes[i] & 0x000000FF);
    }

    checkSum = 0;
    for (i = 1; i <= 4; i++)
    {
    	checkSum += resultBytes[i];
    }
    return (resultBytes[5] == checkSum);
}
