/*****************************************************************************
 * Project: ECONET (low Energy COnsumption NETworks)
 * This program reads the current input bit rate of each port and 
 * change the Xilinx Virtex II Pro clock frequency accordingly.
 *
 * This software works properly when the reference_router bitstream is
 * loaded on the FPGA
 * 
 * Copyright (c) 2012      Lightcomm. All right reserved.
 *
 * $COPYRIGHT$
 *
 * Usage: ./governor


// Copyright (c) 2013 Lightcomm s.r.l.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//

 *
 *****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <limits.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>

#include <net/if.h>

#include "../../../../lib/C/common/nf2util.h"
#include "../../lib/C/reg_defines_green_reference_router.h"
#include "nf_download_very_fast.c"

#define DEFAULT_IFACE   "nf2c0"
#define MICROSECONDS_TO_SLEEP 10000


static struct nf2device nf2;

struct struct_thread {
	struct nf2device nf2;
	double microseconds_to_sleep;
	unsigned long th1,th2,th3,th4;
	int reg_to_write;
};

short pg = 30;

unsigned long setLocalBitrate(unsigned long q0_val, unsigned long q0_val_old, unsigned long *b0) {
	if(q0_val<q0_val_old) {
		(*b0) = ULONG_MAX - q0_val_old;
                (*b0) = (*b0) + q0_val + 1;
        }
        else {
                (*b0) = q0_val-q0_val_old;
	}
}

void changeFrequency(struct struct_thread *param_thread, int val) {
	char ff[2][10];
	strcpy(ff[0],"62.5 MHz");
	strcpy(ff[1],"125 MHz");
	download_very_fast(val);
	writeReg(&(param_thread->nf2), param_thread->reg_to_write, val);
	printf("\nFREQUENCY: %d (%s)\n", val,ff[val]);
}

void *governor_function(void *arg) {
	unsigned q0_val;
	unsigned q1_val;
	unsigned q2_val;
	unsigned q3_val;
	unsigned long q0_val_old;
	unsigned long q1_val_old;
	unsigned long q2_val_old;
	unsigned long q3_val_old;
	unsigned long b0;
	unsigned long b1;
	unsigned long b2;
	unsigned long b3;

	double overall;
	unsigned short first=1;
	struct struct_thread *param_thread;

	double interval;
	double bytes;

	param_thread = (struct struct_thread *)arg;
	short int frequency = 100;
	short int hold_frequency = 100;

	while(1) {
      		readReg(&(param_thread->nf2), MAC_GRP_0_RX_QUEUE_NUM_BYTES_PUSHED_REG, &q0_val);
      		readReg(&(param_thread->nf2), MAC_GRP_1_RX_QUEUE_NUM_BYTES_PUSHED_REG, &q1_val);
      		readReg(&(param_thread->nf2), MAC_GRP_2_RX_QUEUE_NUM_BYTES_PUSHED_REG, &q2_val);
      		readReg(&(param_thread->nf2), MAC_GRP_3_RX_QUEUE_NUM_BYTES_PUSHED_REG, &q3_val);
     
      		if(!first) {
			setLocalBitrate(q0_val,q0_val_old,&b0);
			setLocalBitrate(q1_val,q1_val_old,&b1);
			setLocalBitrate(q2_val,q2_val_old,&b2);
			setLocalBitrate(q3_val,q3_val_old,&b3);

			interval = (double )MICROSECONDS_TO_SLEEP / 1000000;
			bytes = (double) (b0 + b1 + b2 + b3);
			overall = (bytes * 8) / interval;

			if(overall <= param_thread->th1) {
				frequency = 0;
			} else {
				frequency = 1;
			}

			//printf("\n\n\n\nthresho bitrate:%ld\n\n",param_thread->th1);
			//printf("\noverall bitrate:%f\n\n",overall);

			if(hold_frequency != frequency) {
				//printf("q0:%lu\n",q0_val);
				//printf("bitrate in q0:%lu bps\n",b0);
				//printf("q1:%lu\n",q1_val);
				//printf("bitrate in q1:%lu bps\n",b1);
				//printf("q2:%lu\n",q2_val);
				//printf("bitrate in q2:%lu bps\n",b2);
				//printf("q3:%lu\n",q3_val);
				//printf("bitrate in q3:%lu bps\n",b3);
				//printf("overall bitrate:%lf\n\n",overall);
				//printf("-------------------\n");
				//printf("Frequency: %d\n", frequency);
				//printf("-------------------\n");

				if(hold_frequency != 0 && frequency == 0)  {// From 125 MHz to 62.5 MHz
					int random_num = rand()%100;
					if(random_num > pg) {
						hold_frequency = frequency;
		                                changeFrequency(param_thread, frequency);
					}
				} 
				else { // From 62.5 MHz to 125 MHz
					hold_frequency = frequency;
				        changeFrequency(param_thread, frequency);
				}
				//hold_frequency = frequency;
				//changeFrequency(param_thread, frequency);
				usleep(2000);
			}
	      	} else {  
			first = 0;
	      	}
      
		q0_val_old = q0_val;
	      	q1_val_old = q1_val;
	      	q2_val_old = q2_val;
	      	q3_val_old = q3_val;

	      	usleep(param_thread->microseconds_to_sleep);
    	}
}

int main (int argc,char *argv[]) 
{
  	unsigned long q0_val, q1_val, q2_val, q3_val, ewma_val;
  	unsigned long q0_val_old, q1_val_old, q2_val_old, q3_val_old;
	unsigned long b0, b1, b2, b3;
	unsigned long overall;
	pthread_t governor_thread;
	struct struct_thread *param_thread = NULL;


	/********* NF2 INITIALIZATION **********************/
	nf2.device_name = DEFAULT_IFACE;
	if (check_iface(&nf2))
        {
                exit(1);
        }
        if (openDescriptor(&nf2))
        {
                exit(1);
        }
	/********* END NF2 INITIALIZATION ******************/

	param_thread = (struct struct_thread *)malloc(sizeof(struct struct_thread));

	param_thread->nf2 = nf2;
	param_thread->microseconds_to_sleep = MICROSECONDS_TO_SLEEP;
	param_thread->reg_to_write = 0x0000050;

	/**** POPULATE param_thread  *****/
	param_thread->th1 = 500000000.0 * 4;
	param_thread->th2 = 0;
	param_thread->th3 = 0;
	param_thread->th4 = 0;
	/**** END POPULATE param_thread  *****/

	if(pthread_create(&governor_thread,NULL,governor_function,param_thread)<0) {
		printf("pthread_create error for thread 1\n");
		exit(1);
	}


	// Call pthread_join if we want to wait for the termination of governor_thread. Else comment it
	int retcode = pthread_join(governor_thread,NULL);
        closeDescriptor(&nf2);
	free(param_thread);
        return 0;
}
