#!/usr/bin/perl

# Copyright 2012 Illumina 
# 
#     Licensed under the Apache License, Version 2.0 (the "License"); 
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software 
# distributed under the License is distributed on an "AS IS" BASIS, 
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and 
# limitations under the License.
 
use strict;
use Getopt::Long;
use JSON;
use Data::Dumper;
use LWP;
use LWP::Simple;
use HTTP::Request;

my $self = bless {};

# /usr/local/lib/python2.7/dist-packages/BaseSpacePy/api/BaseAPI.py
my $UROOT = "/data/output/appresults/";
my $DROOT = "/data/input/samples/";

my $debug;
my $AccessToken; my $AppSessionId; my $ApiUrl; my $exe; my $file1; my $file2;
GetOptions(
       'AccessToken:s'  => \$AccessToken,
       'AppSessionId:s' => \$AppSessionId,
       'ApiUrl:s'       => \$ApiUrl,
       'exe:s'          => \$exe,
       'debug'          => \$debug,
    );

print STDERR "AccessToken $AccessToken\n";
print STDERR "AppSessionId $AppSessionId\n";
print STDERR "ApiUrl $ApiUrl\n";

$DB::single=1;1;

exit(0) if (2 == $debug);

my $curl_cmd; my $curl_url; my $json_str;

exit(0) unless (defined $AppSessionId || $debug);

$json_str  = get_appsession_properties($AppSessionId);
my $json = JSON::decode_json($json_str);
my $s3file1; my $s3file2;
foreach my $hash (@{$json->{Response}{Items}}) {
    $DB::single=1;1;
    print Dumper $hash;
}
exit 0;

$file1 = $s3file1 if (defined $s3file1);
$file2 = $s3file2 if (defined $s3file2);

my $wget_cmd = "wget -O \"$file1\" -c \"$s3file1\"";
my $wget_ret = `$wget_cmd`;

########################################
# METHODS

