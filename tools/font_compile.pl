#!/usr/bin/perl
use strict;

# This script converts "space-dot" fonts to binary "glyph rows". One byte for
# each row. In a 5x7 font, each glyph thus use 7 bytes.

my $fn = @ARGV[0];
unless ($fn =~ /.*(\d)x(\d)\.txt/) { die "$fn isn't a font filename" };
my ($width, $height) = ($1, $2);

print STDERR "Reading a $width x $height font.\n";

my $handle;
unless (open($handle, '<', $fn)) { die "Can't open $fn"; }

# We start the binary data with our first char, space, which is not in our input
# but needs to be in our output.
print pack('C*', (0) x $height);

while (<$handle>) {
    unless (/( |\.){${width}}\n/) { die "Invalid line format '$_'"; }
    my @line = split //, $_;
    my $num = 0;
    for (my $i=$width-1; $i>=0; $i--) {
        if (@line[$width-$i-1] eq '.') {
            $num += (1 << $i);
        }
    }
    printf pack('C', $num);
}
