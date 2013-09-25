#!/usr/local/sbin/perl-suid

use strict;
use warnings;
use CGI;
1;

sub make_json_call ($\%);

sub json_load_files ($) {
	#Sub to pull out files from a single torrent, and return an array containing them

	my $id = int shift;

	my $method = "torrent-get";

	my %object = (
		fields => ["files","name","priorities","wanted"],
		ids => [$id]
	);

	my %result; 

	# Make call
	my $result = make_json_call($method,%object);

	#de-ref the hash for use below
        (%result) = %{($result)};
	
	#die "first file name is ".$result{"arguments"}->{"torrents"}->[0]->{"files"}->[0]->{"name"}."\n";

	if ( defined($result{"error"})) {
		my @error_array = ("error",$result{"error"});
		return \@error_array;
	} else {
		# Pull torrent_file array into array variable
		my $torrent_ref = $result{"arguments"}->{"torrents"};

		return $torrent_ref;
	}
}

sub json_pause_torrent($$) {
	#Sub to pause / unpause torrent(s)
	
	my $id = shift;
	my $pause = shift;

        my %config = load_config();
        my $return = "";

        $id = clean_data($id);
        
	my $method = "";
	my %object;
	
	my @num_ids;
	
	my @ids = split(/,/,$id);

	# Pull each item out of id, convert to int and then put into integer array
	foreach my $no_id (@ids) {
		push(@num_ids,int $no_id);
	}
	
	$object{"ids"} = \@num_ids;
	
        if ($pause eq "false") {
		$method = "torrent-start";
	} else {
		$method = "torrent-stop";
	}
	
	# Make call
	my $result = make_json_call($method,%object);

	return $result;
}

sub json_load_info ($) {
	#Sub to pull out details of all torrents for the main operate page, and return an array containing them

	my $id = int shift;

	my $method = "torrent-get";

	my %object = (
		fields => ["activityDate","addedDate","bandwidthPriority","comment","corruptEver","creator","dateCreated","desiredAvailable","doneDate","downloadDir","downloadedEver","downloadLimit","downloadLimited","error","errorString","eta","hashString","haveUnchecked","haveValid","honorsSessionLimits","id","isFinished","isPrivate","leftUntilDone","name","peersConnected","peersGettingFromUs","peersSendingToUs","peer-limit","pieceCount","pieceSize","rateDownload","rateUpload","recheckProgress","secondsDownloading","secondsSeeding","seedRatioMode","seedRatioLimit","sizeWhenDone","startDate","status","totalSize","uploadedEver","uploadLimit","uploadLimited","webseeds","webseedsSendingToUs"],
		ids => [$id]
	);

	my %result; 

	# Make call
	my $result = make_json_call($method,%object);

	#de-ref the hash for use below
        (%result) = %{($result)};
	
	#die "torrent ".$result{"arguments"}->{"torrents"}->[0]->{"id"}." activity date is ".$result{"arguments"}->{"torrents"}->[0]->{"activityDate"}."\n";

	if ( defined($result{"error"})) {
		my @error_array = ("error",$result{"error"});
		return \@error_array;
	} else {
		# Pull torrent array into array variable
		my $torrent_ref = $result{"arguments"}->{"torrents"};

		return $torrent_ref;
	}
}

sub json_load_torrents () {
	#Sub to pull out details of all torrents for the main operate page, and return an array containing them

	#my $id = int shift;

	my $method = "torrent-get";

	my %object = (
		fields => ["error","errorString","eta","id","isFinished","leftUntilDone","name","peersGettingFromUs","peersSendingToUs","rateDownload","rateUpload","sizeWhenDone","status","downloadedEver","uploadedEver","uploadRatio"]
	);

	my %result; 

	# Make call
	my $result = make_json_call($method,%object);

	#de-ref the hash for use below
        (%result) = %{($result)};
	
	#die "first torrent name is ".$result{"arguments"}->{"torrents"}->[1]->{"name"}."\n";
	
	if ( defined($result{"error"})) {
		my @error_array = ("error",$result{"error"});
		return \@error_array;
	} else {
		# Pull torrent array into array variable
		my $torrent_ref = $result{"arguments"}->{"torrents"};

		return $torrent_ref;
	}
}

sub make_json_call ($\%) {
	use JSON::RPC::Client;

        my $loop = 1;
	my $count = 0;

	my $content;

        my $method = shift;
        my (%arguments) = %{(shift)};

        my $client = new JSON::RPC::Client;
        my $uri    = 'http://localhost:9091/transmission/rpc';
        my $server = 'localhost:9091';

        while($loop == 1) {

	        my %config = load_config();

        	my $key = $config{'session_id'};

		$client->ua->credentials("$server",'Transmission',$config{remote_user},$config{remote_pass});

		$client->ua->default_header('X-Transmission-Session-Id'=>"$key");

                my $callobj = {
                      method  => $method,
                      arguments  => {%arguments} # ex.) params => { a => 20, b => 10 } for JSON-RPC v1.1
                };

                my $res = $client->call($uri, $callobj);

                if($res) {
                        if ($res->is_error) {
                                #print "Error: $res->error_message";
                                $loop = 0;
                                #print "Error occured\n";
                        }
                        else {
                                $loop = 0;
                                return $res->content;
                        }
                }
                else {
                        #print $client->status_line;

			my $error = $client->status_line;
			if ($client->status_line =~ m/^500/i) {
				#print "Transmission connection refused\n";
				$content->{"error"} = $error;
				sleep 1;
				
				if ($count >= 4) {	
                                	$loop = 0;
                                	return $content;
				} else {
					$count++;
				}
			} elsif ($client->status_line =~ m/^409/i) {
                        	#print "Updating key\n";
                        	update_rpc_key();
			} else {
				$content->{"error"} = $error;
                                sleep 1;

                                if ($count >= 4) {
                                        $loop = 0;
                                        return $content;
                                } else {
                                        $count++;
                                }
			}
                }
        }
}

sub update_rpc_key {

        use LWP;
        use HTTP::Request;
        use DBI;
        use strict;

        my $uri = "http://localhost:9091/transmission/rpc";
        my $header_field = "X-Transmission-Session-Id";
        my $server = 'localhost:9091';

        my $ua = LWP::UserAgent->new();

	my %config = load_config();

	my $header_value = $config{'session_id'};

	$ua->credentials("$server",'Transmission',$config{remote_user},$config{remote_pass});

        my $response = $ua->post($uri, $header_field => $header_value, Content => qq!{"method":"session-stats"}!);

        if ($response->content =~ m/(\<code\>X\-Transmission\-Session\-Id\:\s)(.*)\<\/code\>/) {
                #print "New code is $2\n";
                $header_value = $2;

        	my $ds = get_datasource();
        	my $dbh = DBI->connect($ds) || die "DBI::errstr";

                my $query = $dbh->prepare("update config set value = '$header_value' where name = 'session_id'") || die "DBI::errstr";
                $query->execute();
        }
}
