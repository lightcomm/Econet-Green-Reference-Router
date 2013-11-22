
# make_pkts.pl
#
#
# 

use NF2::PacketGen;
use NF2::PacketLib;
use SimLib;
use RouterLib;

use reg_defines_awm_earth;

$delay = 2000;
$batch = 0;
nf_set_environment( { PORT_MODE => 'PHYSICAL', MAX_PORTS => 4 } );

# use strict AFTER the $delay, $batch and %reg are declared
use strict;
use vars qw($delay $batch %reg);

my $ROUTER_PORT_1_MAC = 'ca:fe:f0:0d:00:01';
my $ROUTER_PORT_2_MAC = 'ca:fe:f0:0d:00:02';
my $ROUTER_PORT_3_MAC = 'ca:fe:f0:0d:00:03';
my $ROUTER_PORT_4_MAC = 'ca:fe:f0:0d:00:04';

my $ROUTER_PORT_1_IP = '192.168.1.1';
my $ROUTER_PORT_2_IP = '192.168.2.1';
my $ROUTER_PORT_3_IP = '192.168.3.1';
my $ROUTER_PORT_4_IP = '192.168.4.1';

my $next_hop_1_DA = '00:fe:ed:01:d0:65';
my $next_hop_2_DA = '00:fe:ed:02:d0:65';

#nf_PCI_write32($delay, 0, AWM_EARTH_SRC_IP_REG(), 0xc0a80102);
#nf_PCI_write32($delay, 0, AWM_EARTH_BETA_REG(), 0x5f5e100);
nf_PCI_write32($delay, 0, AWM_EARTH_TARGET_REG(), 0x3e80);
#nf_PCI_write32($delay, 0, AWM_EARTH_FLOWS_REG(), 0x3e8);
nf_PCI_write32($delay, 0, AWM_EARTH_FLOWS_REG(), 0x1);
#nf_PCI_write32($delay, 0, AWM_EARTH_DST_IP_REG(), 0xc0a80102);
#nf_PCI_write32($delay, 0, OQ_QUEUE_4_NUM_WORDS_IN_Q_REG(), 0x10);
#nf_PCI_write32($delay, 0, OQ_QUEUE_0_NUM_WORDS_IN_Q_REG(), 0x10);
#nf_PCI_read32($delay+150000, 0, AWM_EARTH_DELTA_REG(), 0);
#nf_PCI_write32($delay, 0, OQ_QUEUE_4_NUM_PKTS_IN_Q_REG(), 0x90);
#nf_PCI_write32($delay+14000, 0, OQ_QUEUE_4_NUM_WORDS_IN_Q_REG(), 0x1f4);
#nf_PCI_read32($delay+45000, 0, AWM_EARTH_WINDOW_REG_REG(), 0);

# Test 3 TCP header and payload, contains SSL application data. 
my @TCP_PDU = (
0x00, 0x50, 0x90, 0xec, 0x2c, 0xfd, 0x46, 0xa6, 0x2c, 0x8f, 0x74, 0x09, 0x80, 0x18, 0xff, 0xff,
0x83, 0xf1, 0x00, 0x00, 0x01, 0x01, 0x08, 0x0a, 0x3c, 0x13, 0x9c, 0xfe, 0x44, 0x5a, 0x93, 0x07,
0xf5, 0x4f, 0x41, 0x14, 0x58, 0x91, 0xb4, 0x43, 0x6f, 0x34, 0x3e, 0x49, 0x34, 0x45, 0xc5, 0x93,
0x58, 0x47, 0x54, 0x56, 0x8d, 0xf5, 0x47, 0xcb, 0xf3, 0x4c, 0x67, 0xf5, 0x53, 0x89, 0xd5, 0x44,
0xcf, 0xf4, 0x56, 0x33, 0x34, 0x40, 0x2f, 0xd5, 0x52, 0x4d, 0x95, 0x53, 0x9d, 0xd4, 0x53, 0x53,
0x95, 0x5b, 0xa7, 0xd4, 0x5b, 0x43, 0xb5, 0x54, 0xc3, 0x15, 0x4a, 0x3b, 0x55, 0x46, 0xa9, 0xd4,
0x3f, 0x49, 0x75, 0x4a, 0xb7, 0x15, 0x5d, 0xc1, 0x35, 0x39, 0x87, 0xd4, 0x51, 0xb1, 0x75, 0x55,
0x83, 0x14, 0x5b, 0xad, 0x35, 0x56, 0xdf, 0xb4, 0x5a, 0xa3, 0x15, 0x48, 0xd5, 0xf4, 0x45, 0xfb,
0x55, 0x93, 0x82, 0x00, 0x00, 0x3b);



# Prepare the DMA and enable interrupts
prepare_DMA('@3.9us');
enable_interrupts(0);

# Write the ip addresses and mac addresses, routing table, filter, ARP entries
$delay = '@4us';
set_router_MAC(1, $ROUTER_PORT_1_MAC);
$delay = 0;
set_router_MAC(2, $ROUTER_PORT_2_MAC);
set_router_MAC(3, $ROUTER_PORT_3_MAC);
set_router_MAC(4, $ROUTER_PORT_4_MAC);

