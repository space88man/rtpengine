#!/usr/bin/perl

use strict;
use warnings;
use NGCP::Rtpengine::Test;
use NGCP::Rtpclient::SRTP;
use NGCP::Rtpengine::AutoTest;
use Test::More;
use NGCP::Rtpclient::ICE;
use POSIX;


autotest_start(qw(--config-file=none -t -1 -i 203.0.113.1 -i 2001:db8:4321::1
			-n 2223 -c 12345 -f -L 7 -E -u 2222 --silence-detect=1 --dtx-delay=10
			--dtx-cn-params=10))
		or die;



my ($sock_a, $sock_b, $sock_c, $sock_d, $port_a, $port_b, $ssrc, $ssrc_b, $resp,
	$sock_ax, $sock_bx, $port_ax, $port_bx,
	$srtp_ctx_a, $srtp_ctx_b, $srtp_ctx_a_rev, $srtp_ctx_b_rev,
	@ret1, @ret2, @ret3, @ret4, $srtp_key_a, $srtp_key_b, $ts, $seq);





($sock_a, $sock_b) = new_call([qw(198.51.100.10 5000)], [qw(198.51.100.10 5002)]);

($port_a) = offer('G.711 DTX',
	{ replace => ['origin'], codec => {
			transcode => ['PCMA'],
	} }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5000 RTP/AVP 0
c=IN IP4 198.51.100.10
a=sendrecv
----------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 0 8
c=IN IP4 203.0.113.1
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=sendrecv
a=rtcp:PORT
SDP

($port_b) = answer('G.711 DTX',
	{ replace => ['origin'] }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5002 RTP/AVP 8
c=IN IP4 198.51.100.10
a=sendrecv
--------------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 0
c=IN IP4 203.0.113.1
a=rtpmap:0 PCMU/8000
a=sendrecv
a=rtcp:PORT
SDP

snd($sock_a, $port_b, rtp(0, 2000, 4000, 0x5678, "\x40" x 160));
($ssrc) = rcv($sock_b, $port_a, rtpm(8, 2000, 4000, -1, "\x68" x 160));
snd($sock_a, $port_b, rtp(0, 2001, 4160, 0x5678, "\x40" x 160));
rcv($sock_b, $port_a, rtpm(8, 2001, 4160, $ssrc, "\x68" x 160));
# DTX -> CN
rcv($sock_b, $port_a, rtpm(8, 2002, 4320, $ssrc, "\x8c\x68\x02\x87\x94\x8e\x17\xc5\x19\x34\x6e\x08\x1c\x7e\x9f\x86\xf4\x09\x12\x8c\x81\x0c\x06\x05\x84\x18\x0e\x03\x16\x9f\x0a\x4c\x35\x4f\x05\x9c\x8e\x1d\x18\xf2\x9e\x8a\x99\xb4\x05\x11\x0e\x59\x02\xc8\x6b\x99\x1a\x03\x8c\x13\x67\x96\x35\x1e\x86\x9e\x80\x82\x99\x10\x86\x1f\x9b\x0a\x8f\x35\x04\x8c\x04\xd5\x63\x69\x0f\x09\x9a\x84\x01\x92\x71\x84\x1b\x8f\x03\xea\x73\x00\x0a\x13\x62\x9b\x00\xe4\x04\x87\x86\xd5\xea\x04\x04\x0d\x89\x8a\x91\xea\x97\x1f\x83\x96\x87\xb5\x85\x0d\x04\x63\xfc\x13\xe7\x46\x83\x14\x97\xd2\x0e\x69\x6d\x17\x0a\x85\x9a\x35\xe3\x8d\x64\x67\x46\x66\x0c\xe9\x02\x80\x87\xcf\x0d\x81\x10\x99\x92\x90\x03\x0c\xfd\x10\xb4\x1b"));
rcv($sock_b, $port_a, rtpm(8, 2003, 4480, $ssrc, "\x9a\x87\x6a\x08\x09\x0b\x7b\x61\x81\xe7\x85\x05\x19\x0a\x87\x04\x34\x06\x93\x8a\x88\xb5\x5c\x6b\x0f\x02\x84\x0f\x82\x81\x40\x34\x91\x34\x03\x85\x9a\x03\x14\x6f\x80\xb5\x03\x0e\x98\x12\x00\x0a\x86\x10\x8e\x92\x03\x87\x87\x85\x6f\x6a\x04\x82\x81\x94\x80\x01\x14\x9b\x65\x6c\x84\x09\x65\x0b\xb4\x34\x8d\xe2\x02\x05\x0d\x8c\xe1\x0c\x14\x92\xe1\x0e\x80\x8d\x15\x8e\x03\x0c\x8b\x4b\x8d\x8f\xb5\x00\xb5\x18\x59\x72\x01\x97\x88\x35\x35\x8d\x13\x8f\xf3\x04\x87\x0d\x35\x88\xe4\x1a\x0a\x04\x9e\x94\x17\x0a\xec\x89\x1a\x94\x88\x8e\x94\x34\xe8\x35\x69\x82\x89\xc6\x9c\x52\x9d\x08\x89\x94\xe2\x80\xd3\xb5\x0b\x84\x0d\xee\x0e\x8d\x88\x5d\x0b\x07\x35\x84"));
# start audio again
snd($sock_a, $port_b, rtp(0, 2002, 4640, 0x5678, "\x40" x 160));
rcv($sock_b, $port_a, rtpm(8, 2004, 4640, $ssrc, "\x68" x 160));

rtpe_req('delete', 'G.711 DTX', { 'from-tag' => ft() });



($sock_a, $sock_b) = new_call([qw(198.51.100.10 5004)], [qw(198.51.100.10 5006)]);

($port_a) = offer('G.711 DTX ptime=30',
	{ replace => ['origin'], codec => {
			transcode => ['PCMA'],
	} }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5004 RTP/AVP 0
c=IN IP4 198.51.100.10
a=sendrecv
a=ptime:30
----------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 0 8
c=IN IP4 203.0.113.1
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=sendrecv
a=rtcp:PORT
a=ptime:30
SDP

($port_b) = answer('G.711 DTX ptime=30',
	{ replace => ['origin'] }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5006 RTP/AVP 8
c=IN IP4 198.51.100.10
a=sendrecv
--------------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 0
c=IN IP4 203.0.113.1
a=rtpmap:0 PCMU/8000
a=sendrecv
a=rtcp:PORT
a=ptime:30
SDP

snd($sock_a, $port_b, rtp(0, 2000, 4000, 0x5678, "\x40" x 240));
($ssrc) = rcv($sock_b, $port_a, rtpm(8, 2000, 4000, -1, "\x68" x 240));
snd($sock_a, $port_b, rtp(0, 2001, 4240, 0x5678, "\x40" x 240));
rcv($sock_b, $port_a, rtpm(8, 2001, 4240, $ssrc, "\x68" x 240));
# DTX -> CN
rcv($sock_b, $port_a, rtpm(8, 2002, 4480, $ssrc, "\x8c\x68\x02\x87\x94\x8e\x17\xc5\x19\x34\x6e\x08\x1c\x7e\x9f\x86\xf4\x09\x12\x8c\x81\x0c\x06\x05\x84\x18\x0e\x03\x16\x9f\x0a\x4c\x35\x4f\x05\x9c\x8e\x1d\x18\xf2\x9e\x8a\x99\xb4\x05\x11\x0e\x59\x02\xc8\x6b\x99\x1a\x03\x8c\x13\x67\x96\x35\x1e\x86\x9e\x80\x82\x99\x10\x86\x1f\x9b\x0a\x8f\x35\x04\x8c\x04\xd5\x63\x69\x0f\x09\x9a\x84\x01\x92\x71\x84\x1b\x8f\x03\xea\x73\x00\x0a\x13\x62\x9b\x00\xe4\x04\x87\x86\xd5\xea\x04\x04\x0d\x89\x8a\x91\xea\x97\x1f\x83\x96\x87\xb5\x85\x0d\x04\x63\xfc\x13\xe7\x46\x83\x14\x97\xd2\x0e\x69\x6d\x17\x0a\x85\x9a\x35\xe3\x8d\x64\x67\x46\x66\x0c\xe9\x02\x80\x87\xcf\x0d\x81\x10\x99\x92\x90\x03\x0c\xfd\x10\xb4\x1b\x9a\x87\x6a\x08\x09\x0b\x7b\x61\x81\xe7\x85\x05\x19\x0a\x87\x04\x34\x06\x93\x8a\x88\xb5\x5c\x6b\x0f\x02\x84\x0f\x82\x81\x40\x34\x91\x34\x03\x85\x9a\x03\x14\x6f\x80\xb5\x03\x0e\x98\x12\x00\x0a\x86\x10\x8e\x92\x03\x87\x87\x85\x6f\x6a\x04\x82\x81\x94\x80\x01\x14\x9b\x65\x6c\x84\x09\x65\x0b\xb4\x34\x8d\xe2\x02\x05\x0d\x8c"));
rcv($sock_b, $port_a, rtpm(8, 2003, 4720, $ssrc, "\xe1\x0c\x14\x92\xe1\x0e\x80\x8d\x15\x8e\x03\x0c\x8b\x4b\x8d\x8f\xb5\x00\xb5\x18\x59\x72\x01\x97\x88\x35\x35\x8d\x13\x8f\xf3\x04\x87\x0d\x35\x88\xe4\x1a\x0a\x04\x9e\x94\x17\x0a\xec\x89\x1a\x94\x88\x8e\x94\x34\xe8\x35\x69\x82\x89\xc6\x9c\x52\x9d\x08\x89\x94\xe2\x80\xd3\xb5\x0b\x84\x0d\xee\x0e\x8d\x88\x5d\x0b\x07\x35\x84\x8a\xfa\xc8\x82\xfd\x95\x0d\x69\x9a\x83\x61\xfd\x12\x81\x69\x18\x85\x06\xb5\x08\xb5\xda\x93\x9d\x82\x03\xf5\x65\xe6\x35\xb5\x1e\x04\xdd\x88\x06\x62\x99\x35\x8f\xf9\x9a\x8a\x0d\x98\x92\x04\x81\x9d\x09\x35\xd0\x80\x0a\x85\x04\x80\x35\x87\x87\x35\x8c\x60\xe9\x14\x0d\x5b\x43\xdf\x0b\xfc\xf4\x8e\x0a\x0e\x77\x1c\x98\x6c\x08\xb5\xe4\x00\x1d\x0a\x82\x85\x8d\x8f\x08\x99\x8e\x01\x09\x63\x08\x95\xb4\x04\x03\xb5\xb5\x00\x87\x08\xe2\x99\x0c\x0e\xe1\xb5\x90\x88\x82\x71\x8b\x0b\xc4\x35\x72\x87\x5a\x9a\x9f\x0a\xd8\x9a\x90\x0c\x9f\x03\x7c\x83\xb5\x0b\x96\x43\x35\x81\xb4\x89\x04\x8f\x13\x82\x00\x94\x8e\x0c\x8b\x80\x05\x0c\x8b\x11\x64\x81\x03\x83\x9b"));
# start audio again
snd($sock_a, $port_b, rtp(0, 2002, 4960, 0x5678, "\x40" x 240));
rcv($sock_b, $port_a, rtpm(8, 2004, 4960, $ssrc, "\x68" x 240));

rtpe_req('delete', 'G.711 DTX ptime=30', { 'from-tag' => ft() });




($sock_a, $sock_b) = new_call([qw(198.51.100.10 5008)], [qw(198.51.100.10 5010)]);

($port_a) = offer('G.711 DTX ptime change',
	{ replace => ['origin'], codec => {
			transcode => ['PCMA'],
	} }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5008 RTP/AVP 0
c=IN IP4 198.51.100.10
a=sendrecv
----------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 0 8
c=IN IP4 203.0.113.1
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
a=sendrecv
a=rtcp:PORT
SDP

($port_b) = answer('G.711 DTX ptime change',
	{ replace => ['origin'] }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5010 RTP/AVP 8
c=IN IP4 198.51.100.10
a=sendrecv
--------------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 0
c=IN IP4 203.0.113.1
a=rtpmap:0 PCMU/8000
a=sendrecv
a=rtcp:PORT
SDP

snd($sock_a, $port_b, rtp(0, 2000, 4000, 0x5678, "\x40" x 240));
($ssrc) = rcv($sock_b, $port_a, rtpm(8, 2000, 4000, -1, "\x68" x 160));
snd($sock_a, $port_b, rtp(0, 2001, 4240, 0x5678, "\x40" x 240));
rcv($sock_b, $port_a, rtpm(8, 2001, 4160, $ssrc, "\x68" x 160));
rcv($sock_b, $port_a, rtpm(8, 2002, 4320, $ssrc, "\x68" x 160));
# DTX -> CN
rcv($sock_b, $port_a, rtpm(8, 2003, 4480, $ssrc, "\x8c\x68\x02\x87\x94\x8e\x17\xc5\x19\x34\x6e\x08\x1c\x7e\x9f\x86\xf4\x09\x12\x8c\x81\x0c\x06\x05\x84\x18\x0e\x03\x16\x9f\x0a\x4c\x35\x4f\x05\x9c\x8e\x1d\x18\xf2\x9e\x8a\x99\xb4\x05\x11\x0e\x59\x02\xc8\x6b\x99\x1a\x03\x8c\x13\x67\x96\x35\x1e\x86\x9e\x80\x82\x99\x10\x86\x1f\x9b\x0a\x8f\x35\x04\x8c\x04\xd5\x63\x69\x0f\x09\x9a\x84\x01\x92\x71\x84\x1b\x8f\x03\xea\x73\x00\x0a\x13\x62\x9b\x00\xe4\x04\x87\x86\xd5\xea\x04\x04\x0d\x89\x8a\x91\xea\x97\x1f\x83\x96\x87\xb5\x85\x0d\x04\x63\xfc\x13\xe7\x46\x83\x14\x97\xd2\x0e\x69\x6d\x17\x0a\x85\x9a\x35\xe3\x8d\x64\x67\x46\x66\x0c\xe9\x02\x80\x87\xcf\x0d\x81\x10\x99\x92\x90\x03\x0c\xfd\x10\xb4\x1b"));
rcv($sock_b, $port_a, rtpm(8, 2004, 4640, $ssrc, "\x9a\x87\x6a\x08\x09\x0b\x7b\x61\x81\xe7\x85\x05\x19\x0a\x87\x04\x34\x06\x93\x8a\x88\xb5\x5c\x6b\x0f\x02\x84\x0f\x82\x81\x40\x34\x91\x34\x03\x85\x9a\x03\x14\x6f\x80\xb5\x03\x0e\x98\x12\x00\x0a\x86\x10\x8e\x92\x03\x87\x87\x85\x6f\x6a\x04\x82\x81\x94\x80\x01\x14\x9b\x65\x6c\x84\x09\x65\x0b\xb4\x34\x8d\xe2\x02\x05\x0d\x8c\xe1\x0c\x14\x92\xe1\x0e\x80\x8d\x15\x8e\x03\x0c\x8b\x4b\x8d\x8f\xb5\x00\xb5\x18\x59\x72\x01\x97\x88\x35\x35\x8d\x13\x8f\xf3\x04\x87\x0d\x35\x88\xe4\x1a\x0a\x04\x9e\x94\x17\x0a\xec\x89\x1a\x94\x88\x8e\x94\x34\xe8\x35\x69\x82\x89\xc6\x9c\x52\x9d\x08\x89\x94\xe2\x80\xd3\xb5\x0b\x84\x0d\xee\x0e\x8d\x88\x5d\x0b\x07\x35\x84"));
rcv($sock_b, $port_a, rtpm(8, 2005, 4800, $ssrc, "\x8a\xfa\xc8\x82\xfd\x95\x0d\x69\x9a\x83\x61\xfd\x12\x81\x69\x18\x85\x06\xb5\x08\xb5\xda\x93\x9d\x82\x03\xf5\x65\xe6\x35\xb5\x1e\x04\xdd\x88\x06\x62\x99\x35\x8f\xf9\x9a\x8a\x0d\x98\x92\x04\x81\x9d\x09\x35\xd0\x80\x0a\x85\x04\x80\x35\x87\x87\x35\x8c\x60\xe9\x14\x0d\x5b\x43\xdf\x0b\xfc\xf4\x8e\x0a\x0e\x77\x1c\x98\x6c\x08\xb5\xe4\x00\x1d\x0a\x82\x85\x8d\x8f\x08\x99\x8e\x01\x09\x63\x08\x95\xb4\x04\x03\xb5\xb5\x00\x87\x08\xe2\x99\x0c\x0e\xe1\xb5\x90\x88\x82\x71\x8b\x0b\xc4\x35\x72\x87\x5a\x9a\x9f\x0a\xd8\x9a\x90\x0c\x9f\x03\x7c\x83\xb5\x0b\x96\x43\x35\x81\xb4\x89\x04\x8f\x13\x82\x00\x94\x8e\x0c\x8b\x80\x05\x0c\x8b\x11\x64\x81\x03\x83\x9b"));
# start audio again
snd($sock_a, $port_b, rtp(0, 2002, 4960, 0x5678, "\x40" x 240));
rcv($sock_b, $port_a, rtpm(8, 2006, 4960, $ssrc, "\x68" x 160));

rtpe_req('delete', 'G.711 DTX ptime change', { 'from-tag' => ft() });



($sock_a, $sock_b) = new_call([qw(198.51.100.10 5012)], [qw(198.51.100.10 5014)]);

($port_a) = offer('G.722 DTX',
	{ replace => ['origin'], codec => {
			transcode => ['G722'],
	} }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5012 RTP/AVP 0
c=IN IP4 198.51.100.10
a=sendrecv
----------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 0 9
c=IN IP4 203.0.113.1
a=rtpmap:0 PCMU/8000
a=rtpmap:9 G722/8000
a=sendrecv
a=rtcp:PORT
SDP

($port_b) = answer('G.722 DTX',
	{ replace => ['origin'] }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5014 RTP/AVP 9
c=IN IP4 198.51.100.10
a=rtpmap:9 G722/8000
a=sendrecv
--------------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 0
c=IN IP4 203.0.113.1
a=rtpmap:0 PCMU/8000
a=sendrecv
a=rtcp:PORT
SDP

snd($sock_a, $port_b, rtp(0, 2000, 4000, 0x5678, "\x40" x 160));
Time::HiRes::usleep(10000); # resample buffer delay
snd($sock_a, $port_b, rtp(0, 2001, 4160, 0x5678, "\x40" x 160));
($ssrc) = rcv($sock_b, $port_a, rtpm(9, 2000, 4000, -1, "\x3a\x96\x24\x86\x21\x84\x04\x8c\x4d\xd0\xd1\xd2\x94\xd5\xd5\xd6\xd7\xd8\x98\xd8\xd8\xd8\xd8\xd8\xd8\xd8\xd9\xd9\xda\xda\xda\xdb\xdc\x9a\xda\xdb\x9c\xda\xda\x9c\xda\xda\xdb\xdc\xda\xdb\xdd\xdb\xdb\xdc\xda\xdb\xdb\xdd\xda\xdb\xdc\xda\xda\xda\xdc\xd9\xd9\xdb\xdc\xd8\xd8\xda\xdb\xdc\xd8\xd9\xda\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xda\xdb\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xdb\xdc\xd6\xdc\xd7\xff\xd8\xd8\xda\xda\xdb\xd9\xdc\xd9\xdb\xdc\xd6\xdd\xd8\xd9\xdc\xd7\xfc\xd7\xdd\xd9\xd9\xdb\xdc\xd9\xd9\xdb\xde\xd9\xd8\xdb\xdf\xda\xda\xdd\xd9\xd9\xda\xde\xda\xdb\xdf\xdc\xd5\xdb\xff\xd6\xde\xdc\xd9\xd9\xd8\xdd\xd9\xda\xfe"));
snd($sock_a, $port_b, rtp(0, 2002, 4320, 0x5678, "\x40" x 160));
rcv($sock_b, $port_a, rtpm(9, 2001, 4160, $ssrc, "\xd7\xfe\xd5\xdd\xda\xdc\xdd\xd7\xf9\xd6\xdc\xd7\xf9\xdb\xd9\xff\xd7\xfc\xd6\xfc\xde\xd8\xdd\xd9\xde\xd9\xde\xfe\xd7\xfc\xdb\xdd\xd9\xdd\xff\xd7\xf9\xd9\xdb\xff\xd8\xde\xdd\xfe\xd9\xda\xfc\xdd\xdb\xfc\xfd\xda\xda\xfb\xd9\xdc\xdc\xfe\xda\xdb\xf8\xda\xdd\xda\xfb\xd6\xfe\xdc\xd9\xfe\xd6\xf9\xd9\xdc\xdb\xff\xdb\xdc\xda\xdf\xfe\xd5\xde\xdf\xdf\xdb\xde\xdf\xdb\xdc\xd9\xdd\xda\xfe\xd7\xfe\xd8\xd7\xf9\xd7\xfa\xd5\xdf\xfe\xd3\xf8\xda\xde\xda\xdd\xdc\xd6\xfc\xdc\xd7\xfd\xda\xde\xd8\xd8\xde\xdc\xd9\xdb\xfa\xd5\xd8\xdc\xda\xdf\xde\xdf\xdc\xd3\xfa\xd6\xff\xd9\xde\xde\xd7\xff\xd6\xfe\xd7\xfa\xd8\xd6\xff\xd8\xd9\xdb\xf9\xda\xd7\xff\xd9\xd8\xda\xfa"));
# DTX -> CN
rcv($sock_b, $port_a, rtpm(9, 2002, 4320, $ssrc, "\xd8\xd6\xff\xd9\xd8\xda\xfa\xd8\xd6\xfc\xda\xda\xdc\xdb\xfb\xd3\xfc\xdc\xd5\xdd\xdd\xde\xd8\xda\xfe\xd5\xda\xfd\xdb\xdd\xd8\xdb\xdd\xd8\xda\xfe\xd8\xd8\xd9\xdc\xda\xdd\xde\xdc\xd6\xdc\xd9\xda\xdf\xff\xd7\xde\xd9\xd7\xfe\xd9\xde\xdc\xd8\xd6\xdb\xfc\xda\xdd\xdc\xd7\xdd\xd5\xde\xdf\xfe\xd7\xdc\xd6\xdd\xd9\xde\xfb\xd4\xd7\xff\xd7\xfe\xd9\xfc\xd9\xd5\xdc\xd8\xdc\xdc\xdc\xd9\xd7\xff\xd5\xdb\xf9\xdb\xdd\xd5\xdc\xd8\xd7\xf5\xdb\xde\xd8\xd7\xff\xd6\xf8\xde\xdc\xd5\xd8\xdc\xd7\xf5\xdd\xd9\xd7\xde\xdc\xd5\xfa\xfe\xd6\xdc\xd6\xff\xd6\xf9\xdf\xdc\xd6\xdb\xfe\xd5\xfe\xde\xde\xd8\xd4\x9c\x34\x85\x21\x85\x20\x97\x06\x20\x99\x11\x8e\x29\xb4\x06\xa0"));
rcv($sock_b, $port_a, rtpm(9, 2003, 4480, $ssrc, "\xa8\x0c\x8d\x32\xb6\x08\xb9\x61\x6a\x46\x8a\x27\x93\x27\x9b\x39\xfb\xc8\x6e\x88\x24\xb7\x31\xda\xd3\xed\x46\x6d\xe3\xd9\x79\xcb\x2e\x85\x39\xa3\x6a\xcf\x3b\xd4\xca\xd9\x71\x60\xf8\x4c\xf7\xc5\x53\xe1\x6a\xf5\xdb\x53\x86\x2c\xb6\x24\xbe\x27\x89\x45\x62\xc9\x74\xe6\x72\x4d\xca\x65\x73\xc7\x62\xb7\x1b\x89\x2a\xd4\x51\xe9\x5a\xdc\xfb\xb4\x6d\xca\x35\xdf\x72\xea\xce\x33\xce\x59\x9b\xe4\x64\x51\xd3\x5a\x8c\x73\xee\x6e\x6d\xd6\xc8\x4f\xef\x2f\xfe\x2b\xbd\x7d\x8a\xda\x70\x8f\x2c\xec\x73\xcc\xf6\x6a\x86\x74\xe4\xfb\x53\xfd\x30\x8a\x30\xdf\x6a\xee\x56\x8d\x74\xdd\x1f\x6b\xf7\x54\x8a\x2c\x9c\x67\x96\xdf\x6d\xcf\x4e\x55\xf7\x6b\xf3\x6b\x98\x57"));
# start audio again
snd($sock_a, $port_b, rtp(0, 2003, 4800, 0x5678, "\x40" x 160));
rcv($sock_b, $port_a, rtpm(9, 2004, 4640, $ssrc, "\x8c\x52\xd6\x27\x73\xce\x7b\xb3\x6b\xdb\x33\xd4\x4f\x17\xd6\x24\x96\xec\xad\xd5\xc9\x37\x59\x53\x67\x6d\xd3\x53\x5f\xb0\xe9\xd1\xcf\x6b\x96\x19\x90\x69\xbf\xf3\x6f\xca\x6f\xba\xf4\xd8\x18\xd7\xef\xed\xdc\x2e\x4f\xd6\x73\xff\x99\x2a\xd0\x3c\x8d\x28\x94\x7a\xe9\xcc\x5f\xcd\x6a\x72\x50\x7d\xf6\x34\x4d\x73\x2a\xd3\x2d\x55\xcc\x6a\xdc\x2d\xb1\x2a\xcd\x37\x98\xd2\xf6\x52\xf1\x69\xd7\x8a\x6d\xde\x6f\xf4\xd3\x6f\x54\x8b\x70\xee\x3e\x4f\xd4\xef\xf5\x5f\xcf\xfd\x29\x99\x7c\x6a\xee\x33\x8a\x7f\x8d\x15\x6e\x28\xf1\x74\x9e\x39\xcb\x38\xee\x5b\x3f\x1c\x7f\x57\x5b\xdd\xde\x5e\x5f\xfe\xdd\x5c\x5b\xdc\xdb\x5d\x5d\xde\xdd\xdc\xdc\x5a\x5c\xda\xdd\xdb"));

rtpe_req('delete', 'G.722 DTX', { 'from-tag' => ft() });



($sock_a, $sock_b) = new_call([qw(198.51.100.10 5016)], [qw(198.51.100.10 5018)]);

($port_a) = offer('G.722 reverse DTX',
	{ replace => ['origin'], codec => {
			transcode => ['PCMU'],
	} }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5016 RTP/AVP 9
c=IN IP4 198.51.100.10
a=sendrecv
----------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 9 0
c=IN IP4 203.0.113.1
a=rtpmap:9 G722/8000
a=rtpmap:0 PCMU/8000
a=sendrecv
a=rtcp:PORT
SDP

($port_b) = answer('G.722 reverse DTX',
	{ replace => ['origin'] }, <<SDP);
v=0
o=- 1545997027 1 IN IP4 198.51.100.10
s=tester
t=0 0
m=audio 5018 RTP/AVP 0
c=IN IP4 198.51.100.10
a=rtpmap:9 G722/8000
a=sendrecv
--------------------------------------
v=0
o=- 1545997027 1 IN IP4 203.0.113.1
s=tester
t=0 0
m=audio PORT RTP/AVP 9
c=IN IP4 203.0.113.1
a=rtpmap:9 G722/8000
a=sendrecv
a=rtcp:PORT
SDP

snd($sock_a, $port_b, rtp(9, 2000, 4000, 0x5678, "\x3a\x96\x24\x86\x21\x84\x04\x8c\x4d\xd0\xd1\xd2\x94\xd5\xd5\xd6\xd7\xd8\x98\xd8\xd8\xd8\xd8\xd8\xd8\xd8\xd9\xd9\xda\xda\xda\xdb\xdc\x9a\xda\xdb\x9c\xda\xda\x9c\xda\xda\xdb\xdc\xda\xdb\xdd\xdb\xdb\xdc\xda\xdb\xdb\xdd\xda\xdb\xdc\xda\xda\xda\xdc\xd9\xd9\xdb\xdc\xd8\xd8\xda\xdb\xdc\xd8\xd9\xda\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xda\xdb\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xdb\xdc\xd6\xdc\xd7\xff\xd8\xd8\xda\xda\xdb\xd9\xdc\xd9\xdb\xdc\xd6\xdd\xd8\xd9\xdc\xd7\xfc\xd7\xdd\xd9\xd9\xdb\xdc\xd9\xd9\xdb\xde\xd9\xd8\xdb\xdf\xda\xda\xdd\xd9\xd9\xda\xde\xda\xdb\xdf\xdc\xd5\xdb\xff\xd6\xde\xdc\xd9\xd9\xd8\xdd\xd9\xda\xfe"));
Time::HiRes::usleep(10000); # resample buffer delay
snd($sock_a, $port_b, rtp(9, 2001, 4160, 0x5678, "\x3a\x96\x24\x86\x21\x84\x04\x8c\x4d\xd0\xd1\xd2\x94\xd5\xd5\xd6\xd7\xd8\x98\xd8\xd8\xd8\xd8\xd8\xd8\xd8\xd9\xd9\xda\xda\xda\xdb\xdc\x9a\xda\xdb\x9c\xda\xda\x9c\xda\xda\xdb\xdc\xda\xdb\xdd\xdb\xdb\xdc\xda\xdb\xdb\xdd\xda\xdb\xdc\xda\xda\xda\xdc\xd9\xd9\xdb\xdc\xd8\xd8\xda\xdb\xdc\xd8\xd9\xda\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xda\xdb\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xdb\xdc\xd6\xdc\xd7\xff\xd8\xd8\xda\xda\xdb\xd9\xdc\xd9\xdb\xdc\xd6\xdd\xd8\xd9\xdc\xd7\xfc\xd7\xdd\xd9\xd9\xdb\xdc\xd9\xd9\xdb\xde\xd9\xd8\xdb\xdf\xda\xda\xdd\xd9\xd9\xda\xde\xda\xdb\xdf\xdc\xd5\xdb\xff\xd6\xde\xdc\xd9\xd9\xd8\xdd\xd9\xda\xfe"));
($ssrc) = rcv($sock_b, $port_a, rtpm(0, 2000, 4000, -1, "\x7e\xff\x7e\xfe\x7d\xfd\x7c\xfd\x7d\x7e\xf0\x4f\x44\x41\x40\x41\x40\x40\x40\x40\x3f\x40\x40\x40\x40\x40\x40\x40\x40\x40\x3f\x40\x40\x40\x41\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40"));
snd($sock_a, $port_b, rtp(9, 2002, 4320, 0x5678, "\x3a\x96\x24\x86\x21\x84\x04\x8c\x4d\xd0\xd1\xd2\x94\xd5\xd5\xd6\xd7\xd8\x98\xd8\xd8\xd8\xd8\xd8\xd8\xd8\xd9\xd9\xda\xda\xda\xdb\xdc\x9a\xda\xdb\x9c\xda\xda\x9c\xda\xda\xdb\xdc\xda\xdb\xdd\xdb\xdb\xdc\xda\xdb\xdb\xdd\xda\xdb\xdc\xda\xda\xda\xdc\xd9\xd9\xdb\xdc\xd8\xd8\xda\xdb\xdc\xd8\xd9\xda\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xda\xdb\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xdb\xdc\xd6\xdc\xd7\xff\xd8\xd8\xda\xda\xdb\xd9\xdc\xd9\xdb\xdc\xd6\xdd\xd8\xd9\xdc\xd7\xfc\xd7\xdd\xd9\xd9\xdb\xdc\xd9\xd9\xdb\xde\xd9\xd8\xdb\xdf\xda\xda\xdd\xd9\xd9\xda\xde\xda\xdb\xdf\xdc\xd5\xdb\xff\xd6\xde\xdc\xd9\xd9\xd8\xdd\xd9\xda\xfe"));
rcv($sock_b, $port_a, rtpm(0, 2001, 4160, $ssrc, "\x40\x40\x40\x40\x41\x3f\x45\x42\x59\x43\xbd\x17\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\x02\x02\x03\x04\x04\x04\x05\x05\x06\x06\x06\x07\x07\x08\x08\x08\x09\x09\x09\x0a\x0a\x0a\x0b\x0b\x0c\x0c\x0c\x0d\x0d\x0d\x0e\x0e\x0e\x0e\x0f\x0f\x0f"));
# DTX -> CN
rcv($sock_b, $port_a, rtpm(0, 2002, 4320, $ssrc, "\x0f\x10\x10\x11\x11\x12\x13\x14\x17\x19\x22\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\x01\x02\x02\x03\x03\x04\x04\x05\x05\x06\xa5\x40\x28\xad\xbd\xa4\x3c\xe6\x32\x1e\x42\x21\x35\x50\xb4\xac"));
rcv($sock_b, $port_a, rtpm(0, 2003, 4480, $ssrc, "\xda\x22\x37\xa6\xaa\x26\x2b\x2e\xad\x31\x24\x29\x3b\xb4\x20\x5e\x1f\x5e\x2e\xb5\xa4\x36\x31\xd4\xb3\xa0\xb2\x9e\x2f\x3a\x23\x6b\x27\xdc\x3f\xb2\x30\x29\xa5\x38\x4a\xbb\x1f\x33\xac\xb3\xa9\xa7\xb2\x39\xab\x34\xb0\x1f\xa5\x1e\x2d\xa6\x2e\xff\x47\x41\x25\x23\xb0\xad\x2b\xb7\x57\xae\x30\xa4\x29\xbf\x55\x2a\x1f\x37\x46\xb0\x2a\xcc\x2e\xac\xac\xfd\xbf\x2e\x2d\x26\xa2\xa0\xba\xbf\xbc\x34\xa8\xbb\xac\x9f\xaf\x26\x2e\x47\xd2\x38\xcb\x64\xa9\x3d\xbc\xf0\x23\x41\x44\x3c\x1f\xae\xaf\x1f\xc7\xa7\x4c\x4b\x64\x4a\x25\xc1\x27\xaa\xac\xde\x27\xab\x39\xb2\xb7\xb9\x28\x26\xd3\x39\x9e\x30\xaf\xad\x3e\x21\x23\x20\x4e\x49\xaa\xcb\xae\x2e\x32\x1f\xac\x2d"));
rcv($sock_b, $port_a, rtpm(0, 2004, 4640, $ssrc, "\x1e\x2b\xb8\x9f\xa2\x9e\x6e\x3f\x25\x28\xad\x24\xa8\xab\x61\x1e\xba\x1e\x28\xae\xaf\x29\x3d\x43\xa9\x9e\x29\x24\xb1\x37\x2a\x20\xac\x39\xa3\xb7\x28\xac\xad\xaf\x43\x3f\x2e\xa7\xab\xbd\xaa\x2a\x3d\xb0\x4d\x44\xad\x23\x4d\x21\x9e\x1e\xa6\xc6\x27\x2e\x27\xa6\xc9\x26\x3d\xb7\xc9\x24\xa9\xa6\x3d\xa4\x29\x25\xa0\x5c\xa7\xa5\x9f\x29\x9f\x31\x6b\x53\x2b\xbc\xa1\x1f\x1f\xa7\x38\xa5\xd5\x2e\xac\x26\x1e\xa1\xcc\x2f\x20\x2d\xb3\xbc\x3c\x1f\xc4\xa3\x2f\xbd\xa1\xa4\xbd\x1e\xc0\x1f\x41\xa8\xa2\xe3\xb5\x71\xb6\x22\xa3\xbd\xc6\xa9\xf1\x9e\x20\xae\x26\xc2\x24\xa7\xa2\x6f\x20\x2d\x1f\xae\xa0\xcd\xdd\xa7\xd3\xbe\x27\x40\xaf\xa8\x49\xd2\x37\xaa\x41\x31"));
# start audio again
snd($sock_a, $port_b, rtp(9, 2003, 4960, 0x5678, "\x3a\x96\x24\x86\x21\x84\x04\x8c\x4d\xd0\xd1\xd2\x94\xd5\xd5\xd6\xd7\xd8\x98\xd8\xd8\xd8\xd8\xd8\xd8\xd8\xd9\xd9\xda\xda\xda\xdb\xdc\x9a\xda\xdb\x9c\xda\xda\x9c\xda\xda\xdb\xdc\xda\xdb\xdd\xdb\xdb\xdc\xda\xdb\xdb\xdd\xda\xdb\xdc\xda\xda\xda\xdc\xd9\xd9\xdb\xdc\xd8\xd8\xda\xdb\xdc\xd8\xd9\xda\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xda\xdb\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xdb\xdc\xd6\xdc\xd7\xff\xd8\xd8\xda\xda\xdb\xd9\xdc\xd9\xdb\xdc\xd6\xdd\xd8\xd9\xdc\xd7\xfc\xd7\xdd\xd9\xd9\xdb\xdc\xd9\xd9\xdb\xde\xd9\xd8\xdb\xdf\xda\xda\xdd\xd9\xd9\xda\xde\xda\xdb\xdf\xdc\xd5\xdb\xff\xd6\xde\xdc\xd9\xd9\xd8\xdd\xd9\xda\xfe"));
rcv($sock_b, $port_a, rtpm(0, 2005, 4800, $ssrc, "\xae\x2b\x9f\x22\x9f\xe8\xb8\xb6\xa8\x29\xdb\x4d\xca\x1e\x9e\x33\x2d\xef\xa1\x2b\x46\xb2\x1f\xa5\xcf\xb0\xa0\x26\xb1\xb7\x2e\xab\xb6\x23\x1e\xf4\xaa\x20\xaf\x2e\xaa\x1f\xad\xad\x1f\xa6\x48\xc1\x3d\x26\x68\x61\xed\x20\xd2\xda\xa3\x20\x23\x59\x35\xb1\x44\x22\x9e\xcc\x2a\x36\x20\xa7\xaf\xa7\xa4\x21\xb2\xa3\x2b\x22\x47\x22\xbe\x9e\x2d\x28\x9e\x9f\x2a\xad\x22\xc6\xb2\x25\x24\xc8\x9e\xb9\xa2\xa8\x56\xa1\x21\xe5\x1f\x54\xac\x68\xaf\xb4\x1f\xea\xaf\xb9\x26\xb4\x28\x52\xa9\x9e\x21\xbb\x60\x1f\xab\x9e\xa2\x2d\xa5\x38\xa7\x29\xbd\xa3\x26\xa1\xa9\x2f\x26\xa0\x3a\x4c\xab\x29\xa8\xb0\x07\x07\x08\x08\x08\x09\x09\x0a\x0a\x0a\x0b\x0b\x0b\x0c\x0c\x0c"));
snd($sock_a, $port_b, rtp(9, 2004, 5120, 0x5678, "\x3a\x96\x24\x86\x21\x84\x04\x8c\x4d\xd0\xd1\xd2\x94\xd5\xd5\xd6\xd7\xd8\x98\xd8\xd8\xd8\xd8\xd8\xd8\xd8\xd9\xd9\xda\xda\xda\xdb\xdc\x9a\xda\xdb\x9c\xda\xda\x9c\xda\xda\xdb\xdc\xda\xdb\xdd\xdb\xdb\xdc\xda\xdb\xdb\xdd\xda\xdb\xdc\xda\xda\xda\xdc\xd9\xd9\xdb\xdc\xd8\xd8\xda\xdb\xdc\xd8\xd9\xda\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xda\xdb\xdb\xdb\xdb\xde\xda\xdb\xdb\xdb\xdb\xdb\xde\xda\xdb\xdc\xd6\xdc\xd7\xff\xd8\xd8\xda\xda\xdb\xd9\xdc\xd9\xdb\xdc\xd6\xdd\xd8\xd9\xdc\xd7\xfc\xd7\xdd\xd9\xd9\xdb\xdc\xd9\xd9\xdb\xde\xd9\xd8\xdb\xdf\xda\xda\xdd\xd9\xd9\xda\xde\xda\xdb\xdf\xdc\xd5\xdb\xff\xd6\xde\xdc\xd9\xd9\xd8\xdd\xd9\xda\xfe"));
rcv($sock_b, $port_a, rtpm(0, 2006, 4960, $ssrc, "\x0d\x0d\x0d\x0e\x0e\x0e\x0f\x10\x13\x15\x1e\x0c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x01\x02\x02\x03\x04\x04\x05\x05\x06\x07\x07\x07\x08\x08\x09\x09\x0a\x0a\x0a\x0b\x0b"));

rtpe_req('delete', 'G.722 reverse DTX', { 'from-tag' => ft() });



done_testing();