sub get_appsession_properties {
    my $AppSessionId = shift;

#    my $curl_url = "$ApiUrl/v1pre3/appsessions/$AppSessionId/properties/Input.file-id";
    my $curl_url = "$ApiUrl/v1pre3/appsessions/$AppSessionId/properties/";
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

########################################
# Perl SDK



sub APIClient_init {
    my $self = shift;
    my $AccessToken = shift || undef;
    my $apiServer   = shift || undef;
    my $timeout     = shift || 10;

    unless (defined $AccessToken) {
    die('You must pass an access token when instantiating the
	APIClient');
    }

    $self->{apiKey}     = $AccessToken;
    $self->{apiServer}  = $apiServer;
    $self->{timeout}    = $timeout;

    return;
}

sub APIClient_forcePostCall {
    my $self = shift;
    my $resourcePath = shift;
    my $postData = shift;
    my $headers = shift;
    my $data = shift || undef;

    # For forcing a post request using pycurl
    # :param qParams:Query oaramter string
    # :param resourcePath: The url 

    # FIXME
    warn('Method not implemented (yet).');
#
#        postData = [(p,postData[p]) for p in postData]
#        headerPrep  = [k + ':' + headers[k] for k in headers.keys()]
#        post =  urllib.urlencode(postData)
##        print "header prep " + str(headerPrep)
##        print "post " + str(post)
#        response = cStringIO.StringIO()
#        c = pycurl.Curl()
#        c.setopt(pycurl.URL,resourcePath + '?' + post)
#        c.setopt(pycurl.HTTPHEADER, headerPrep)
#        c.setopt(pycurl.POST, 1)
#        c.setopt(pycurl.POSTFIELDS, post)
#        c.setopt(c.WRITEFUNCTION, response.write)
#        c.perform()
#        c.close()
#        return response.getvalue()

    return;
}

sub APIClient_putCall {
    my $self = shift;
    my $resourcePath = shift;
    my $postData = shift;
    my $headers = shift;
    my $transFile = shift;
    
# FIXME
##        headerPrep  = [k + ':' + headers[k] for k in headers.keys()]
#        name = '/home/mkallberg/Desktop/multi/tempfiles/temp.bam' + resourcePath.split('/')[-1]  
#        f = open(name,'w')
#        f.write(data)
#        f.close()
#        f = open(name)
#        print len(f.read())
#        c = pycurl.Curl()
#        c.setopt(pycurl.URL,resourcePath)
#        c.setopt(pycurl.HTTPHEADER, headerPrep)
#        c.setopt(pycurl.PUT, 1)
#        c.setopt(pycurl.UPLOAD,dataInput)
#        c.setopt(pycurl.INFILESIZE,10239174)
#        c.setopt(c.WRITEFUNCTION, response.write)
#        c.perform()
#        c.close()
#        print resourcePath
#        
    my $cmd;
    $cmd = 'curl -H "x-access-token:' . $self->apiKey . '" -H "Content-MD5:' . $headers->{'Content-MD5'} .'" -T "'. $transFile .'" -X PUT ' . $resourcePath;
        ##cmd = data +'|curl -H "x-access-token:' + self.apiKey + '" -H "Content-MD5:' + headers['Content-MD5'].strip() +'" -d @- -X PUT ' + resourcePath
    my $output = `$cmd`;

    return $output;
}

sub APIClient_callAPI {
    my $self = shift;
    my $resourcePath = shift;
    my $method = shift;
    my $queryParams = shift;
    my $postData = shift;
    my $headerParams = shift || undef;
    my $forcePost = shift || 0;

    my $url;
    my $response;
    $url = $self->apiServer . $resourcePath;
    my $headers;
    if ($headerParams) {
	foreach my $param (keys %$headerParams) {
	    $headers->{$param} = $headerParams->{$param};
	}
    }
    # specify the content type
    unless (defined $headers->{'Content-Type'} && $method eq 'PUT' && defined $forcePost) {
	$headers->{'Content-Type'} = 'application/json';
    }

    # include access token in header 
    $headers->{'Authorization'} = 'Bearer ' + $self->apiKey;
        
    my $data = undef;

    my $sentQueryParams;
    if ($queryParams) {
	# Need to remove None values, these should not be sent
	foreach my $param (keys %$queryParams) {
	    my $value = $queryParams->{$param};
	    if (defined $value && $value ne '') {
		$sentQueryParams->{$param} = $value;
	    }
	}
    }
    
    if ($method eq 'GET') {
	$url = $url . '?' . $self->urlencode($sentQueryParams) if (defined $sentQueryParams);
	# TODO: headers? my $request = get($url=url, $headers)
	my $request = get($url);
    } elsif ($method =~ /POST|PUT|DELETE/) {
	my $forcePostUrl = $url; 
	$url = $url . '?' . $self->urlencode($sentQueryParams) if (defined $sentQueryParams);
	my $data = $postData;
	if (defined $data) {

	    $DB::single=1;1;
	    # TODO - check if postData is JSON, then:
	    # if type(postData) not in [str, int, float, bool]:
            #         data = json.dumps(postData)
	}

	unless ($forcePost) {
	    if ($data && 0 == length($data)) { $data='\n'; }
	    # temp fix, in case is no data in the file, to prevent post request from failing
	    my $request = get($url);
	} else {
	    # use pycurl to force a post call, even w/o data
	    $response = $self.APIClient_forcePostCall($forcePostUrl,$sentQueryParams,$headers);
	}

	if ($method =~ /PUT|DELETE/) { #urllib doesnt do put and delete, default to pycurl here
	    $response = $self.APIClient_putCall($url, $queryParams, $headers, $data);
	    $DB::single=1;1;
	    #response =  response.split()[-1]
	}
               
    } else {
	    warn('Method ' . $method . ' is not recognized.');
    }

       # Make the request, request may raise 403 forbidden, or 404 non-response
    if (!$forcePost && $method !~ /PUT|DELETE/) {                                      # the normal case
#	print "$url\n";
	#print request
#	print "request with timeout=" , $self->timeout, "\n";
        eval {
#	    my $response = get($request,timeout=self.timeout).read()
	    $response = get($url);
	};
	if ($@) {
	    die "Error $@";
	}
	eval {
	    $data = JSON::decode_json($response);
	};
	if ($@) {
           $data=undef;
	}
    }

    return $data;
}

=head2 apiKey

  Arg [1]    : (optional) String - the apiKey to set
  Example    : $self->apiKey('qwerty');
  Description: Getter/setter for attribute apiKey
  Returntype : String
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub apiKey {
    my $self = shift;
    $self->{'apiKey'} = shift if( @_ );
    return $self->{'apiKey'};
}

=head2 apiServer

  Arg [1]    : (optional) String - the apiServer to set
  Example    : $self->apiServer('https://api.basespace.illumina.com');
  Description: Getter/setter for attribute apiServer
  Returntype : String
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub apiServer {
    my $self = shift;
    $self->{'apiServer'} = shift if( @_ );
    return $self->{'apiServer'};
}

=head2 timeout

  Arg [1]    : (optional) String - the timeout to set
  Example    : $self->timeout(10);
  Description: Getter/setter for attribute timeout
  Returntype : Integer
  Exceptions : none
  Caller     : general
  Status     : Stable

=cut

sub timeout {
    my $self = shift;
    $self->{'timeout'} = shift if( @_ );
    return $self->{'timeout'};
}

sub urlencode {
    my $self = shift;
    return $self->escape_hash(@_);
}

sub escape_hash {
    my %hash = @_;
    my @pairs;
    for my $key (keys %hash) {
        push @pairs, join "=", map { uri_escape($_) } $key, $hash{$key};
    }
    return join "&", @pairs;
}

# Borrowed from URI::Escape
# Build a char->hex map
my %escapes;
for (0..255) {
    $escapes{chr($_)} = sprintf("%%%02X", $_);
}

my %subst;  # compiled patterns

my %Unsafe = (
    RFC2732 => qr/[^A-Za-z0-9\-_.!~*'()]/,
    RFC3986 => qr/[^A-Za-z0-9\-\._~]/,
);

sub uri_escape {
    my($text, $patn) = @_;
    return undef unless defined $text;
    if (defined $patn){
        unless (exists  $subst{$patn}) {
            # Because we can't compile the regex we fake it with a cached sub
            (my $tmp = $patn) =~ s,/,\\/,g;
            eval "\$subst{\$patn} = sub {\$_[0] =~ s/([$tmp])/\$escapes{\$1} || _fail_hi(\$1)/ge; }";
	    warn("uri_escape: $@") if $@;
        }
        &{$subst{$patn}}($text);
    } else {
        $text =~ s/($Unsafe{RFC3986})/$escapes{$1} || _fail_hi($1)/ge;
    }
    $text;
}

sub _fail_hi {
    my $chr = shift;
    warn(sprintf "Can't escape \\x{%04X}, try uri_escape_utf8() instead", ord($chr));
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