add_dst_ip_filter_entry(0,$ROUTER_PORT_1_IP);
add_dst_ip_filter_entry(1,$ROUTER_PORT_2_IP);
add_dst_ip_filter_entry(2,$ROUTER_PORT_3_IP);
add_dst_ip_filter_entry(3,$ROUTER_PORT_4_IP);

add_LPM_table_entry(0,'192.168.2.0', '255.255.255.0', '192.168.2.2', 0x04);

# Add the ARP table entries
add_ARP_table_entry(0, '192.168.2.2', $next_hop_2_DA);

my $length = 100;
my $TTL = 30;
my $DA = 0;
my $SA = 0;
my $dst_ip = 0;
my $src_ip = 0;
my $pkt;
my $proto = 0;
#
###############################
# Test 1: Tests state WORD_4. Sends pkt size < 86, proto = TCP, in port 1 and
#         out port 2. 


$delay = '@40us';
$length = 168;# 381;
$DA = $ROUTER_PORT_1_MAC;
$SA = '01:55:55:55:55:55';
$dst_ip = '192.168.2.2';
$src_ip = '192.168.1.2';
$proto = 0x06;
$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip, $proto);
nf_packet_in(1, $length, $delay, $batch,  $pkt);

#$DA = $next_hop_2_DA;
#$SA = $ROUTER_PORT_2_MAC;
#$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL-1, $dst_ip, $src_ip, $proto);
#nf_expected_packet(2, $length, $pkt);
##nf_expected_dma_data(1,$length,$pkt);

# *********** Finishing Up - need this in all scripts ! ****************************

#
###############################
# Test 2: Tests state WORD_4. Sends pkt size < 86, proto = TCP, in port 1 and
#         out port 2. 

$delay = '@90us';
$length = 168;# 381;
$DA = $ROUTER_PORT_1_MAC;
$SA = '01:55:55:55:55:55';
$dst_ip = '192.168.2.2';
$src_ip = '192.168.1.2';
$proto = 0x06;
$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip, $proto);
nf_packet_in(1, $length, $delay, $batch,  $pkt);

#$DA = $next_hop_2_DA;
#$SA = $ROUTER_PORT_2_MAC;
$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL-1, $dst_ip, $src_ip, $proto);
nf_expected_packet(2, $length, $pkt);
#######

###############################
# Test 2: Tests state WORD_4. Sends pkt size < 86, proto = TCP, in port 1 and
#         out port 2. 

$delay = '@90us';
$length = 168;# 381;
$DA = $ROUTER_PORT_1_MAC;
$SA = '01:55:55:55:55:55';
$dst_ip = '192.168.2.2';
$src_ip = '192.168.1.2';
$proto = 0x06;
$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip, $proto);
nf_packet_in(1, $length, $delay, $batch,  $pkt);

#$DA = $next_hop_2_DA;
#$SA = $ROUTER_PORT_2_MAC;
$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL-1, $dst_ip, $src_ip, $proto);
nf_expected_packet(2, $length, $pkt);
#######


###############################
# Test 3: Tests state WORD_4. Sends pkt size < 86, proto = TCP, in port 1 and

###############################
# Test 3: Tests state WORD_4. Sends pkt size < 86, proto = TCP, in port 1 and
#         out port 2. 

#$delay = '@90us';
#$length = 168;# 381;
#$DA = $ROUTER_PORT_1_MAC;
#$SA = '01:55:55:55:55:55';
#$dst_ip = '192.168.2.2';
#$src_ip = '192.168.1.2';
#$proto = 0x06;
#$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip,$proto);
#nf_packet_in(1, $length, $delay, $batch,  $pkt);

#$DA = $next_hop_2_DA;
#$SA = $ROUTER_PORT_2_MAC;
#$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL-1, $dst_ip, $src_ip,$proto);
#nf_expected_packet(2, $length, $pkt);
#######

###############################
# Test 3: Tests state WORD_4. Sends pkt size < 86, proto = TCP, in port 1 and
#         out port 2.

#$delay = '@90us';
#$length = 168;# 381;
#$DA = $ROUTER_PORT_1_MAC;
#$SA = '01:55:55:55:55:55';
#$dst_ip = '192.168.2.2';
#$src_ip = '192.168.1.2';
#$proto = 0x06;
#$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip,$proto);
#nf_packet_in(1, $length, $delay, $batch,  $pkt);

#$DA = $next_hop_2_DA;
#$SA = $ROUTER_PORT_2_MAC;
#$pkt = make_IP_TCP_pkt($length, $DA, $SA, $TTL-1, $dst_ip, $src_ip,$proto);
#nf_expected_packet(2, $length, $pkt);
#######

my $t = nf_write_sim_files();
my $t = nf_write_sim_files();
print  "--- make_pkts.pl: Generated all configuration packets.\n";
printf "--- make_pkts.pl: Last packet enters system at approx %0d microseconds.\n",($t/1000);
if (nf_write_expected_files()) {
  die "Unable to write expected files\n";
}

nf_create_hardware_file('LITTLE_ENDIAN');
nf_write_hardware_file('LITTLE_ENDIAN');
