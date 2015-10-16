#!/usr/bin/perl

# s02_vcf2tab.pl
# Convert vcf-vep to tab-delimited text file
# Alexey Larionov, 15Oct2015

# Use: s06_vcf2tab.pl input_file samples_suffix

# Set environment
use strict;
use warnings;

# -------------------------------------------------------- #
#                     Initial settings                     #
# -------------------------------------------------------- #

my $VCF_in = $ARGV[0]
my $samples_suffix = $ARGV[1]

my $plate = "6";
my $library = "2";

my $samples_suffix = "_sort_dedup.bam";

my $VCF_in = "/home/alarionov/Work/data/wecare/vep/w${plate}.lib${library}.vep.vcf";
my $File_out = "/home/alarionov/Work/data/wecare/tab/w${plate}_lib${library}.txt";

# -------------------------------------------------------- #
#               Report settings to terminal                #
# -------------------------------------------------------- #

print	"\nTabulating VCF VEP file\n".
		"Input VCF file: $VCF_in\n".
		"Output file: $File_out\n".
		"Samples suffix: $samples_suffix\n\n";

# -------------------------------------------------------- #
#         Make arrays for the vcf and info fields          #
# -------------------------------------------------------- #

# Notes: 
# For now VCF and INFO are set manually.  These fields are expected to be more or less stable.   
# Later they may be red from the input file, like the other fields below.
# AT prsent script assumes that the sequence of the vcf fields is constant in input VCF file  

# Array with vcf fields names names
my @vcf_fields = qw(CHROM POS ID REF ALT QUAL FILTER INFO FORMAT);

# Array with vcf info fields names
my @info_codes = qw(DP DP4 MQ FQ AF1 AC1 AN IS AC G3 HWE CLR UGT CGT PV4 INDEL PC2 PCHI2 QCHI2 PR QBD RPB MDV VDB CSQ);

# Add INFO_ prefix to each element of @info_fields
my @info_fields = @info_codes ;
for (@info_fields) { $_ = "INFO_" . $_; }

# -------------------------------------------------------- #
#          Read samples names from input vcf file          # 
# -------------------------------------------------------- #

# Declare array for samples names
my @samples; 

# Open input file
open my $VCF_in_FH, "<$VCF_in" or die "Input file $VCF_in cannot be opened: $!\n";

# Look for the line starting with #CHROM
while (<$VCF_in_FH>) {
      if (/^#CHROM/) {
         chomp;
         @samples = split /\t/; # Read the line into array
         last;
      }
}

# Close input file
close $VCF_in_FH or die "Cannot close $VCF_in: $!\n"; 

# Select samples from the line:
# VCF field names do not have the suffix 
@samples = grep(/$samples_suffix/, @samples);

