BeagleBone_PRU_DHT11_DHT22
========================== 

Read DHT11/22 temperature and humidity sensor from the Beaglebone PRU

This project was adapted from example apps at git://github.com/beagleboard/am335x_pru_package.git
The sensor is connected to P8_12
The PRU initiates a read from the sensor and polls the pin, clocking in the response
The high time and low time in microseconds of each bit (one start bit plus 40 data bits) is recorded in shared RAM.
The low time of the data bits should always be about 50 us
If the high time is 28 us, then the bit is a zero
If the high time is 70 us, the the bit is a one
I'm using 40 as the cutoff to classify bits as zero or one
After the PRU reads the sensor data into shared RAM it halts.
The C code analyzes the rsults in RAM and prints a bunch of debugging info. 

Example Output:
Result: 0 -- Low: 66, High: 69  //this is the start bit -- should be 80 us high, 80 us low

Result: 1 -- Low: 43, High: 19
Result: 2 -- Low: 43, High: 19
Result: 3 -- Low: 43, High: 56
Result: 4 -- Low: 44, High: 18
Result: 5 -- Low: 44, High: 19
Result: 6 -- Low: 43, High: 56
Result: 7 -- Low: 43, High: 57
Result: 8 -- Low: 43, High: 19

Result: 9 -- Low: 43, High: 19
Result: 10 -- Low: 43, High: 19
Result: 11 -- Low: 43, High: 19
Result: 12 -- Low: 43, High: 19
Result: 13 -- Low: 43, High: 19
Result: 14 -- Low: 44, High: 18
Result: 15 -- Low: 44, High: 19
Result: 16 -- Low: 43, High: 20

Result: 17 -- Low: 43, High: 19
Result: 18 -- Low: 43, High: 19
Result: 19 -- Low: 43, High: 19
Result: 20 -- Low: 43, High: 57
Result: 21 -- Low: 43, High: 19
Result: 22 -- Low: 43, High: 56
Result: 23 -- Low: 44, High: 56
Result: 24 -- Low: 43, High: 56

Result: 25 -- Low: 44, High: 19
Result: 26 -- Low: 43, High: 19
Result: 27 -- Low: 43, High: 19
Result: 28 -- Low: 43, High: 19
Result: 29 -- Low: 43, High: 19
Result: 30 -- Low: 43, High: 19
Result: 31 -- Low: 43, High: 19
Result: 32 -- Low: 43, High: 21

Result: 33 -- Low: 43, High: 19
Result: 34 -- Low: 43, High: 19
Result: 35 -- Low: 43, High: 56
Result: 36 -- Low: 43, High: 57
Result: 37 -- Low: 43, High: 56
Result: 38 -- Low: 44, High: 56
Result: 39 -- Low: 43, High: 19
Result: 40 -- Low: 43, High: 55

Byte: 1 -- 38
Byte: 2 -- 0
Byte: 3 -- 23
Byte: 4 -- 0
Byte: 5 -- 61
Example executed successfully.

This means Humidity is 38.0%, Temperature is 23.0 degrees C, and the checksum is correct (38 + 0 + 23 + 0 = 61)

I tested on a Beaglebone Black A6 with a DHT11 on pin P8_12
You will need to enable the PRU in the device tree (by loading a device tree overlay for example) before running the code.
