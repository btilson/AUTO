#!/usr/local/sbin/perl-suid

use strict;
use warnings;
use CGI;
use BitTorrent;

1;
sub generate_header ($\%\@) {
	my $cgi = get_cgi();
	my %config = load_config();

        my $page = shift;
        my (%pages) = %{(shift)};
        my (@pages_short) = @{(shift)};

        my $header = "";

	my $logo = $config{app_logo_loc};
	$logo = "" unless defined ($logo);

        my $filter = $cgi->param("filter");

        $filter = "all" unless defined($filter);

	my @redirect_pages = ("start_submit","add_submit","pause_submit","honour_submit","remove_submit","change_view");

        my $tab = qq!<div class="STATUS"><a href="/auto/auto.pl?page=PAGE_SHORT">PAGE_NAME</a></div>!;
        my $tab_spacer = qq!<div class="divider">&nbsp;</div><div class="spacer">&nbsp;</div>!;

        my $header_start = qq^<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html
PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>$config{app_name} - Advanced User-friendly Torrent Operations and Media Manipulation</title>
<link rel="stylesheet" type="text/css" href="auto.css" title="default" />
<link rel="shortcut icon" href="images/favicon.ico" />
<link rel="icon" type="image/x-icon" href="images/favicon.ico" />
<script type="text/javascript" src="js/OnloadScheduler.js"></script>
<script type="text/javascript" src="js/CollapsibleLists.js"></script>
<script type="text/javascript">

OnloadScheduler.schedule(function(){ CollapsibleLists.apply(); });

</script>^;

my $header_middle = qq^</head>

<body onload=refresh_timer()>
<!--Header-->
<div id="header">
$logo
<h1>&nbsp;$config{app_name}</h1>

<div id="tabspacer">&nbsp;</div>
<div id="tabbar">^;

        my $header_end = qq!</div>
</div>

<a name="top"></a>
<div id="container">!;

        $header = $header_start."\n";

	if ($page ne "operate") {
		foreach my $reload_page (@redirect_pages) {
			if ($page eq $reload_page) {
				if ($page eq "add_submit") {
					$filter = "download"
				}
				$header .= qq!<meta http-equiv="refresh" content="10;url=/auto/auto.pl?page=operate&filter=$filter" />\n!;
			}
		}
	}

	$header .= $header_middle."\n";

        foreach my $key(@pages_short) {
                my $value = $pages{$key};
                my $line = $tab;
                $line =~ s/PAGE_SHORT/$key/;
                $line =~ s/PAGE_NAME/$value/;

                if ($page eq $key) {
                        $line =~ s/STATUS/active/;
                } else {
                        $line =~ s/STATUS/passive/;
                }

                $header .= $line."\n";
                $header .= $tab_spacer."\n";
        }

	if ($page eq "operate") {
		$header .= qq!<div id="filtertextbar">Filter: <input type="filter_text" id="filter_text" onChange="load_data()" />&nbsp;</div>!;
        }

	$header .= $header_end."\n";
        return $header;
}

sub generate_footer {

	my $footer = qq!<div id="footer">
<p>Copyright Auto Inc.</p>
</div>
</div>!;
	return $footer;
}

sub generate_endhtml {
	my $endhtml = qq!</body>
</html>!;
	return $endhtml;
}

sub get_torrent_list {
	my %config = load_config();
        
	my @torrent_list = `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -l 2>&1`;

	return @torrent_list;
}

sub get_torrent_info {
        my %config = load_config();
        my $id = shift;

	$id = clean_data($id);
        
	my @raw_info = `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id -i`;
	
	#my %torrent_info = parse_torrent_info(\@raw_info);

	return \@raw_info; 
}