# Remove suffixes from the samples names
for (@samples) { s/$samples_suffix//; } 

# -------------------------------------------------------- #
#           Read VEP fields  from input vcf file           #
# -------------------------------------------------------- #

# Declare needed array and scalar
my $vep_line;
my @vep_fields;
my $vep_line_head = "##INFO=<ID=CSQ,";

# Open input file
open $VCF_in_FH, "<$VCF_in" or die "Input file $VCF_in cannot be opened: $!\n";

# Look for the line starting with ##INFO=<ID=CSQ,
while (<$VCF_in_FH>) {
      if (/^($vep_line_head)/) {
         chomp;
         $vep_line = $_; # Read line into variable
         last;
      }
}

# Close input file
close $VCF_in_FH or die "Cannot close $VCF_in: $!\n"; 

# Remove the head and tail from VEP string
my $start_vep = index($vep_line , "Format: ");
$vep_line = substr($vep_line, $start_vep + 8, -2);

# Split string into array
# Negative limit may be needed to preserve empty trailing elements (if any)
# http://stackoverflow.com/questions/9161952/splitting-on-pipe-character-in-perl 
@vep_fields = split(/\|/, $vep_line, -1);

# Add VEP_ prefix to each element of @vep_fields
for (@vep_fields) { $_ = "VEP_" . $_; }

# --------------------------------------------------------------- #
#    Read format field from the first variant in input vcf file   # 
# --------------------------------------------------------------- #
my $nextline;

# Open input file
open $VCF_in_FH, "<$VCF_in" or die "Input file $VCF_in cannot be opened: $!\n";

# Look for the line starting with #CHROM
while (<$VCF_in_FH>) {
      if (/^#CHROM/) {
         $nextline = <$VCF_in_FH>; # read next line after the one starting with #CHROM
         last;
      }
}

# Close input file
close $VCF_in_FH or die "Cannot close $VCF_in: $!\n"; 

# Select format field
chomp($nextline);
my @nextline = split(/\t/, $nextline); # Read the line into array
my $formats = $nextline[8]; # e.g. "GT:PL:DP:DV:SP"
my @formats = split(":", $formats); # e.g. GT PL DP DV SP

# -------------------------------------------------------- #
#     Prepare array with column names for output file      #
# -------------------------------------------------------- #

# Start field names for output table
my @fields = (@vcf_fields, @samples, @info_fields, @vep_fields);

# Add fields for parsed samples data
foreach my $sample (@samples){
        foreach my $format (@formats){
	              push(@fields, $sample."_".$format);
        }
}

# -------------------------------------------------------- #
#      Make hashes with numbers of arrays elements         #
# -------------------------------------------------------- #

# Hash with array indices for the output table fields 
my %fields; 
foreach my $field_no (0..$#fields) {
        $fields{$fields[$field_no]} = $field_no;
}

# Hash with array indices for the vep fields 
my %vep_fields; 
foreach my $vep_field_no (0..$#vep_fields) {
        $vep_fields{$vep_fields[$vep_field_no]} = $vep_field_no;
}

# Hash with array indices for the samples 
my %samples; 
foreach my $sample_no (0..$#samples) {
        $samples{$samples[$sample_no]} = $sample_no;
}

# -------------------------------------------------------- #
#          Parse input file and make output file           #
# -------------------------------------------------------- #

# Open input file
open $VCF_in_FH, "<$VCF_in" or die "Input file $VCF_in cannot be opened: $!\n"; 

# Create ouput file
open my $File_out_FH, ">$File_out" or die "Output file $File_out cannot be created: $!\n";

# Print header to output file
print $File_out_FH join("\t", @fields)."\n";

# --- Parse input file line by line --- #

# For each line in the input file
while (<$VCF_in_FH>)
{

	# Skip comments & header
	next if /^#/;

  # Remove "new-line" at the end (just in case)
	chomp;

  # ---------- Populate the initial elements ---------- # 
  
  # VCF fields and non-parced INFO and samples data
	my @line = split /\t/; 

  # Add dashes for the rest of fields
  # The num of initial elements: $#line
  # The total num of output fields: $#fields
	push(@line, (('-') x ($#fields - $#line)));

	# ---------- Parse INFO field (column 8) ---------- #
 
	my @info = split(/;/, $line[$fields{'INFO'}]); 
 
  # For each INFO element 
	foreach my $element (@info)
	{
		my @element = split(/=/, $element);
		my $code = $element[0];
		my $value = $element[1]; # How this line works for INDEL?
		
    # For each possible INFO code
    foreach my $code_no (0..$#info_codes) {
            
            # If code match with the element
            if ($code eq $info_codes[$code_no]) {
               
               # Handle special case for INDEL coding
               if ($code eq "INDEL") { $value = "INDEL"; }  # INFO-INDEL,Number=0 !!!
               
               # Write value to appropriate field of the output table
               $line[$fields{$info_fields[$code_no]}] = $value;
               
			         # Handle special case for CSQ field: parce VEP data
               if ($code eq "CSQ") {

                  # Split CSQ field into separate VEP elements
			            my @vep = split(/\|/, $line[$fields{'INFO_CSQ'}], -1); 
                  
                  # For each VEP element in CSQ field
                  foreach my $vep_no (0..$#vep) {
                  
                          # Substitute "-" to the VEP value, if present
      			              if (defined $vep[$vep_no] && $vep[$vep_no] ne '') {$line[$fields{$vep_fields[$vep_no]}] = $vep[$vep_no];}
                                           
                  } # Next VEP element in the field
               }
               
               # Stop checking codes for this element
               last;
            }
            
    } # Next info code
   
	} # Next info element

	# ---------- Parse samples data ---------- #

	# Check data format for samples fields 
	# NB: Make sure the format string (GT:PL:DP:DV:SP) corresponds to what is expected in the vep file 
	die "Unexpected format at line $.\n" if $line[$fields{'FORMAT'}] ne $formats; 

  # For each sample
	foreach my $sample (@samples){

		# Get sample data to array
		my @data = split(/:/, $line[$fields{$sample}]);

    # Set sample's offset: where the parsed sample start (account for 0-based array addresses)
		my $base = ($#vcf_fields + 1) + ($#samples + 1) + ($#info_fields + 1) + ($#vep_fields + 1) + $samples{$sample} * ($#formats + 1); 
    
    # For each format
    my $format_no = 0;  
    foreach my $format (@formats){
            
		        # Write sample data  (0-based array addresses)
		        $line[$base + $format_no] = $data[$format_no];
            
            # Increment format number
            $format_no = $format_no + 1 ;

    } # next format
    
	} # next sample

	# Write line to output file
	print $File_out_FH join("\t", @line)."\n";

} # Next line in the input VCF file


# Tidy up ...
close $VCF_in_FH or die "Cannot close $VCF_in: $!\n"; 
close $File_out_FH or die "Cannot close $File_out: $!\n"; 

# Completion message to terminal
print "Done\n\n"; 

