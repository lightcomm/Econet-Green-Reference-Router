/*

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
///////////////////////////////////////////////////////////////////////////////
*/


#ifndef _NF2_DOWNLOAD_H
#define _NF2_DOWNLOAD_H

int bytes_sent;
char *log_file_name;
FILE *log_file;
char *bin_file_name;
FILE *bin_file;
u_int verbose;
u_int cpci_reprog;
u_int prog_addr;
u_int ignore_dev_info;
u_int intr_enable;

#define ROUTER_OP_LUT_MAC_0_HI_REG                        0x2000028
#define ROUTER_OP_LUT_MAC_0_LO_REG                        0x200002c
#define ROUTER_OP_LUT_MAC_1_HI_REG                        0x2000030
#define ROUTER_OP_LUT_MAC_1_LO_REG                        0x2000034
#define ROUTER_OP_LUT_MAC_2_HI_REG                        0x2000038
#define ROUTER_OP_LUT_MAC_2_LO_REG                        0x200003c
#define ROUTER_OP_LUT_MAC_3_HI_REG                        0x2000040
#define ROUTER_OP_LUT_MAC_3_LO_REG                        0x2000044

#define ROUTER_OP_LUT_DST_IP_FILTER_TABLE_ENTRY_IP_REG    0x2000074
#define ROUTER_OP_LUT_DST_IP_FILTER_TABLE_RD_ADDR_REG     0x2000078
#define ROUTER_OP_LUT_DST_IP_FILTER_TABLE_WR_ADDR_REG     0x200007c

#define ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_HI_REG          0x2000060
#define ROUTER_OP_LUT_ARP_TABLE_ENTRY_MAC_LO_REG          0x2000064
#define ROUTER_OP_LUT_ARP_TABLE_ENTRY_NEXT_HOP_IP_REG     0x2000068
#define ROUTER_OP_LUT_ARP_TABLE_RD_ADDR_REG               0x200006c
#define ROUTER_OP_LUT_ARP_TABLE_WR_ADDR_REG               0x2000070

#define ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_IP_REG            0x2000048
#define ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_MASK_REG          0x200004c
#define ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_NEXT_HOP_IP_REG   0x2000050
#define ROUTER_OP_LUT_ROUTE_TABLE_ENTRY_OUTPUT_PORT_REG   0x2000054
#define ROUTER_OP_LUT_ROUTE_TABLE_RD_ADDR_REG             0x2000058
#define ROUTER_OP_LUT_ROUTE_TABLE_WR_ADDR_REG             0x200005c

#define READ_BUFFER_SIZE 4096
#define SUCCESS 0
#define FAILURE 1

#define CPCI_PROGRAMMING_DATA    0x100
#define CPCI_PROGRAMMING_STATUS  0x104
#define CPCI_PROGRAMMING_CONTROL 0x108
#define CPCI_ERROR               0x010
#define CPCI_ID	                 0x000
#define CPCI_CTRL                0x008
#define CPCI_CLK		0x050

#define START_PROGRAMMING        0x00000001
#define DISABLE_RESET            0x00000100

#define VIRTEX_PROGRAM_CTRL_ADDR        0x0440000
#define VIRTEX_PROGRAM_RAM_BASE_ADDR    0x0480000

#define CPCI_BIN_SIZE            166980

#define VIRTEX_BIN_SIZE_V2_0     1448740
#define VIRTEX_BIN_SIZE_V2_1     2377668



void BeginCodeDownload(char *codefile_name);
void InitGlobals();
void FatalError();
void StripHeader(FILE *code_file);
void DownloadCode(FILE *code_file);
void DownloadVirtexCodeBlock (u_char *code_data, int code_data_size);
void DownloadCPCICodeBlock (u_char *code_data, int code_data_size);
void ResetDevice(void);
void VerifyDevInfo(void);
void NF2_WR32(u_int addr, u_int data);
u_int NF2_RD32(u_int addr);
void processArgs (int argc, char **argv );
void usage ();


#endif
