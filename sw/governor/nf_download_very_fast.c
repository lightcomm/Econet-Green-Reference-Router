/*****************************************************************************
 * $Id: nf_download.c 6067 2010-04-01 22:36:26Z grg $
 *
 * Project: NetFPGA2, Stanford University
 * This program reads a Xilinx .bin or .bit file and downloads it to the
 * Virtex 2 Pro or Spartan on a NetFPGA board.
 *
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
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
/*
#include <sys/time.h>
#include <sys/resource.h>
#include <unistd.h>
*/

#include "nf_download.h"
#include "../../../../lib/C/common/nf2util.h"
#include "../../lib/C/reg_defines_2freq.h"

//#include "../common/nf2util.h"
//#include "../common/reg_defines.h"

#include <net/if.h>
#include <netinet/in.h>

#define DEFAULT_IFACE	"nf2c0"

unsigned int freq;
/* Global vars */
static struct nf2device nf2;

/*
  Checks for commandline args, intializes globals, then  begins code download.
*/
int download_very_fast(int frequency) {

   nf2.device_name = DEFAULT_IFACE;
   struct in_addr ip[32], mask[32], gw[32], gw_arp[32], ip_filter[32];
   unsigned int mac_hi[32];
   unsigned int mac_lo[32];
   unsigned int mac0_hi,mac0_lo;
   unsigned int mac1_hi,mac1_lo;
   unsigned int mac2_hi,mac2_lo;
   unsigned int mac3_hi,mac3_lo;

   /*if(argc<2) {
	printf("run <command> <0/1> (0 down; 1 up)\n");
	exit(1);
   }*/
   freq = frequency;
   if(freq!=0 && freq!=1) {
	printf("argument must be either 0 or 1!!!\n");
	exit(1);
   }

   if (check_iface(&nf2))
   {
	   exit(1);
   }
   if (openDescriptor(&nf2))
   {
      exit(1);
   }

   int i;
   char iface;
   unsigned int port[32];
 
   readReg(&nf2,ROUTER_OP_LUT_MAC_0_HI_REG,&mac0_hi);
   readReg(&nf2,ROUTER_OP_LUT_MAC_1_HI_REG,&mac1_hi);
   readReg(&nf2,ROUTER_OP_LUT_MAC_2_HI_REG,&mac2_hi);
   readReg(&nf2,ROUTER_OP_LUT_MAC_3_HI_REG,&mac3_hi);
   readReg(&nf2,ROUTER_OP_LUT_MAC_0_LO_REG,&mac0_lo);
   readReg(&nf2,ROUTER_OP_LUT_MAC_1_LO_REG,&mac1_lo);
   readReg(&nf2,ROUTER_OP_LUT_MAC_2_LO_REG,&mac2_lo);
   readReg(&nf2,ROUTER_OP_LUT_MAC_3_LO_REG,&mac3_lo);

   for(i=0; i<32;i++) {
	bzero(&ip_filter[i], sizeof(struct in_addr));
	writeReg(&nf2, ROUTER_OP_LUT_DST_IP_FILTER_TABLE_RD_ADDR_REG, i);
        readReg(&nf2, ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG, &ip_filter[i].s_addr);

        bzero(&gw_arp[i], sizeof(struct in_addr));
        /* write the row number */
        writeReg(&nf2, ROUTER_OP_LUT_ARP_TABLE_RD_ADDR_REG, i);

        /* read the four-touple (mac hi, mac lo, gw, num of misses) */
        readReg(&nf2, ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG, &mac_hi[i]);
        readReg(&nf2, ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG, &mac_lo[i]);
        readReg(&nf2, ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG, &gw_arp[i].s_addr);

        bzero(&ip[i], sizeof(struct in_addr));
        bzero(&mask[i], sizeof(struct in_addr));
        bzero(&gw[i], sizeof(struct in_addr));

        /* write the row number */
        writeReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_RD_ADDR_REG, i);

        /* read the four-tuple (ip, gw, mask, iface) from the hw registers */
        readReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG, &ip[i].s_addr);
        readReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG, &mask[i].s_addr);
        readReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG, &gw[i].s_addr);
        readReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG, &port[i]);

       }


      ResetDevice();

      writeReg(&nf2,ROUTER_OP_LUT_MAC_0_HI_REG,mac0_hi);
      writeReg(&nf2,ROUTER_OP_LUT_MAC_1_HI_REG,mac1_hi);
      writeReg(&nf2,ROUTER_OP_LUT_MAC_2_HI_REG,mac2_hi);
      writeReg(&nf2,ROUTER_OP_LUT_MAC_3_HI_REG,mac3_hi);
      writeReg(&nf2,ROUTER_OP_LUT_MAC_0_LO_REG,mac0_lo);
      writeReg(&nf2,ROUTER_OP_LUT_MAC_1_LO_REG,mac1_lo);
      writeReg(&nf2,ROUTER_OP_LUT_MAC_2_LO_REG,mac2_lo);
      writeReg(&nf2,ROUTER_OP_LUT_MAC_3_LO_REG,mac3_lo);
      for(i=0; i<32;i++) {
      	    writeReg(&nf2, ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG, ip_filter[i].s_addr);
            writeReg(&nf2, ROUTER_OP_LUT_DST_IP_FILTER_TABLE_WR_ADDR_REG, i);

	    /* read the four-tuple (ip, gw, mask, iface) from the hw registers */
            writeReg(&nf2, ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG, mac_hi[i]);
            writeReg(&nf2, ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG, mac_lo[i]);
            writeReg(&nf2, ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG, gw_arp[i].s_addr);

            /* write the row number */
            writeReg(&nf2, ROUTER_OP_LUT_ARP_TABLE_WR_ADDR_REG, i);

            /* read the four-tuple (ip, gw, mask, iface) from the hw registers */
            writeReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG, ip[i].s_addr);
            writeReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG, mask[i].s_addr);
            writeReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG, gw[i].s_addr);
            writeReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG, port[i]);

            /* write the row number */
            writeReg(&nf2, ROUTER_OP_LUT_ROUTE_TABLE_WR_ADDR_REG, i);
        
   }

   /* wait until the resets have been completed */
   usleep(1);

   closeDescriptor(&nf2);

   return SUCCESS;
}


/*
 * Reset the device
 */
void ResetDevice(void) {
   u_int val;

   /* Read the current value of the control register so that we can modify
    * it to do a reset */
   val = NF2_RD32(CPCI_CTRL);

   NF2_WR32(CPCI_CLK, freq);
   /* Write to the control register to reset it */
   NF2_WR32(CPCI_CTRL, val | 0x100);

   //NF2_WR32(CPCI_CLK, 0x0);
   /* Sleep for a while to let the reset complete */
   usleep(1);
}



/*
 * readReg - read a register
 */
u_int NF2_RD32(u_int addr)
{
   u_int val;

   if (readReg(&nf2, addr, &val))
   {
      fprintf(stderr, "Error reading register %x\n", addr);
      exit(1);
   }

   return val;
}

void NF2_WR32(u_int addr, u_int data)
{
   if (writeReg(&nf2, addr, data))
   {
      fprintf(stderr, "Error writing register %x\n", addr);
      exit(1);
   }
}


/* vim:set shiftwidth=3 softtabstop=3 expandtab: */
