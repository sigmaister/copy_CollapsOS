#!/usr/bin/perl
use strict;

# This script converts "space-dot" fonts to binary "glyph rows". One byte for
# each row. In a 5x7 font, each glyph thus use 7 bytes.
# Resulting bytes are aligned to the **left** of the byte. Therefore, for
# a 5-bit wide char, ". . ." translates to 0b10101000
# Left-aligned bytes are easier to work with when compositing glyphs.

my $fn = @ARGV[0];
unless ($fn =~ /.*(\d)x(\d)\.txt/) { die "$fn isn't a font filename" };
my ($width, $height) = ($1, $2);

if ($width > 8) { die "Can't have a width > 8"; }

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
    for (my $i=0; $i<8; $i++) {
        if (@line[$i] eq '.') {
            $num += (1 << (7-$i));
        }
    }
    print pack('C', $num);
}