sub parse_torrent_info {
	my @torrent_info = @{(shift)};
	
	my %parsed_torrent_info;

	foreach my $line (@torrent_info) {
		if ($line =~ m/Name\:(.*)$/) {
			$parsed_torrent_info{name} = $1;
		} elsif ($line =~ m/Total\ssize\:(.*\s\w\w\w?)\s\((.*\s\w\w\w?)\s.*/) {
			$parsed_torrent_info{total_size} = $1;
			$parsed_torrent_info{wanted_size} = $2;
		} elsif ($line =~ m/Have\:(.*\s\w\w\w?)\s\((.*\s\w\w\w?)\s.*/) {
			$parsed_torrent_info{have_size} = $1;
			$parsed_torrent_info{verified_size} = $2;
		} elsif ($line =~ m/State\:/) {
			$parsed_torrent_info{state} = $line;
		} elsif ($line =~ m/Peers\:/) {
			$parsed_torrent_info{peers} = $line;
		} elsif ($line =~ m/Honors Session Limits\:/) {
			$parsed_torrent_info{honours} = $line;
		}
	}		
        
	return %parsed_torrent_info;
}

sub get_torrent_files {
        my %config = load_config();
        my $id = shift;

	$id = clean_data($id);
 
        #my @torrent_files = `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id -f`;
	my $torrents = json_load_files($id);
	
        return $torrents;
}

sub parse_torrent_files {
	my %config = load_config();
	my $id = shift;
	my $torrents = shift;
	my $torrent_name = shift;
	chomp($torrent_name);
	$torrent_name =~ s/\s//g;
	my $current_folder;
	my $sample;
	my @dirs;
	my $content = "";

	my @torrents = @$torrents;

	#die "first file name is ".$torrents[0]->{"files"}->[0]->{"name"}."\n";	

	$content = "<h3>Torrent ID $id</h3>\n";
	
	my @torrent_files = @{$torrents[0]->{"files"}};	

	#die "Files array is @torrent_files\n";
	
	my $file_count = 0;

	#foreach my $files (@torrent_files) {
	#	my (%files) = %{$files};
	#	$content .= "File ID $file_count - ";
	#	$content .= qq!File name $files{"name"}<br />\n!;
		#$content .= "File Percentage $file_line[1]<br />\n";
	#	$file_count++;
	#}
	
	foreach my $files (@torrent_files) {
		my (%files) = %{$files};
		if ($files{"name"} =~ m/$torrent_name\/(.*\/)(.*)$/i && $files{"name"} !~ m/Sample/i) {
			push (@dirs, $1);
		}
	}
	my %seen = ();
	my @new_dirs = ();
  foreach my $value (@dirs) {
    unless ($seen{$value}) {
      push @new_dirs, $value;
     	$seen{$value} = 1;
    }
  }
	$content .= qq!<ul class="collapsibleList">\n<li>\n!;
	$content .= qq!<strong>$torrent_name</strong>\n<ul>\n!;
	
	foreach my $dirs (@new_dirs) {
		$content .= qq!<li>\n<strong>$dirs</strong>\n<ul>\n!;
		foreach my $files (@torrent_files) {
			my (%files) = %{$files};
			if ($files{"name"} =~ m/$dirs/i) {
				if ($files{"name"} =~ m/$torrent_name\/(.*\/)(.*)$/i && $files{"name"} !~ m/sample/ig) {
					my $directory = $1;
					my $filename = $2;
					$content .= "<li class=\"listitem\">" . $filename . "</li>\n";
				}
				elsif ($files{"name"} =~ m/$torrent_name\/(.*\/)(.*\/)(.*)$/ig) {
					my $directory = $2;
					my $filename = $3;
					$sample = qq!<li>\n<strong>$2</strong>\n<ul>\n!;
					$sample .= "<li class=\"listitem\">" . $filename . "</li>\n";
					$sample .= qq!</ul></li>\n!;
				}
		  }
		}
		if ($sample) {
			$content .= $sample;
		}
		$content .= qq!</ul>\n</li>\n!;
	}
	foreach my $files (@torrent_files) {
		my (%files) = %{$files};
		if ($files{"name"} !~ m/$torrent_name\/(.*\/)(.*)$/ig) {
			if ($files{"name"} =~ m/$torrent_name\/(.*)$/i) {
				$content .= "<li class=\"listitem\">$1</li>\n";
			}
		}
	}
	$content .= qq!</ul>\n!;
	
	$content .= qq!</ul>\n!;
	return $content;
}

sub get_running_hash {
        my %config = load_config();
        my $id = shift;

	$id = clean_data($id);
	
	my $torrent_hash = `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id -i | grep Hash`;
	
	$torrent_hash =~ s/\s+Hash\:\s//;	
	
	return $torrent_hash;
}

sub get_db_entry {
	use DBI;
	use BitTorrent;

	my $tor_hash = shift;
	chomp($tor_hash);
	
	my %config = load_config();
	my $torrent;
	my $download;
	my $hash;
	my $hashref;
	my %return;

	my $bt = BitTorrent->new();
        
	my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

  	my $query = $dbh->prepare("select * from running_torrents where hash = '$tor_hash'") || die "DBI::errstr";
	
	$query->execute;
	$query->bind_columns(\$torrent,\$download,\$hash);
	while ($query->fetch) {
		if ($torrent =~ m/$config{torrent_loc}/g) {
			$hashref = $bt->getTrackerInfo($torrent);
			# Compare passed hash (from transmission list) to one from DB 
			if ($tor_hash eq $hashref->{'hash'}) {
				$return{torrent} = $torrent;					
				return(%return);
			}
		}
		else {
			$return{torrent} = $torrent;					
			return(%return);
		}
	}
	$return{error} = "Torrent $tor_hash not found in DB\n";
	return(%return);
}

sub load_rss_shows {
	use DBI;

	my %rss_shows;
	my $name;
	my $include;
	my $exclude;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

        my $query = $dbh->prepare("select show,include,exclude from rss_shows") || die "DBI::errstr";
	$query->execute;
	$query->bind_columns(\$name,\$include,\$exclude);

	while ($query->fetch) {
		$rss_shows{"$name"}=$include."&".$exclude;
	}
	return %rss_shows;
}

sub load_rss_movies {
	use DBI;

	my %rss_movies;
	my $name;
	my $include;
	my $exclude;
	my $imdb_code;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

	my $query = $dbh->prepare("select movie,include,exclude,imdb_code from rss_movies") || die "DBI::errstr";
	$query->execute;
	$query->bind_columns(\$name,\$include,\$exclude,\$imdb_code);

	while ($query->fetch) {
		$rss_movies{"$name"}=$include."&".$exclude."&".$imdb_code;
	}
	return %rss_movies;
}

sub load_config {
	use DBI;

	my %config;
	my $option;
	my $value;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

        my $query = $dbh->prepare("select * from config") || die "DBI::errstr";
	$query->execute;
	$query->bind_columns(\$option,\$value);

	while ($query->fetch) {
		$config{"$option"}=$value;
	}
	return %config;
}

sub load_categories {
	use DBI;

	my %categories;
	my $category;
	my $location;
	my $sorting;
	
	my @array;

	my $ds = get_datasource();
	my $dbh = DBI->connect($ds) || die "DBI::errstr";

        my $query = $dbh->prepare("select * from categories") || die "DBI::errstr";
	$query->execute;
	$query->bind_columns(\$category,\$location,\$sorting);

	while ($query->fetch) {
		if ($sorting == 1) {
			$sorting = "on";
		} else {
			$sorting = "off";
		}

		$categories{"$category"} = "$location,$sorting";
	}
	return %categories;
}

sub get_datasource {
	my $db_location = "/var/www/html/auto/auto.db";
	my $ds = "DBI:SQLite:dbname=$db_location";
	
	return $ds;
}

sub generate_download_path {
	my $type = shift;
	my $show_name = shift;
	my $season_no = shift;
	my $download_path;

	my %categories = load_categories();

	my @category_info = split(/,/,$categories{$type});

        my $main_directory = $category_info[0];
        my $sorting = $category_info[1];

	if ($sorting eq "on") {
        	#Ensure the season is two digits, add leading 0 if needed
        	$season_no = sprintf("%02d", $season_no);

        	#Generate the path from all the questions
        	$download_path = $main_directory."/";
       		$download_path .= $show_name."/";
        	$download_path .= "Season_".$season_no;
	} else {
        	$download_path = $main_directory;
	}
	
	# Remove the strange whitespace at the start of the download location 
	# (no idea where it comes from...)
	# NOTE - May be rectified, need to test (hence commented out)
	#$download_path =~ s/^\s+//;

	return $download_path;
}

sub generate_torrent_path {
	my $torrent = shift;
	my %return;

	my %config = load_config();

	$torrent = clean_data($torrent);
	
	my $torrent_path;
	my $torrent_prefix = $config{torrent_loc};
	$torrent_prefix .= "/";
	my $torrent_folder = `date +%b%y`;

	$torrent_folder = clean_data($torrent_folder);

	if ( !$torrent )
	{
       		$return{error} = "There was a problem loading the torrent, please try again";
       		return %return;	
	}

	if ($torrent =~ m/\'/g) {
        	$return{error} = "Torrent file contains \' marks, please rename it to remove them\n";
		return %return;
	}
	
	#perform necessary cleanup and modification of date output
	chomp($torrent_folder);
	$torrent_folder =~ s/s+//g;
	$torrent_folder .= "/";

	#combined variable for -e below
	my $combined_old_location = $torrent_prefix.$torrent;

	#combined variable for rename etc
	my $combined_new_location = $torrent_prefix.$torrent_folder.$torrent;

	#Check that the torrent submitted exists where it should
	if (-e "$combined_old_location") {
	        #Found torrent where it should be, continue on
	} else {
       		my $error = "<h1>Torrent file not found in torrent directory</h1>\n";
        	$error .= "<h2>check that the torrent is in the torrents folder where it should be...</h2>\n";
        	$error .= "<p>Location checked was ".$combined_old_location."\n";
		$return{error} = $error;
		return %return;
	}
	
	# Create the dated directory if it does not exist
	mkdir "$torrent_prefix$torrent_folder", 0777 unless -d "$torrent_prefix$torrent_folder";
	directory_check("$torrent_prefix.$torrent_folder");	

	# Move the torrent file into the dated folder and generate
	if (!rename("$combined_old_location","$combined_new_location")) {
		my $error = "<h1>Failed to move torrent file as needed</h1>\n";
		$error .= "<h2>Attempted to move $combined_old_location<br />";
		$error .= "To $combined_new_location</h2>\n";
		$error .= "<p>Server reports the following error<br />\n";
		$error .= "$! </p>\n";
		$return{error} = $error;
		return %return;
	}

	# Add the prefix to the path
	$torrent_path = $torrent_prefix.$torrent_folder.$torrent;

	# Remove the strange whitespace at the start of the torrent location 
	# (no idea where it comes from...)
	# NOTE - May be rectified, need to test (hence commented out)
	#$torrent_path =~ s/^\s+//;
	
	$return{torrent_path} = $torrent_path;
	return %return;
}

sub process_rss {
	
	my $rss = shift;
	my $verbose = shift;
	
	my $return = "";
	my $wget_output = "";

	my %config = load_config();
	my %shows = load_rss_shows();
	 
        for my $search_value ( keys %shows ) {
                my @include_exclude = split(/&/,$shows{$search_value});
                my $include_value = $include_exclude[0];
                my $exclude_value = $include_exclude[1];
	
		# Line to disable all actual processing of RSS by using non-existant show name
                #$search_value = "BIG_SHOW_NAME_THAT_DOESNT_EXIST";
                
		# Line to print all RSS show names to be checked	
		#print "Searching for matching shows for $search_value\n";
		
		#Force an unlikely combination for the exclude if none provided.
		$exclude_value = "ABCDEF" unless defined $exclude_value;

		#Force a blank value for the include if none provided.
		$include_value = "" unless defined $include_value;

		my $show_name = $search_value;

		# Change whitespace in show name to be generic regex match anything characters
		$search_value =~ s/\s/\./g;
        
		foreach my $item (@{$rss->{'items'}}) {
       	         	next unless defined($item->{'title'}) && defined($item->{'link'});
       	         	next unless ($item->{'title'} =~ m/$search_value/i);
			
			my $exclude = 0;

			my @includes = split(/,/,$include_value);
	
			foreach my $include_item (@includes) {
                		if ($item->{'title'} !~ m/$include_item/i) {
					$exclude = 1;
				}
			}
			
			my @excludes = split(/,/,$exclude_value);
			
			foreach my $exclude_item (@excludes) {
                		if ($item->{'title'} =~ m/$exclude_item/i) {
					$exclude = 1;
				}
			}
			
                	next if ($exclude == 1);

                	$return .= "$item->{'title'}\n" unless $verbose == 0;
                	#print "$item->{'link'}\n";
                	my $torrent_location = $config{torrent_loc}."/auto/".$item->{'title'}.".torrent";
                	#print "$torrent_location\n";
                	if (-e "$torrent_location") {
				$return .= "Torrent has already been downloaded\n" unless $verbose == 0;
                	}
                	else {
                		if ($item->{'link'} =~ m/mininova/) {
               	                	$item->{'link'} =~ s/\/tor\//\/get\//;
                        	}
                        	$wget_output = `wget -t 3 -o /dev/stdout "$item->{'link'}" -O "$torrent_location"`;

				if ($wget_output =~ m/ERROR/) {
					$return .= "Torrent file failed to download, skipping\n";
					unlink($torrent_location);
					next;
				} else {
					$return .= "Torrent file $item->{'title'}.torrent downloaded\n";
				}
                	}
                	$return .= add_rss_download($torrent_location,$search_value,$show_name,$verbose);
        	}
	}

	return $return;
}

sub process_movie_rss {
	
	my $rss = shift;
	my $verbose = shift;
	
	my $return = "";
	my $wget_output = "";

	my %config = load_config();
	my %movies = load_rss_movies();
	 
        for my $search_value ( keys %movies ) {
                my @include_exclude = split(/&/,$movies{$search_value});
                my $include_value = $include_exclude[0];
                my $exclude_value = $include_exclude[1];
	
		# Line to disable all actual processing of RSS by using non-existant movie name
                #$search_value = "BIG_MOVIE_NAME_THAT_DOESNT_EXIST";
                
		# Line to print all RSS movie names to be checked	
		#$return .= "Searching for matching movies for $search_value\n";
		my $movie = $search_value;
		chomp($movie);
		
		#Force an unlikely combination for the exclude if none provided.
		$exclude_value = "ABCDEF" unless defined $exclude_value;

		#Force a blank value for the include if none provided.
		$include_value = "" unless defined $include_value;

		# Change whitespace in movie name to be generic regex match anything characters
		$search_value =~ s/\s/\./g;
		
		foreach my $item (@{$rss->{'items'}}) {
			$item->{'title'} =~ s/\'//g;
       	         	next unless defined($item->{'title'}) && defined($item->{'link'});
       	         	next unless ($item->{'title'} =~ m/$search_value/i);
			
			my $exclude = 0;

			my @includes = split(/,/,$include_value);
	
			foreach my $include_item (@includes) {
                		if ($item->{'title'} !~ m/$include_item/i) {
					$exclude = 1;
				}
			}
			
			my @excludes = split(/,/,$exclude_value);
			
			foreach my $exclude_item (@excludes) {
                		if ($item->{'title'} =~ m/$exclude_item/i) {
					$exclude = 1;
				}
			}

                	next if ($exclude == 1);

                	$return .= "$item->{'title'}\n" unless $verbose == 0;
                	#print "$item->{'link'}\n";
                	my $torrent_location = $config{torrent_loc}."/auto/".$item->{'title'}.".torrent";
                	#print "$torrent_location\n";
                	if (-e "$torrent_location") {
				$return .= "Torrent has already been downloaded\n" unless $verbose == 0;
                	}
			else {
				my $sendmail = "/usr/sbin/sendmail -f movie_match -t";
				my $subject = "Subject: Movie match found for - " . $movie . "\n";
  
				my $send_to = "To: $config{email_addr}\n";
	 
	 			open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
	 			#print SENDMAIL $reply_to;
	 			print SENDMAIL $subject;
	 			print SENDMAIL $send_to;
	 			print SENDMAIL "Content-type: text/html\n\n";
	 			print SENDMAIL "<html>";
	 			print SENDMAIL "<p>Hi User,<br />";
	 			print SENDMAIL "The following movie has been released matching your watch list:<br />";
	 			print SENDMAIL "<br />";
				print SENDMAIL "<strong>Watch list entry:</strong> " . $movie . "<br />";
	 			print SENDMAIL "<strong>Released movie:</strong> " . $item->{'title'} . "<br />";
				print SENDMAIL "<br />";
	 			print SENDMAIL "If this is correct please find the torrent at the following link:<br />";
				print SENDMAIL "<a href=\"" . $item->{'link'} . "\">" . $item->{'link'} . "</a><br />";
				print SENDMAIL "<br />";
				print SENDMAIL "The matched entry has been removed from the watch list<br />";
	 			print SENDMAIL "<br />";
	 			print SENDMAIL "Enjoy the rest of your day!!</p>";
	 			print SENDMAIL "</html>";
	 			close(SENDMAIL);
				$return .= db_delete_rss_movie_entry($movie);
			}
        	}
	}
	return $return;
}

sub add_rss_download {
        my $torrent_location = shift;
        my $search_value = shift;
        my $rss_show_name = shift;
        my $verbose = shift;
        my $show_name;
        my $season_no;
        my $episode;
        my $torrent_path;
        my $torrent_file;
        my $query;
	my $hash;
        
	my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";
        
	my $status = 0;
        my $ok_to_dl = 0;
	my $proper = 0;

	my $return = "";

	my %config = load_config();

        my $download_path = $config{rss_down_loc};
        
	if ($torrent_location =~ m/($config{torrent_loc}\/auto\/)(.*)/g) {
                $torrent_path = $1;
                $torrent_file = $2;
        }
	
        if ($torrent_file =~ m/(.*)\s(\-|\_).*\s(\d?\d)x(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $3;
                $episode = $4;

        } elsif ($torrent_file =~ m/(.*)\s(\d?\d)x(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $2;
                $episode = $3;

        } elsif ($torrent_file =~ m/(.*)\sS(\d?\d)E(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $2;
                $episode = $3;

        } elsif ($torrent_file =~ m/(.*)\s(\-|\_).*(\d?\d)\sx\s(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $3;
                $episode = $4;
        
	} elsif ($torrent_file =~ m/(.*)\s(\d?\d)\sx\s(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $2;
                $episode = $3;

        } elsif ($torrent_file =~ m/(.*)\.S(\d?\d)E(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $2;
                $episode = $3;

	} 

	# Begin new cleaned up entries without Show name

	# Search seasons
	if ($torrent_file =~ m/Series.(\d?\d)/i) {
		$season_no = $1;
	} elsif ($torrent_file =~ m/(\d?\d)x(\d?\d)/gi) {
		$season_no = $1;
	}
	
	# Then find episode number
	if ($torrent_file =~ m/(\d?\d)of(\d?\d)/gi) {	
               	$episode = $1;
	} elsif ($torrent_file =~ m/(\d?\d)x(\d?\d)/gi) {
		$episode = $2;
	}

	#$show_name = $search_value;
	$show_name = $rss_show_name;
		
	#print "Show name is |$show_name|\n";
        #print "Season is |$season_no|\n";
        #print "Episode is |$episode|\n";
        
	# Swap out dots in name for whitespace (to be swapped out later for underscores)
	# Commented out - Should not be needed any more with show names coming from RSS directly
        #$show_name =~ s/\./ /g;
	
	# Swap out regex start and end characters for the name
        $show_name =~ s/^\^//g;
        $show_name =~ s/\$$//g;
	
	$show_name = "" unless defined $show_name;
	$season_no = "unknown" unless defined $season_no;
	$episode = "unknown" unless defined $episode;

        if ($show_name eq "") {
                $return = "Failed to get show name correctly\n";
                return $return;
        }

        if ($season_no eq "unkown" || $episode eq "unknown") {
                $return = "Failed to get show $torrent_file season/episode correctly\n";
                return $return;
        }

        #Perform manipulation on necessary things
        #lower case the whole string
        $show_name =~ tr/[a-z]/[A-Z]/;

        #Capitalise first letter of every word
        $show_name =~ s/(?<=\w)(.)/\l$1/g;

        #Swap whitespace for underscores
        $show_name =~ s/\s/\_/g;

	if ($season_no ne "unknown") {
        	#Ensure the season is two digits, add leading 0 if needed
        	$season_no = sprintf("%02d", $season_no);
	} 

	if ($episode ne "unknown") {
        	#Ensure the episode is two digits, add leading 0 if needed
        	$episode = sprintf("%02d", $episode);
	} 

        # Uncomment for testing show regex parsing
	#print "Show name is |$show_name|\n";
        #print "Season is |$season_no|\n";
        #print "Episode is |$episode|\n";
 
	if ($config{rss_sorting} eq "on") { 
        	$download_path = $download_path."/".$show_name."/";
        	$status = directory_check($download_path);

        	$download_path = $download_path."Season_".$season_no."/";
        	$status = directory_check($download_path);
	}

        # Uncomment for testing show regex parsing
        #print "Final download path is |$download_path|\n";
        #print "Final torrent location is |$torrent_location|\n";

        #check if this is a PROPER or REAL release and if so, ignore rules and force re-download
        #currently will cause a stopped download of a proper to continue to add itself over
        #and over again until its revolved out of the RSS. Will write a "proper check" soon to
        #Check if the file / download present is the proper.

        if ($torrent_file =~ m/PROPER/ || $torrent_file =~ m/REAL/ || $torrent_file =~ m/REPACK/) {
               
		$proper = 1;
		my $dl_check = 0;
	
		$dl_check = downloading_check($show_name,$season_no,$episode,$proper);
		
		if ($dl_check == 1) {
                	$return .= "PROPER / REAL / REPACK Episode is already being downloaded\n" unless $verbose == 0;
                } else {
                	$ok_to_dl = 1;
		}
        }
		
	# Check if an op_lock exists BEFORE doing file check / downloading check - Ensures anything else 
	# that is currently being added will be picked up and not duplicated
	
	my $lock_check = op_lock_check();

	my $lock_count = 0;
	
	while ($lock_check == 1) {
		$lock_check = op_lock_check();
		$return .= "operation lock exists, waiting\n";
		sleep 5;

		$lock_count++;

		if ($lock_count >= 60) {
			#Maybe email here?
			#die "AUTO lock count exceeded\n";
			$return .= "operation lock stuck, overriding and stopping stuck processes\n";
			op_lock_remove();
			`pkill perl`;
  			$lock_check = op_lock_check();
		}

		sleep 5;
	}
	
	op_lock_set();

        if ($proper == 0) {
                my $file_check = file_check($download_path,$search_value,$season_no,$episode);
		my $dl_check = 0;

                if ($file_check == 1) {
                        $return .= "Episode has already been downloaded\n" unless $verbose == 0;
                } else {
                	$dl_check = downloading_check($show_name,$season_no,$episode,$proper);
			
			if ($dl_check == 1) {
                       		$return .= "Episode is already being downloaded\n" unless $verbose == 0;
                	} else {
	        		my $query = $dbh->prepare("select * from running_torrents where torrent_location = '$torrent_location'") || die "DBI::errstr";
				my $torrent;
				my $download;
				my $hash;

				$query->execute;
				$query->bind_columns(\$torrent,\$download,\$hash);
				$query->fetch;

				#set the db loaded torrent to an impossible to match value if nothing is found
				$torrent = "NOTATORRENT" unless defined $torrent;
			
				if ($torrent eq $torrent_location) {       
					$return .= "Torrent $torrent already in running torrent database, wont start again\n";
				} else {  
					$ok_to_dl = 1;
				}
                	}
        	}
	}

        
	if ($ok_to_dl == 1) {
                $return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -w "$download_path"`;
                $return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -a "$torrent_location"`;
	
		if ($torrent_path =~ m/^magnet:.*urn:btih:(\w*)&dn/i) {
			#Get the hash from the magnet link
			$hash = $1;
 		} else {	
			# Get the hash from the bittorrent file for insertion into DB
			my $bt = BitTorrent->new();
			my $hashref = $bt->getTrackerInfo($torrent_location);	
			$hash = $hashref->{'hash'};
		}

		if ($return !~ m/invalid/i && $return !~ m/fail/i) {
			$query = $dbh->prepare("INSERT INTO running_torrents values ('$torrent_location','$download_path','$hash')") || die "DBI::errstr";
               		$query->execute();
		} else {
			$return .= "$torrent_location failed to add properly\n";
			unlink($torrent_location);
		}
        }
		
	op_lock_remove();

	return $return;
}

sub stop_ratio {

	my $verbose = shift;

	my %shows = load_rss_shows();
        my @torrent_list = get_torrent_list();
	 
	my %config = load_config();

	my $show_check = "";
	my @show;

	my $return = "Shows ready to be stopped\n";

	foreach my $line (@torrent_list) {
        	if ($line =~ m/.*\s100\%\s.*/) {
			my @fields = split (" ",$line);
                	my $id = $fields[0];
                	my $ratio = $fields[7];
                	my $show_name = "";

                	my $array_positions = scalar(@fields);

                	for (my $i=9; $i < $array_positions; $i++) {
                      		$show_name = $show_name." ".$fields[$i];
                	}

                	$show_name =~ s/^\s+//;

                	if ($ratio !~ m/\d+/) {
                       		next;
                	}

                	if ($ratio <= $config{rss_ratio} || $line =~ m/Stopped/) {
                        	next;
                	}

			for my $show_check ( keys %shows ) {

                        	$show_check =~ s/\s/\.\?/g;

                        	#print "torrent is $show_name, show check is $show_check, ratio is $ratio\n";

              			if ($show_name =~ m/$show_check/i) {
                                	$return .= "Found matching torrent for $show_check with required ratio\n";
                                	#system ("$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t$id -S");
					json_pause_torrent($id,"true");
                        	}
                	}
        	}
	}
	
	if ($return eq "Shows ready to be stopped\n") {
		if ($verbose == 0) {
			$return = "";
		} else {
			$return = "No shows ready to be stopped yet\n";
		}
	}

	return $return;
}	

sub add_torrent {
	use DBI;
	use BitTorrent;

	my $download_path = shift;
	my $torrent_path = shift;
	my $timing = shift;
	$download_path = clean_data($download_path);

	my %config = load_config();

	 my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

	my $hash;

	if ($torrent_path =~ m/^magnet:.*urn:btih:(\w*)&dn/i) {
		#Get the hash from the magnet link
		$hash = $1;
 	} else {	
		# Get the hash from the bittorrent file for insertion into DB
		my $bt = BitTorrent->new();
		my $hashref = $bt->getTrackerInfo($torrent_path);	
		$hash = $hashref->{'hash'};
	}

	my %return;
	

	if ($timing eq "on" ) {
        	$return{info} = "On-Peak download selected<br />\n";
     		my $query = $dbh->prepare("INSERT INTO on_peak_queue values ('$torrent_path','$download_path')") || die "DBI::errstr";
        	$query->execute();
	}
	elsif ($timing eq "off" ) {
        	$return{info} = "Off-Peak download selected<br />\n";
        	my $query = $dbh->prepare("INSERT INTO off_peak_queue values ('$torrent_path','$download_path')") || die "DBI::errstr";
        	$query->execute();
	}
	elsif ($timing eq "now" ) {
        	$torrent_path =~ s/^s+//;
        	$download_path =~ s/^s+//;
        	#$return{info} = "Immediate download selected<br />\n";
        	my $query = $dbh->prepare("INSERT INTO running_torrents values ('$torrent_path','$download_path','$hash')") || die "DBI::errstr";
        	$query->execute();
        	
		my $lock_check = op_lock_check();

		my $lock_count = 0;

		while ($lock_check == 1) {
			$lock_check = op_lock_check();
			$return{info}.= "operation lock exists, waiting\n";

			$lock_count++;
			sleep 5;

                	if ($lock_count >= 30) {
                        	#Maybe email here?
				#die "AUTO lock count exceeded\n";
				$return{info} .= "operation lock stuck, overriding and stopping stuck processes\n";
				op_lock_remove();
				`pkill perl`;
  				$lock_check = op_lock_check();
                	}
		}

		op_lock_set();

		`$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -w "$download_path"`;
        	my $torrent_add_return = `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -a "$torrent_path"`;
	
		if ($torrent_add_return =~ m/Success/i) {
			$return{info} .= "Successfully Added!\n";
		} else {
			$torrent_add_return =~ s/.*://g;	
			$torrent_add_return =~ s/"//g;	
        		
			#Capitalise first letter of every word
        		#$torrent_add_return =~ s/(?<=\w)(.)/\l$1/g;
			
			$return{info} .= $torrent_add_return;
		}

        	$return{info} .= "<br />\n";
		
		op_lock_remove();
	}
	
	return %return;
}

sub remove_torrent {

	my $id = shift;
	my %config = load_config();
	my $return = "";

	$id = clean_data($id);

	if ($config{remove_data} eq "off") {
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id -r`;
	}
	elsif ($config{remove_data} eq "on") {
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id --remove-and-delete`;
	}
	if ($return =~ m/"success"/) {
		return "Removed torrent $id from Transmission\n";
	} else {
		return $return;	
	}
}

sub honour_torrent {

	my $id = shift;
	my $honour = shift;
	my %config = load_config();
	my $return = "";

	$id = clean_data($id);
	
	if ($honour eq "false") {
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id -HL`;
	} else {
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id -hl`;
	}
	
	if ($return =~ m/success/) {
		$return = "Torrent ";
		if ($honour eq "false") {
			$return .= "has been set to ignore session speed limits<br />\n";
		} else {
			$return .= "has been set to honour session speed limits<br />\n";
		}
	}

	return $return;	
}

sub change_views {
	use DBI;

	my $view = shift;
        my %return;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

	my $query = $dbh->prepare("update config SET value = '$view' where name = 'view_mode'") || die "DBI::errstr";
        $query->execute();
	
	$return{info} = "View mode changed to $view";
	
	return %return;
}
		
sub db_set_options {
	use DBI;

        my %return;

	my $off_peak_start = shift;
        my $off_peak_up = shift;
        my $off_peak_down = shift;
        my $on_peak_start = shift;
        my $on_peak_up = shift;
        my $on_peak_down = shift;
        my $daemon_loc = shift;
        my $remote_loc = shift;
				my $remote_user = shift;
				my $remote_pass = shift;
        my $torrent_loc = shift;
        my $rss_loc = shift;
				my $movie_rss_loc = shift;
				my $my_eps_rss  = shift;
				my $email_addr = shift;
        my $rss_state = shift;
				my $rss_sorting = shift;
				my $rss_ratio = shift;
				my $rss_time = shift;
        my $rss_down_loc = shift;
        my $transmission_port = shift;
				my $remove_data = shift;
				my $last_active = shift;
				my $seed_time = shift;

	#Remove all whitespace at the start of text
       	$off_peak_start =~ s/^\s+//;
       	$off_peak_up =~ s/^\s+//;
       	$off_peak_down =~ s/^\s+//;
       	$on_peak_start =~ s/^\s+//;
       	$on_peak_up =~ s/^\s+//;
       	$on_peak_down =~ s/^\s+//;
       	$daemon_loc =~ s/^\s+//;
       	$remote_loc =~ s/^\s+//;
				$remote_user =~ s/^\s+//;
				$remote_pass =~ s/^\s+//;
       	$torrent_loc =~ s/^\s+//;
       	$rss_loc =~ s/^\s+//;
				$movie_rss_loc =~ s/^\s+//;
				$my_eps_rss  =~ s/^\s+//;
				$email_addr =~ s/^\s+//;
       	$rss_state =~ s/^\s+//;
				$rss_sorting =~ s/^\s+//;
				$rss_ratio =~ s/^\s+//;
				$rss_time =~ s/^\s+//;
       	$rss_down_loc =~ s/^\s+//;
       	$transmission_port =~ s/^\s+//;
				$remove_data =~ s/^\s+//;
				$last_active =~ s/^\s+//;
				$seed_time =~ s/^\s+//;
	
	#Remove all whitespace at the end of text
       	$off_peak_start =~ s/\s+$//;
       	$off_peak_up =~ s/\s+$//;
       	$off_peak_down =~ s/\s+$//;
       	$on_peak_start =~ s/\s+$//;
       	$on_peak_up =~ s/\s+$//;
       	$on_peak_down =~ s/\s+$//;
       	$daemon_loc =~ s/\s+$//;
       	$remote_loc =~ s/\s+$//;
				$remote_user =~ s/\s+$//;
				$remote_pass =~ s/\s+$//;
       	$torrent_loc =~ s/\s+$//;
       	$rss_loc =~ s/\s+$//;
				$movie_rss_loc =~ s/\s+$//;
				$email_addr =~ s/\s+$//;
				$my_eps_rss  =~ s/\s+$//;
       	$rss_state =~ s/\s+$//;
				$rss_sorting =~ s/\s+$//;
				$rss_ratio =~ s/\s+$//;
				$rss_time =~ s/\s+$//;
       	$rss_down_loc =~ s/\s+$//;
       	$transmission_port =~ s/\s+$//;
				$remove_data =~ s/\s+$//;
				$last_active =~ s/\s+$//;
				$seed_time =~ s/\s+$//;


        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

	my $query = $dbh->prepare("update config SET value = '$off_peak_start' where name = 'off_peak_start'") || die "DBI::errstr";
        $query->execute();
       	
	$query = $dbh->prepare("update config SET value = '$off_peak_up' where name = 'off_peak_up_speed_kb'") || die "DBI::errstr";
        $query->execute();
       	
	$query = $dbh->prepare("update config SET value = '$off_peak_down' where name = 'off_peak_down_speed_kb'") || die "DBI::errstr";
        $query->execute();

	$query = $dbh->prepare("update config SET value = '$on_peak_start' where name = 'on_peak_start'") || die "DBI::errstr";
        $query->execute();
       	
	$query = $dbh->prepare("update config SET value = '$on_peak_up' where name = 'on_peak_up_speed_kb'") || die "DBI::errstr";
        $query->execute();
       	
	$query = $dbh->prepare("update config SET value = '$on_peak_down' where name = 'on_peak_down_speed_kb'") || die "DBI::errstr";
        $query->execute();

       	$query = $dbh->prepare("update config SET value = '$daemon_loc' where name = 'daemon_loc'") || die "DBI::errstr";
        $query->execute();
       	
	$query = $dbh->prepare("update config SET value = '$remote_loc' where name = 'remote_loc'") || die "DBI::errstr";
        $query->execute();

	$query = $dbh->prepare("update config SET value = '$remote_user' where name = 'remote_user'") || die "DBI::errstr";
        $query->execute();
				
	$query = $dbh->prepare("update config SET value = '$remote_pass' where name = 'remote_pass'") || die "DBI::errstr";
        $query->execute();

	$query = $dbh->prepare("update config SET value = '$torrent_loc' where name = 'torrent_loc'") || die "DBI::errstr";
        $query->execute();

       	$query = $dbh->prepare("update config SET value = '$rss_loc' where name = 'rss_loc'") || die "DBI::errstr";
        $query->execute();
				
				$query = $dbh->prepare("update config SET value = '$movie_rss_loc' where name = 'movie_rss_loc'") || die "DBI::errstr";
        $query->execute();
				
				$query = $dbh->prepare("update config SET value = '$my_eps_rss' where name = 'my_eps_rss'") || die "DBI::errstr";
        $query->execute();
				
				$query = $dbh->prepare("update config SET value = '$email_addr' where name = 'email_addr'") || die "DBI::errstr";
        $query->execute();
       	
	$query = $dbh->prepare("update config SET value = '$rss_state' where name = 'rss_state'") || die "DBI::errstr";
        $query->execute();
       	
	$query = $dbh->prepare("update config SET value = '$rss_sorting' where name = 'rss_sorting'") || die "DBI::errstr";
        $query->execute();
				
	$query = $dbh->prepare("update config SET value = '$rss_ratio' where name = 'rss_ratio'") || die "DBI::errstr";
        $query->execute();
				
	$query = $dbh->prepare("update config SET value = '$rss_time' where name = 'rss_time'") || die "DBI::errstr";
        $query->execute();
       	
	$query = $dbh->prepare("update config SET value = '$rss_down_loc' where name = 'rss_down_loc'") || die "DBI::errstr";
        $query->execute();

	$query = $dbh->prepare("update config SET value = '$transmission_port' where name = 'transmission_port'") || die "DBI::errstr";
        $query->execute();
	
	$query = $dbh->prepare("update config SET value = '$remove_data' where name = 'remove_data'") || die "DBI::errstr";
        $query->execute();
				
	$query = $dbh->prepare("update config SET value = '$last_active' where name = 'last_active'") || die "DBI::errstr";
        $query->execute();
				
	$query = $dbh->prepare("update config SET value = '$seed_time' where name = 'seed_time'") || die "DBI::errstr";
        $query->execute();

	$return{info} = "Updated Options";
	
	return %return;
}

sub db_delete_running_entry {
	use DBI;
	
	my $torrent_path = shift;
        
	my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

       	my $query = $dbh->prepare("DELETE FROM running_torrents WHERE torrent_location = '$torrent_path'") || die "DBI::errstr";
        $query->execute();
	
	return "Deleted $torrent_path from database";
}

sub db_add_rss_show {
	use DBI;

	my $show = shift;
	my $inclusions = shift;
	my $exclusions = shift;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";
	
	my %return;

	#Remove all whitespace at the start of text
       	$show =~ s/^\s+//;
       	$inclusions =~ s/^\s+//;
       	$exclusions =~ s/^\s+//;
	
	#Remove all whitespace at the end of text
       	$show =~ s/\s+$//;
       	$inclusions =~ s/\s+$//;
       	$exclusions =~ s/\s+$//;
       	
	#set all letters to lower case	
	$show =~ tr/[a-z]/[A-Z]/;

        #Capitalise first letter of every word
        $show =~ s/(?<=\w)(.)/\l$1/g;
   
	# Prepare string as an insert 
	my $query_string = "INSERT INTO rss_shows values ('$show','$exclusions','$inclusions')";
       	
	# Pull any show that matches the current one
	my $query = $dbh->prepare("Select show from rss_shows where show = '$show'") || die "DBI::errstr";
       	$query->execute();

	my $pulled_show;
	
	$query->bind_columns(\$pulled_show);

	# Run the query and check for a match for show names (double check)
	while ($query->fetch) {
		if ($show eq $pulled_show) {
			# If a match is found, make an update instead of an insert
			$query_string = "update rss_shows set include = '$inclusions',exclude = '$exclusions' where show = '$show'";
		}
	}

	$query = $dbh->prepare($query_string) || die "DBI::errstr";
       	$query->execute();

	if ($query_string =~ m/update rss_shows/) {
		$return{info} = "Updated $show in the RSS show database";
	} else {
		$return{info} = "Added $show in the RSS show database";
	}

	return %return;
}

sub db_delete_rss_entry {
	use DBI;
	
	my $show = shift;
        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

       	my $query = $dbh->prepare("DELETE FROM rss_shows WHERE show = '$show'") || die "DBI::errstr";
        $query->execute();
	
	return "Deleted $show from RSS Database";
}

sub db_add_rss_movie {
	use DBI;
	use IMDB::Film;

	my $movie = shift;
	my $inclusions = shift;
	my $exclusions = shift;
	my $year;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

	my %return;

	#Remove all whitespace at the start of text
       	$movie =~ s/^\s+//;
       	$inclusions =~ s/^\s+//;
       	$exclusions =~ s/^\s+//;
	
	#Remove all whitespace at the end of text
       	$movie =~ s/\s+$//;
       	$inclusions =~ s/\s+$//;
       	$exclusions =~ s/\s+$//;
       	
	#set all letters to lower case	
	$movie =~ tr/[a-z]/[A-Z]/;

  #Capitalise first letter of every word
  $movie =~ s/(?<=\w)(.)/\l$1/g;
	
	if ($inclusions =~ m/^(\d{4}),.*$/){
		$year = $1;
	}
	my $film = new IMDB::Film(crit => $movie, year => $year);
	my $imdb_code = "tt" . $film->code;
	
	# Prepare string as an insert 
	my $query_string = "INSERT INTO rss_movies values ('$movie','$exclusions','$inclusions','$imdb_code')";
       	
	# Pull any movie that matches the current one
	my $query = $dbh->prepare("Select movie from rss_movies where movie = '$movie'") || die "DBI::errstr";
       	$query->execute();

	my $pulled_movie;
	
	$query->bind_columns(\$pulled_movie);

	# Run the query and check for a match for movie names (double check)
	while ($query->fetch) {
		if ($movie eq $pulled_movie) {
			# If a match is found, make an update instead of an insert
			$query_string = "update rss_movies set imdb_code = '$imdb_code',include = '$inclusions',exclude = '$exclusions' where movie = '$movie'";
		}
	}

	$query = $dbh->prepare($query_string) || die "DBI::errstr";
       	$query->execute();

	if ($query_string =~ m/update rss_movies/) {
		$return{info} = "Updated $movie in the RSS movie database";
	} else {
		$return{info} = "Added $movie in the RSS movie database";
	}

	return %return;
}

sub db_delete_rss_movie_entry {
	use DBI;
	
	my $movie = shift;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

       	my $query = $dbh->prepare("DELETE FROM rss_movies WHERE movie = '$movie'") || die "DBI::errstr";
        $query->execute();
	
	return "Deleted $movie from RSS Database\n";
}

sub db_add_category {
	use DBI;

	my $category = shift;
	my $location = shift;
	my $sorting = shift;

	$sorting = "off" unless defined $sorting;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";
	
	my %return;

	#Remove all whitespace at the start of text
       	$category =~ s/^\s+//;
       	$location =~ s/^\s+//;
       	$sorting =~ s/^\s+//;
	
	#Remove all whitespace at the end of text
       	$category=~ s/\s+$//;
       	$location =~ s/\s+$//;
       	$sorting =~ s/\s+$//;
       	
	if ($sorting eq "on") {
		$sorting = 1;
	} else {
		$sorting = 0;
	}
       	
       	my $query = $dbh->prepare("INSERT INTO categories values ('$category','$location','$sorting')") || die "DBI::errstr";
       	$query->execute();

	$return{info} = "Added $category into the Categories database";

	return %return;
}

sub db_delete_category {
	use DBI;
	
	my $category = shift;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

       	my $query = $dbh->prepare("DELETE FROM categories WHERE category = '$category'") || die "DBI::errstr";
        $query->execute();
	
	return "Deleted $category from Categories database";
}

sub db_manual_edit {
	my $table = shift;

	my $content;

	# No table submitted, present list of available tables to edit
	if ($table eq "none") {
	
		my @tables;
		my @psql_out = `psql -d transmission -c \"\\d\"`;
	
		foreach my $line (@psql_out) {
			if ($line =~ m/public |(.*)|.*|.*/) {
				# Pull table name from line
				my $table_name = $1;
	
				#Remove whitespace at the start and end
				$table_name =~ s/^\s*//;
				$table_name =~ s/\s*$//;
	
				#Place in tables array
				push(@tables,$table_name);
			}
		}

		$content = "<h3>Available tables to manual edit are</h3>\n";

		foreach my $line (@tables) {	
			$content .= "<a href=/auto/auto.pl?page=dbmaint&amp;table=$line>$line</a>";
		}
	} else {
		# Proper table name has been received - present table contents for editing
		# SUB needed, should be used for categories and RSS generation as well maybe
	}
}

sub file_check {
        my $path = shift;
	my $show = shift;
        my $season_no = shift;
        my $episode_no = shift;
        my $check = 0;
        my @file_check = "nothing";

	$show =~ s/\s/\?/g;
	$show =~ s/\./\?/g;

        # Swap out regex start and end characters for the name
        $show =~ s/^\^//g;
        $show =~ s/\$$//g;

	## override the core glob forcing case insensitivity
	use File::Glob qw(:globally :nocase);
	my @sources = <*.{c,h,y}>;

        # Set up to check for the S##E## format
        my $search = $path.$show."*";
        $search = $search."S".$season_no."E".$episode_no."*";

        #print "File check string is |$search|\n";

        @file_check = glob("$search");

        #print "File Check is |@file_check|\n";

        $file_check[0] = "nothing" unless defined $file_check[0];

        if ($file_check[0] eq "nothing") {

                #Now check for the ##x## format
                $search = $path.$show."*";
                $search = $search.$season_no."x".$episode_no."*";

        	@file_check = glob("$search");

                $file_check[0] = "nothing" unless defined $file_check[0];

                if ($file_check[0] eq "nothing") {
                	#Now check for the Series # ##of## format
                	$search = $path.$show."*";

			$season_no =~ s/^0//;
			$episode_no =~ s/^0//;

                	$search = $search."Series*".$season_no."*".$episode_no."of*";
        		@file_check = glob("$search");

                	$file_check[0] = "nothing" unless defined $file_check[0];
                        
                	if ($file_check[0] eq "nothing") {
				$check = 0;
			} else {
				$check = 1;
			}
                } else {
                        $check = 1;
                }
        }
        else {
                $check = 1;
        }

        return $check;
}

sub downloading_check {

	my %config = load_config();

        my @torrent_list = get_torrent_list();
        my $show_name = shift;
        my $season_no = shift;
        my $episode_no = shift;
        my $proper = shift;
        my $line;
        my $check = 0;

        $show_name =~ s/\_/\.\?/g;
        $show_name =~ s/\s+/\.\?/g;
        $show_name = $show_name.".*".$season_no.".*E".$episode_no;

        #print "The show name for download check is $show_name\n";
        #die "The show name for download check is $show_name\n";

        foreach $line (@torrent_list) {
                #print $line;
        	$line =~ s/\_/\.\?/g;
        	$line =~ s/\s+/\.\?/g;
                if ($line =~ m/$show_name/i) {
        		if ($proper == 1) {
				if ($line =~ m/PROPER/ || $line =~ m/REAL/ || $line =~ m/REPACK/) {
					$check = 1;
				}
			} else {
				$check = 1;
			}
                }
        }
        
	#Now check again for shows with SxEE
	
	# drop season back to single digit for this standard if < 10
	$season_no = int $season_no;

        $show_name = $show_name.".*".$season_no."x".$episode_no;

	foreach $line (@torrent_list) {
                #print $line;
        	$line =~ s/\_/\.\?/g;
        	$line =~ s/\s+/\.\?/g;
                if ($line =~ m/$show_name/i) {
        		if ($proper == 1) {
				if ($line =~ m/PROPER/ || $line =~ m/REAL/ || $line =~ m/REPACK/) {
					$check = 1;
				}
			} else {
				$check = 1;
			}
                }
        }

        return $check;
}

sub directory_check {
	
	my %config = load_config();
        
	my $path = shift;
        my $exists = 0;

       	$path = clean_data($path);
 
	if (-d "$path" ) {
                $exists = 1;
                #print "Directory $path exists\n";
        } else {
                my $create_state = mkdir "$path",0777 or die "Couldn't create $path: $!";
                chmod 0777, $path or die "Couldn't chmod $path: $!";
		#print "create state = $create_state\n";
                #print "directory created at $path\n";
                $exists = 1 unless $create_state == 0;
        }

        if ($exists == 0) {
                die "Directory failed to create but did not exist\n";
        }

        return $exists;
}

sub op_lock_check {

	my $check;

	my @lock_check = glob("/tmp/auto_lock*");

        $lock_check[0] = "nothing" unless defined $lock_check[0];

        if ($lock_check[0] eq "nothing") {
                $check = 0;
        } else {
        	$check = 1;
        }

	return $check;
}

sub op_lock_set {
	
	system('touch /tmp/auto_lock');	
}

sub op_lock_remove {

	unlink("/tmp/auto_lock");
}

sub transmission_check {

	my @torrent_list = get_torrent_list();

	foreach my $line (@torrent_list) {	
		if ($line =~ m/transmission\-remote\:\ \(localhost\:9091\)/) {
			return 0;
		}  
	}

	return 1;
}

sub apply_crontab {
	my $return = "";
	my %config = load_config();

	my $crontab_value = $config{rss_time};

	my $auto_location = "/usr/local/bin/auto";
	
	my $off_peak_start = shift;
	my $on_peak_start = shift;
	
	my @raw_crontab = `crontab -l`;
	
	my @new_crontab;

	my $crontab_timing;

	if ($crontab_value eq "5") {
		$crontab_timing = "0,5,10,15,20,25,30,35,40,45,50,55";
	} elsif ($crontab_value eq "10") {
		$crontab_timing = "0,10,20,30,40,50";
	} elsif ($crontab_value eq "15") {
		$crontab_timing = "0,15,30,45";
	}
	
	foreach my $line (@raw_crontab) {
		if ($line !~ m/auto.* cli off_peak/ && $line !~ m/auto.* cli on_peak/ && $line !~ m/auto.* cli rss/ && $line !~ m/auto.* cli movierss/ && $line !~ m/auto.* cli del_old_torrent/ && $line !~ m/auto.* cli clean_up/ && $line !~ m/auto.* cli my_eps/ && $line !~ m/\#AUTO system/) {
			push(@new_crontab,$line);
		}
	} 

	push(@new_crontab,"#AUTO system crontab entries\n");

	my @time = split(/:/,$off_peak_start);
	push(@new_crontab,"$time[1] $time[0] * * * $auto_location cli off_peak\n");
	
	@time = split(/:/,$on_peak_start);
	push(@new_crontab,"$time[1] $time[0] * * * $auto_location cli on_peak\n");
	
	push(@new_crontab,"$crontab_timing * * * * $auto_location cli rss\n");
	
	push(@new_crontab,"14,29,44,59 * * * * $auto_location cli movierss\n");
	
	push(@new_crontab,"30 23 * * * $auto_location cli clean_up\n");
	
	push(@new_crontab,"1 00 * * * $auto_location cli my_eps\n");

	open ( CRONTABFILE, ">/tmp/auto_crontab_rebuild" ) or die "$!";

	foreach (@new_crontab) {
		print CRONTABFILE $_;
	}

	close CRONTABFILE;

	$return = `crontab /tmp/auto_crontab_rebuild`;
	unlink("/tmp/auto_crontab_rebuild");

	return $return;
}

#START CLI BASED SUBS HERE

sub cli_start_transmission {

	my $return = "";
	my %config = load_config();

	$return .= `$config{daemon_loc} -a 192.168.*.*,127.0.0.1 -g ~/.transmission`;

	sleep 5;

	$return .= "Setting transmission port, peer exchange and DHT\n";
	$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -x -p $config{transmission_port} -m -o`;

	return $return;
}

sub cli_add_db_torrents {

	use DBI;
	
	my $return = "";
	my $torrent = "";
	my $download = "";
	my $hash = "";
	
	my %config = load_config();

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";

        my $query = $dbh->prepare("select * from running_torrents") || die "DBI::errstr";
	
	$query->execute;
	$query->bind_columns(\$torrent,\$download,\$hash);
	
	my $lock_check = op_lock_check();

	while ($lock_check == 1) {
		$lock_check = op_lock_check();
		print "operation lock exists, waiting\n";
		sleep 5;
	}

	op_lock_set();

	while ($query->fetch) {
		$return .= "Adding $torrent\n";
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -w "$download" -a "$torrent"`;
		
		#Adding delay to stop transmission getting download directories mixed up
		sleep 2;
	}

	op_lock_remove();

	return $return;
}

sub cli_set_off_peak_speed {
	
	#Sets the off peak speed limit as set via config

	my $return = "";
	my %config = load_config();

	$return .= "Setting upload speed limit to $config{off_peak_up_speed_kb} from config\n";
	$return .= "Note -  -1 means unlimited at this time\n";
	
	if ($config{off_peak_up_speed_kb} == -1) {
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -U`;
	} else {	
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -u $config{off_peak_up_speed_kb}`;
	}

	$return .= "Setting Download speed limit to $config{off_peak_down_speed_kb} from config\n";
	$return .= "Note - -1 means unlimited at this time\n";

	if ($config{off_peak_down_speed_kb} == -1) {
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -D`;
	} else {	
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -d $config{off_peak_down_speed_kb}`;
	}

	return $return;
}

sub cli_set_on_peak_speed {
	
	#Sets the on peak speed limit as set via config

	my $return = "";
	my %config = load_config();

	$return .= "Setting upload speed limit to $config{on_peak_up_speed_kb} from config\n";
	$return .= "Note - -1 means unlimited at this time\n";
	
	if ($config{on_peak_up_speed_kb} == -1) {
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -U`;
	} else {	
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -u $config{on_peak_up_speed_kb}`;
	}

	$return .= "Setting Download speed limit to $config{on_peak_down_speed_kb} from config\n";
	$return .= "Note - -1 means unlimited at this time\n";

	if ($config{on_peak_down_speed_kb} == -1) {
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -D`;
	} else {	
		$return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -d $config{on_peak_down_speed_kb}`;
	}

	return $return;
}

sub cli_on_peak_ops {

	my $return = "";
	
	$return = cli_set_on_peak_speed();

	$return .= cli_start_queue_torrents("on");

	return $return;
}

sub cli_off_peak_ops {

	my $return = "";
	
	$return = cli_set_off_peak_speed();

	$return .= cli_start_queue_torrents("off");

	return $return;
}

sub cli_start_queue_torrents {
	
	my $queue = shift;

	my $return = "";
	my %config = load_config();

	use DBI;
	use BitTorrent;

        my $ds = get_datasource();
        my $dbh = DBI->connect($ds) || die "DBI::errstr";
	
	my $torrent_path = "";
	my $download_path = "";	
	my $hash = "";

	my $query = "";
	my $query2 = "";
	my $query3 = "";
	
	$return = "Starting torrents from the $queue peak queue\n";
	
	if ($queue eq 'on') {
		$query = $dbh->prepare("SELECT * FROM on_peak_queue");	
		$query3 = $dbh->prepare("delete from on_peak_queue");
	}
	elsif ($queue eq 'off') {
		$query = $dbh->prepare("SELECT * FROM off_peak_queue");
		$query3=$dbh->prepare("delete from off_peak_queue");
	}
	
	$query->execute();
        $query->bind_columns(\$torrent_path,\$download_path);

	while ($query->fetch()) {
                $torrent_path =~ s/^\s//;

		if ($torrent_path =~ m/^magnet:.*urn:btih:(\w*)&dn/i) {
			#Get the hash from the magnet link
			$hash = $1;
	 	} else {	
			# Get the hash from the bittorrent file for insertion into DB
			my $bt = BitTorrent->new();
			my $hashref = $bt->getTrackerInfo($torrent_path);	
			$hash = $hashref->{'hash'};
		}

                $return .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -w "$download_path" -a "$torrent_path"`;
                $query2 = $dbh->prepare("INSERT INTO running_torrents values ('$torrent_path','$download_path','$hash')");
                $query2->execute();
        }

	$query3->execute();

	return $return;
}

sub cli_rss {

	use strict;
	use DBI;
	use XML::RSS;
	use LWP::Simple;

	my $verbose = shift;

	# Declare variables
	my $content;
	my $file;

        my $return = "";
        my %config = load_config();

	#$config{rss_loc} = "http://www.ezrss.it/search/index.php?simple&show_name=shit+my+dad+says&mode=rss";

	my $rss_location = "/tmp/auto.rss";

	if ($config{rss_state} eq "off") {
                $return = "RSS is currently disabled\n" if $verbose == "1";
		return $return;
 	}

	#Check that transmission is actually running
	my $transmission_check = transmission_check();

	if ($transmission_check eq 0) {
		$return = "Transmission is not running\n";
		return $return;
	}
	my @rss_links = split(/,/,$config{rss_loc});

	$return = "Beginning RSS downloads\n" unless $verbose == 0;
	
	foreach my $rss_link (@rss_links) {
		my $rss_return = "";
		my $rss_skip = 0;

		$rss_return .= "Downloading RSS Feed $rss_link\n";

	        my $wget_output = `wget -t 3 -o /dev/stdout "$rss_link" -O "$rss_location"`;
		if ($wget_output =~ m/ERROR/ || $wget_output =~ m/Giving up./) {
			$rss_return .= "RSS feed failed to download\n";
			next;

		} else {
			$rss_return .= "RSS feed $rss_link downloaded\n";
		}

		# create new instance of XML::RSS
		my $rss = new XML::RSS;
	
		# argument is a URL
		if ($rss_location =~ /http:/i) {
  			$content = get($rss_location);
			die "Could not retrieve $rss_location" unless $content;
    			# parse the RSS content
    			$rss->parse($content);
	
		# argument is a file
		} else {
    			$file = $rss_location;
    			die "File \"$file\" does't exist.\n" unless -e $file;
			if (-s $file) {
    				# parse the RSS file
    				$rss->parsefile($file);
				$rss_return .= "Scanning the RSS feed for torrents\n";
			} else {
				$rss_return.= "$rss_link did not download correctly or is blank\n";
				$rss_skip = 1;
			}
		}

		# If verbose is off, clear return at this point
		if ($verbose == 0) {
			$rss_return = "";
		}

		$return .= $rss_return;

		if ($rss_skip == 0) {
			# process the RSS listing
			$return .= process_rss($rss,$verbose);
			$return .= "Done!\n" unless $verbose == 0;
		} else {
			$return .= "Skipping $rss_link\n";
		}
	}
	$return .= "Checking for torrents that have reached the $config{rss_ratio} ratio\n" unless $verbose == 0;

	# Check for torrents that are ready to be stopped
	$return .= stop_ratio($verbose);

	$return .= "Done!\n" unless $verbose == 0;

	return $return;
}	

sub cli_movierss {

	use strict;
	use DBI;
	use XML::RSS;
	use LWP::Simple;

	my $verbose = shift;

	# Declare variables
	my $content;
	my $file;

        my $return = "";
        my %config = load_config();

	#$config{rss_loc} = "http://www.ezrss.it/search/index.php?simple&show_name=shit+my+dad+says&mode=rss";

	my $rss_location = "/tmp/auto_movie.rss";

	if ($config{rss_state} eq "off") {
		$return = "RSS is currently disabled\n" if $verbose == "1";
		return $return;
 	}

	#Check that transmission is actually running
	my $transmission_check = transmission_check();

	if ($transmission_check eq 0) {
		$return = "Transmission is not running\n";
		return $return;
	}
	my @rss_links = split(/,/,$config{movie_rss_loc});

	$return = "Beginning Movie RSS downloads\n" unless $verbose == 0;
	
	foreach my $rss_link (@rss_links) {
		my $rss_return = "";
		my $rss_skip = 0;

		$rss_return .= "Downloading Movie RSS Feed $rss_link\n";

	        my $wget_output = `wget -t 3 -o /dev/stdout "$rss_link" -O "$rss_location"`;
		if ($wget_output =~ m/ERROR/ || $wget_output =~ m/Giving up./) {
			$rss_return .= "RSS feed failed to download\n";
			next;

		} else {
			$rss_return .= "Movie RSS feed $rss_link downloaded\n";
		}

		# create new instance of XML::RSS
		my $rss = new XML::RSS;
	
		# argument is a URL
		if ($rss_location =~ /http:/i) {
  			$content = get($rss_location);
			die "Could not retrieve $rss_location" unless $content;
    			# parse the RSS content
    			$rss->parse($content);
	
		# argument is a file
		} else {
    			$file = $rss_location;
    			die "File \"$file\" does't exist.\n" unless -e $file;
			if (-s $file) {
    				# parse the RSS file
    				$rss->parsefile($file);
				$rss_return .= "Scanning the Movie RSS feed for torrents\n";
			} else {
				$rss_return.= "$rss_link did not download correctly or is blank\n";
				$rss_skip = 1;
			}
		}

		# If verbose is off, clear return at this point
		if ($verbose == 0) {
			$rss_return = "";
		}

		$return .= $rss_return;

		if ($rss_skip == 0) {
			# process the RSS listing
			$return .= process_movie_rss($rss,$verbose);
			$return .= "Done!\n" unless $verbose == 0;
		} else {
			$return .= "Skipping $rss_link\n";
		}
	}
	$return .= "Done!\n" unless $verbose == 0;

	return $return;
}	

sub cli_delete_old_torrents {

	my %config = load_config();
	my $content .= "Processing torrents for deletion candidates\n";
	my @torrent_del_names;

  	my $lock_count = 0;
  	my $lock_check = op_lock_check();

	while ($lock_check == 1) {
  		$lock_check = op_lock_check();
  		$content .= "operation lock exists, waiting\n";
	
    		$lock_count++;
   		sleep 5;
	
    		if ($lock_count >= 60) {
			#Maybe email here?
			#die "AUTO lock count exceeded\n";
			$content .= "operation lock stuck, overriding and stopping stuck processes\n";
			op_lock_remove();
			`pkill perl`;
  			$lock_check = op_lock_check();
    		}
  	}
		
	my $torrent_array = json_load_torrents();
  	my @torrents = @$torrent_array;
  	
	op_lock_set();
	
	my $last_active = $config{last_active};
	$last_active = $last_active * 86400;
	my $seed_time = $config{seed_time};
	$seed_time = $seed_time * 86400;
	
	foreach my $torrent (@torrents) {
		
		my (%torrent) = %{($torrent)};
		
		#Define variable for use below
		my $id = $torrent{"id"};
		my $name = $torrent{"name"};
		my $status = $torrent{"status"};
		
		my $info_array = json_load_info($id);
		my @info = @$info_array;
		my $filter = "all";

		if ($info[0] eq "error") {
			print "An error has occured\n";
		} 
		else {
			my $time = time;
			$time = $time - $last_active;
			if ($info[0]->{"secondsSeeding"} > $seed_time && $info[0]->{"activityDate"} < $time && ($info[0]->{"status"} == 6 || $info[0]->{"status"} == 8)) {
				if ($config{remove_data} eq "on") {
					$content .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id --remove-and-delete`;
					$content .= "Torrent ID: " . $id . "\n";
					$content .= "Name: " . $name . " has been flagged for deletion\n\n";
					push(@torrent_del_names, $name);
				} elsif ($config{remove_data} eq "off") {
					$content .= `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id -r`;
					$content .= "Torrent ID: " . $id . "\n";
					$content .= "Name: " . $name . " has been flagged for deletion\n\n";
					push(@torrent_del_names, $name);
				}
			}
		}
	}
	
	if (@torrent_del_names) {
		del_tor_email(@torrent_del_names);
		$content .= "Process Complete\n";
	}
	else {
		$content .= "No torrents require deletion\n";
		$content .= "Process Complete\n";
	}
	
	op_lock_remove();

	return $content;				
}

sub sync_trans_auto {
	use DBI;
	
	my $content .= "Syncing torrents to AUTO that were added to Transmission externally\n";
	
	my %config = load_config();
	my $download_path = $config{rss_down_loc};
	
	my @trans_torrent_info = `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -l`;
	my @trans_torrent_ids;
	my %torrent_file_return;

	my $fixed_something = 0;

	foreach my $line (@trans_torrent_info) {
			if ($line =~ m/^\s*(\d{1,4})\s.*$/) {
				push(@trans_torrent_ids, $1);
			}
	}

	foreach my $id (@trans_torrent_ids) {      
		my @torrent_history = `$config{remote_loc} -n $config{remote_user}:$config{remote_pass} -t $id -i`;
		my %parsed_torrent_history;
		my $running_hash = get_running_hash($id);
		%torrent_file_return = get_db_entry($running_hash);
		
		foreach my $line (@torrent_history) {
			if ($line =~ m/Name\:\s(.*)$/) {
				$parsed_torrent_history{name} = $1;
			}
			elsif ($line =~ m/Hash\:\s(.*)$/) {
				$parsed_torrent_history{hash} = $1;
			}
		}
		
		if ($torrent_file_return{error}) {
		        my $ds = get_datasource();
        		my $dbh = DBI->connect($ds) || die "DBI::errstr";

			$fixed_something = 1;

 	 		$parsed_torrent_history{name} =~ s/^s+//;
 	 		$parsed_torrent_history{name} =~ s/\'//;
  			$download_path =~ s/^s+//;
  			my $query = $dbh->prepare("INSERT INTO running_torrents values ('$parsed_torrent_history{name}','$download_path','$parsed_torrent_history{hash}')") || die "DBI::errstr";
			$content .= "Externally added torrent found: " . $parsed_torrent_history{name} . "\n";
			$content .= "Adding to AUTO DB\n";
			
			$query->execute();
		}
	}
	if ($fixed_something == 0) {
			$content .= "No external torrents found\n";
	}
	$content .= "Done\n";
	
	return $content;
}

sub cli_clean_up {

my $content;
$content = cli_delete_old_torrents();		
$content .= sync_trans_auto();

return $content;

}

sub cli_name_check {

        my $show_name = shift;
        my $torrent_file = shift;
        my $season_no;
        my $episode;
        my $proper;

        if ($torrent_file =~ m/(.*)\s(\-|\_).*\s(\d?\d)x(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $3;
                $episode = $4;

        } elsif ($torrent_file =~ m/(.*)\s(\d?\d)x(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $2;
                $episode = $3;

        } elsif ($torrent_file =~ m/(.*)\sS(\d?\d)E(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $2;
                $episode = $3;

        } elsif ($torrent_file =~ m/(.*)\s(\-|\_).*(\d?\d)\sx\s(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $3;
                $episode = $4;

        } elsif ($torrent_file =~ m/(.*)\s(\d?\d)\sx\s(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $2;
                $episode = $3;

        } elsif ($torrent_file =~ m/(.*)\.S(\d?\d)E(\d?\d).*\.torrent/g) {
                $show_name = $1;
                $season_no = $2;
                $episode = $3;

        }

        # Begin new cleaned up entries without Show name

        # Search seasons
        if ($torrent_file =~ m/Series.(\d?\d)/i) {
                $season_no = $1;
        } elsif ($torrent_file =~ m/(\d?\d)x(\d?\d)/gi) {
                $season_no = $1;
        }

        # Then find episode number
        if ($torrent_file =~ m/(\d?\d)of(\d?\d)/gi) {
                $episode = $1;
        } elsif ($torrent_file =~ m/(\d?\d)x(\d?\d)/gi) {
                $episode = $2;
        }

        if ($torrent_file =~ m/PROPER/ || $torrent_file =~ m/REAL/ || $torrent_file =~ m/REPACK/) {
                $proper = 1;
        } else {
                $proper = 0;
        }

        print "Checking $show_name, season $season_no Episode $episode, proper = $proper\n";

	#my $file_check = file_check($download_path,$search_value,$season_no,$episode);
	my $dl_check = downloading_check($show_name,$season_no,$episode,$proper);

        #print "file check reports $file_check\n";
        print "downloading check reports $dl_check\n";

        die "done checking\n";
}


sub cli_test {

	my $results = json_pause_torrent("2,3,4","false");

	my (%result) = %{($results)};

	print "result is ".$result{"result"}."\n";
	
	my $filter = "all";

}

sub cli_help {
	my $content;

	$content = "---------- AUTO CLI Functions ------------\n";
	$content .= "\n";
	$content .= "start_trans\t\tStarts transmission and loads torrents back in\n";
	$content .= "load_database\t\tLoads AUTOs database of running torrents into transmission\n";
	$content .= "off_peak\t\tSets off peak speed restriction and starts off peak queued torrents\n";
	$content .= "set_off\t\t\tSets off peak speed restriction\n";
	$content .= "start_off_peak\t\tStarts off peak queued torrents\n";
	$content .= "on_peak\t\t\tSets on peak speed restriction and starts on peak queued torrents\n";
	$content .= "set_on\t\t\tSets off peak speed restriction\n";
	$content .= "start_on_peak\t\tStarts off peak queued torrents\n";
	$content .= "rss\t\t\tDownloads the latest RSS feed, starts new torrents, and does ratio pause check\n";
	$content .= "movierss\t\tDownloads the latest movie RSS feed, compares to AUTO list, and emails user if match found\n";
	$content .= "del_old_torrents\tDeletes all torrents that are currently idle and are greater than set options for Auto Delete\n";
	$content .= "sync_trans_auto\t\tSync torrents into AUTO that were added externally to Transmission e.g. via Transmission-QT etc\n";
	$content .= "clean_up\t\tRun both del_old_torrents followed by sync_trans_auto\n";
	$content .= "help\t\t\tDisplays this list of available functions\n";
	$content .= "\n";
	$content .= "------------------------------------------\n";

	return $content;	
}

sub clean_data {
	my $data = shift;

	#if data is blank, return
	if ($data =~ /^$/) {
		return $data;
	}

	if ($data =~ /^([ \/&\[\]\(\):#\@\w].*)$/) {
		$data = $1; #data is now untainted
	} else {
		die "Bad Data: $data\n";
	}

	return $data;
} 

sub convert_to_epoch {
	my $date = shift;
	if ($date =~ m/\w{3}\s(\w{3})\s(\d{1,2})\s(\d{2}):(\d{2}):(\d{2})\s(\d{4})$/) {
		my @months = ("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
		my $month = $1;
		my $day = $2;
		my $hour = $3;
		my $minute = $4;
		my $second = $5;
		my $year = $6;
		for (my $i = 0; $i < @months; $i++) {
    	if ($months[$i] eq $month) {
				$month = $i;
			}
		}
		
		$month++;
		my $datetime = DateTime->new( year => $year, month => $month, day => $day, hour => $hour, minute => $minute,
    second => $second);
		my $epoch_time = $datetime->epoch;
		return $epoch_time;
	}
}

sub convert_time {
	my $time = shift;
	my $scale;

	if ($time >= 60) {
		$time = $time / 60;
		
		if ($time >= 60) {
			$time = $time / 60;
			
			if ($time >= 24) {
				$time = $time / 24;
				
				if ($time >= 7) {
					$time = $time / 7;

					if ($time >= 52) {
						$time = $time / 52;
						$scale = "Years";
					} else {
						$scale = "Weeks";
					}
				} else {
					$scale = "Days";
				}
			} else {
				$scale = "Hours";
			}
		} else {
			$scale = "Minutes";
		}
	} else {
		$scale = "Seconds";
	}

	my $return = sprintf("%.1f", $time)." ".$scale;

	return $return;
}

sub convert_data {
	my $rate = shift;
	my $scale;

	if ($rate >= 1024) {
		$rate = $rate / 1024;
		
		if ($rate >= 1024) {
			$rate = $rate / 1024;
			
			if ($rate >= 1024) {
				$rate = $rate / 1024;
				
				if ($rate >= 1024) {
					$rate = $rate / 1024;
					$scale = "TiB";
				} else {
					$scale = "GiB";
				}
			} else {
				$scale = "MiB";
			}
		} else {
			$scale = "KiB";
		}
	} else {
		$scale = "B";
	}

	my $return = sprintf("%.1f", $rate)." ".$scale;

	return $return;
}

sub del_tor_email {

	my %config = load_config();
	my @tor_del_names = @_;
	
	my $sendmail = "/usr/sbin/sendmail -f remove_torrent -t";
	my $subject = "Subject: Subject: AUTO has removed an old torrent\n";
  
	my $send_to = "To: $config{email_addr}\n";
	 
	open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
	#print SENDMAIL $reply_to;
	print SENDMAIL $subject;
	print SENDMAIL $send_to;
	print SENDMAIL "Content-type: text/html\n\n";
	print SENDMAIL "<html>\n";
	print SENDMAIL "<p>Hi User,<br />\n";
	print SENDMAIL "The following torrents have been removed:<br />\n";
	print SENDMAIL "<br />";
	foreach my $torrent (@tor_del_names) {
		print SENDMAIL "<strong>" . $torrent . "</strong><br />\n";
	}
	print SENDMAIL "<br />\n";
	print SENDMAIL "They have seeded for greater than ". $config{seed_time} . " days and had no activity in the last " . $config{last_active} . " days\n";
	print SENDMAIL "<br />\n";
	print SENDMAIL "Enjoy the rest of your day!!</p>\n";
	print SENDMAIL "</html>";
	close(SENDMAIL)	
}
