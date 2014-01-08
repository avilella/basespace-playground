#!/usr/bin/perl
use strict;
use lib '/home/avilella/src/basespace/samtools/perl/lib/perl5';
use Getopt::Long;
use JSON;

my $inputfile = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data/HG00154/alignment/HG00154.chrom11.ILLUMINA.bwa.GBR.low_coverage.20120522.bam";
my $indexfile = "ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data/HG00154/alignment/HG00154.chrom11.ILLUMINA.bwa.GBR.low_coverage.20120522.bam.bai";
my $samtools_exe = "/home/app/samtools-0.1.19/samtools";
# DEBUG
$samtools_exe = "/home/avilella/src/basespace/samtools/samtools-0.1.19/samtools" unless (-x $samtools_exe);
my $exe = "$samtools_exe idxstats ";
my $debug;
my $AccessToken; my $AppSessionId; my $ApiUrl;
GetOptions(
       'AccessToken:s'  => \$AccessToken,
       'AppSessionId:s' => \$AppSessionId,
       'ApiUrl:s'       => \$ApiUrl,
       'debug'          => \$debug,
    );

print STDERR "AccessToken $AccessToken\n";
print STDERR "AppSessionId $AppSessionId\n";
print STDERR "ApiUrl $ApiUrl\n";

exit(0) if (2 == $debug);

my $curl_cmd; my $curl_url; my $json_str;

exit(0) unless (defined $AppSessionId || $debug);

$json_str  = get_appsession_properties($AppSessionId);
my $json = JSON::decode_json($json_str);
my $bam; my $bai;
foreach my $hash (@{$json->{Response}{Items}}) {
  my $str = get_files_content($hash->{Href});
  $str =~ /(Location\:) (\S+)/;
  my $s3_url = $2 if (defined $2 && defined $1);
  $bam = $s3_url if ($s3_url =~ /\.bam\&/);
  $bai = $s3_url if ($s3_url =~ /\.bam\.bai\&/);
}
$inputfile = $bam if (defined $bam);
$indexfile = $bai if (defined $bai);

# If ftp:/ or http:/ then samtools searches for the string after the
# first "/" and adds ".bai" to try to load the bai file. In BaseSpace
# this will be something like:
# "octet-stream&Signature=blablablah.bai";
# so we manually download the bai file and rename it like samtools
# expects.

my $local_bam = $inputfile; $local_bam =~ s/.+\///;;
my $local_bai = "$local_bam.bai";
my $wget_cmd = "wget -O \"$local_bai\" -c \"$indexfile\"";
my $wget_ret = `$wget_cmd`;

$inputfile =~ s/https\:\/\//http\:\/\//;
my $cmd = "$exe \"$inputfile\"";
my $ret = `$cmd`;
print $ret;

########################################
# METHODS

sub get_appsession_properties {
    my $AppSessionId = shift;

    my $curl_url = "$ApiUrl/v1pre3/appsessions/$AppSessionId/properties/Input.file-id";
    my $curl_cmd = "curl -v -H \"x-access-token: $AccessToken\" -H \"Content-type: application/json\" -X GET $curl_url";
    my $json_str = `$curl_cmd`;

    print "json_str $json_str\n" if ($debug);

    return $json_str;
}

sub get_files_content {
    my $Href = shift;

    my $curl_url = "$ApiUrl/". $Href ."/content";
    my $curl_cmd = "curl -v -H \"x-access-token: $AccessToken\" -H \"Content-type: application/json\" -X GET $curl_url";
    my $str = `$curl_cmd 2>&1`;

    return $str;
}

## Standard callbacks.js
# function launchSpec(dataProvider)
# {
#     return [
#         {
#             commandLine: ["/usr/bin/perl /home/app/samtools_idxstats.pl", "-AccessToken $AccessToken", "-AppSessionId $AppSessionId", "-ApiUrl $ApiUrl"],
#             containerImageId:"avilella/samtools-0.1.19"
#         }
#     ];
# }

## Multilaunch callbacks.js
# function launchSpec(dataProvider)
# {
#     var retval = { nodes: [] };
#    
#     retval.nodes.push({
#             commandLine: ["/usr/bin/perl /home/app/samtools_idxstats.pl -AccessToken $AccessToken -AppSessionId $AppSessionId -ApiUrl $ApiUrl"],
#             containerImageId:"avilella/samtools-0.1.19"
#     });
#    
#     return retval;
# }


1;
