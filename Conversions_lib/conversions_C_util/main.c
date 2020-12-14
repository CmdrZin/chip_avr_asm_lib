/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2016 Nels D. "Chip" Pearson (aka CmdrZin)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * conversions_C_util.c
 *
 * Created: 12/13/2020 5:45:12 PM
 * Author : Chip
 *
 * Use Simulator in Debug mode to Demo.
 */ 

#include <avr/io.h>

#include "conversion_C_util.h"

uint8_t buf[2];

int main(void)
{
    /* Replace with your application code */
    while (1) 
    {
		bin2bcd_10_4(0x03FF, buf);	// 1023
		bin2bcd_10_4(0x01FF, buf);	// 511
		bin2bcd_10_4(0x00FF, buf);	// 255
		bin2bcd_10_4(0x0006, buf);	//   6
		bin2bcd_10_4(0x0101, buf);	// 257
		bin2bcd_10_4(0x0300, buf);	// 768
		bin2bcd_10_4(0x0142, buf);	// 322

		bin2bcd_13_4(0x1FFF, buf);	// 8191
		bin2bcd_13_4(0x01FF, buf);	// 511
		bin2bcd_13_4(0x0007, buf);	//   7
		bin2bcd_13_4(0x1101, buf);	// 4353

		bin2bcd_16_5(0xFFFF, buf);	// 65535
		bin2bcd_16_5(0x5116, buf);	// 20758
		bin2bcd_16_5(0x0050, buf);	//    80
		bin2bcd_16_5(0x1101, buf);	//  4353
    }
}

