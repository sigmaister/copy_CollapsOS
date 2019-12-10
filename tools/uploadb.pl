#!/usr/bin/perl
# Push specified file to specified device **running the BASIC shell** and verify
# that the sent contents is correct.
use strict;
use Fcntl;

if (@ARGV != 3) {
    print "Usage: ./uploadb.pl device memptr filename\n";
    exit 1;
}

my ($device, $memptr, $fname) = @ARGV;

if (hex($memptr) >= 0x10000) { die "memptr is out of range"; }

if (! -e $fname) { die "${fname} does not exist"; }
my $fsize = -s $fname;
my $maxsize = 0x10000 - hex($memptr);
if ($fsize > $maxsize) { die "File too big. ${maxsize} bytes max"; }

my $fh;
unless (open($fh, '<', $fname)) { die "Can't open $fname"; }

my $devh;
unless (sysopen($devh, $device, O_RDWR|O_NOCTTY)) { die "Can't open $device"; }

sub sendcmd {
    # The serial link echoes back all typed characters and expects us to read
    # them. We have to send each char one at a time.
    my $junk;
    foreach my $char (split //, shift) {
        syswrite $devh, $char;
        sysread $devh, $junk, 1;
    }
    syswrite $devh, "\n";
    sysread $devh, $junk, 2; # send back \r\n
}

sendcmd("m=0x${memptr}");

my $rd;
sysread $devh, $rd, 2; # read prompt

# disable buffering
$| = 1;

while (sysread $fh, my $char, 1) {
    print ".";
    for (my $i=0; $i<5; $i++) { # try 5 times
        sendcmd("getc");
        syswrite $devh, $char;
        sysread $devh, $rd, 2; # read prompt
        sendcmd("puth a");
        sysread $devh, $rd, 2;
        my $ri = hex($rd);
        sysread $devh, $rd, 2; # read prompt
        if ($ri == ord($char)) {
            last;
        } else {
            if ($i < 4) {
                print "Mismatch at byte ${i}! ${ri} != ${ord($char)}. Retrying.\n";
            } else {
                die "Maximum retries reached, abort.\n";
            }
        }
    }
    sendcmd("poke m a");
    sysread $devh, $rd, 2; # read prompt
    sendcmd("m=m+1");
    sysread $devh, $rd, 2; # read prompt
}

print "Done!\n";
close $fh;
close $devh;
