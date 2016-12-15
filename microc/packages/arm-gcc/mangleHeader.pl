#/usr/bin/perl -w
#
# whip6: Warsaw High-performance IPv6.
#
# Copyright (c) 2012-2016 InviNets Sp z o.o.
# All rights reserved.
#
# This file is distributed under the terms in the attached LICENSE     
# files. If you do not find these files, copies can be found by writing
# to technology@invinets.com.
#

sub printUsage
{
    printf STDERR "Usage:\n    $0 <input.h> <output.h>\n\n";
}

my $numArgs = @ARGV;
if ($numArgs != 2) {
    printf STDERR "ERROR: Invalid arguments!\n\n";
    printUsage();
    exit 1;
}

my $inputFilePath = $ARGV[0];
my $outputFilePath = $ARGV[1];
my $INPUT_FILE;
my $OUTPUT_FILE;
if (!open($INPUT_FILE, "<$inputFilePath"))
{
    printf STDERR "ERROR: Unable to open the input file, \"$inputFilePath\"!\n\n";
    printUsage();
    exit 1;
}
if (!open($OUTPUT_FILE, ">$outputFilePath"))
{
    printf STDERR "ERROR: Unable to open the output file, \"$outputFilePath\"!\n\n";
    printUsage();
    close($INPUT_FILE);
    exit 1;
}

my $commentLevel = 0;
while (<$INPUT_FILE>)
{
    # Skip comments.
    if ($_ =~ /^\/\//)
    {
        printf $OUTPUT_FILE $_;
        next;
    }
    if ($_ =~ /\*\//)
    {
        --$commentLevel;
    }
    if ($commentLevel > 0)
    {
        printf $OUTPUT_FILE $_;
        next;
    }
    if ($_ =~ /\/\*/)
    {
        ++$commentLevel;
    }

    s{(\#define\s+MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE)}{//$1}g;
    s{(\#define\s+MCS51_STORED_IN_RAM)}{//$1}g;
    s{MCS51_OPTIMIZE_POINTERS_TO_RAM_STORAGE\(([_a-zA-Z][_a-zA-Z0-9]*)\)}{typedef $1 $1_xdata\; typedef $1_xdata whip6_$1;}g;
    s{([_a-zA-Z][_a-zA-Z0-9]*)\s+MCS51_STORED_IN_RAM}{$1_xdata}g;
    s{WHIP6_MICROC_EXTERN_DECL_PREFIX}{extern}g;
    s{WHIP6_MICROC_EXTERN_DECL_SUFFIX}{}g;
    s{WHIP6_MICROC_EXTERN_DEF_PREFIX}{}g;
    s{WHIP6_MICROC_EXTERN_DEF_SUFFIX}{}g;
    s{WHIP6_MICROC_PRIVATE_DECL_PREFIX}{static}g;
    s{WHIP6_MICROC_PRIVATE_DECL_SUFFIX}{}g;
    s{WHIP6_MICROC_PRIVATE_DEF_PREFIX}{static}g;
    s{WHIP6_MICROC_PRIVATE_DEF_SUFFIX}{}g;
    s{WHIP6_MICROC_INLINE_DECL_PREFIX}{static inline}g;
    s{WHIP6_MICROC_INLINE_DECL_SUFFIX}{}g;
    s{WHIP6_MICROC_INLINE_DEF_PREFIX}{static inline}g;
    s{WHIP6_MICROC_INLINE_DEF_SUFFIX}{}g;


    printf $OUTPUT_FILE "%s", $_;
    
}
close($INPUT_FILE);
close($OUTPUT_FILE);

