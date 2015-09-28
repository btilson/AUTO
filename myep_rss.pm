#!/usr/local/sbin/perl-suid

use warnings;
use strict;
use CGI;
use XML::RSS;
use LWP::Simple;

1;
sub retrieve_my_eps_today {
	
  	my $content;
	my %config = load_config();
	my %shows = load_rss_shows();
	my $ds = get_datasource();
	my $show;
	my $epName;
	my $seasonEp = "0x0";
	my $working = "";

  	my $dbh = DBI->connect($ds) || die "DBI::errstr";
	
	# clear yesterdays tv shows
	my $query = $dbh->prepare("DELETE FROM my_eps_today") || die "DBI::errstr";
  	$query->execute();
	
	my $rootDir = $config{rss_down_loc};
  # todays myepisodes rss
	#my $rssUrl = $config{my_eps_rss};
	my $rssUrl = "http://www.myepisodes.com/rss.php?feed=all&uid=auto_user&pwdmd5=d73a4d380561ec4b316f4532b70d90a2";
  
	my $rss = new XML::RSS;
  $content = get($rssUrl);
	
	if ($content eq ''){
		return "failed";
	}
	else {
    $rss->parse($content);
		$working .= "Checking rss feeds for shows out today\n";
		foreach my $item (@{$rss->{'items'}}){
      if ($item->{'title'} =~ /^\[\ (.*)\ \]\[\ (.*)\ \]\[\ (.*)\ \]\[\ (.*)\ \]/i){
      	$show = $1;
      	$seasonEp = $2;
      	$epName = $3;
				for my $db_rss_show_name ( keys %shows ) {
					$show =~ s/\'/\-quote\-/g;
					$epName =~ s/\'/\-quote\-/g;
					if ($show =~ /^$db_rss_show_name$/i) {
						$working .= "Episode of " . $show . " out today, adding to DB\n";
						$query = $dbh->prepare("INSERT INTO my_eps_today values ('$show','$seasonEp','$epName')") || die "DBI::errstr";
      			$query->execute();
					}
				}
			}
		}
	}
return $working;
}

sub load_my_eps_today {
	
  my $content;
	my $rssInfoList = '';
	my %config = load_config();
	my %todays_shows;
	my $show;
	my $epName;
	my $seasonEp = "0x0";

	my $season = 0;
	my $episode = 0;
	
	my $ds = get_datasource();
	my $dbh = DBI->connect($ds) || die "DBI::errstr";
	
	my $query = $dbh->prepare("SELECT * from my_eps_today") || die "DBI::errstr";
	$query->execute;
	$query->bind_columns(\$show,\$seasonEp,\$epName);
	
	my $count = 1;
	while ($query->fetch) {
		#$todays_shows{"$show"}=$seasonEp."&".$epName;
		$todays_shows{"$count"}=$show."&".$seasonEp."&".$epName;
		$count++;
	}
	
	$rssInfoList .= "<h3>Today's Shows</h3>\n";
  	$rssInfoList .= "<table>\n";
  	$rssInfoList .= "<tr>\n";
  	$rssInfoList .= "<td></td>\n";
  	$rssInfoList .= "<td><strong>Show Name</strong></td>\n";
  	$rssInfoList .= "<td><strong>Season</strong></td>\n";
 	$rssInfoList .= "<td><strong>Episode</strong></td>\n";
	$rssInfoList .= "<td><strong>Episode Name</strong></td>";
	$rssInfoList .= "<td><strong>DLing/DL'd?</strong></td>";
	$rssInfoList .= "</tr>\n";


	if (%todays_shows) {
		foreach my $key ( keys %todays_shows ) {
    			my $value = $todays_shows{$key};
			my @inc_exc_values = split(/&/,$value);
			my $hadDL = "N";	
			my $download_path = $config{rss_down_loc};
			#my $orig_show = $key;
			#$show = $key;
			#$seasonEp = $inc_exc_values[0];
			#$epName = $inc_exc_values[1];
			
			my $orig_show = $inc_exc_values[0];
			$show = $inc_exc_values[0];
			$seasonEp = $inc_exc_values[1];
			$epName = $inc_exc_values[2];
	
			$seasonEp = "" unless defined($seasonEp);
			$epName = "" unless defined($epName);
      
			$show =~ s/\-quote\-/\'/g;
			$epName =~ s/\-quote\-/\'/g;
			$rssInfoList .= "<tr>\n";
      			$rssInfoList .= "<td></td>\n";
			$rssInfoList .= "<td>";

		
			# Swap out whitespace for underscores (or else the special character regex below removes them)
			$show =~ s/\s/_/g;
			
			# Swap out special characters in name for nothing
			# Commented out it breaks matching on shows with hyphens
			# $show =~ s/\W//g;
	
			# Swap out underscores for whitespace again
			$show =~ s/_/ /g;

			my $search_value = $show;
			
			# Swap out dots in name for whitespace (to be swapped out later for underscores)
			$show =~ s/\./ /g;
			
			# Swap out regex start and end characters for the name
			$show =~ s/^\^//g;
			$show =~ s/\$$//g;

			#Perform manipulation on necessary things
			#lower case the whole string
			$show =~ tr/[a-z]/[A-Z]/;

			#Capitalise first letter of every word
			$show =~ s/(?<=\w)(.)/\l$1/g;
	
			#Swap whitespace for underscores
			$show =~ s/\s/_/g;

			
			my $proper = 0;
	
      			if ($seasonEp =~ /^(\d{2})x(\d{2})/i){
      				$season = $1;
      				$episode = $2;
      			}
		        
			if ($config{rss_sorting} eq "on") {
       			        $download_path = $download_path."/".$show."/";
                		$download_path = $download_path."Season_".$season."/";
        		}
			
      			my $rssShowInfo = $orig_show . "</td><td><center>" . $season . "</center></td><td><center>" . $episode . "</center></td><td>" . $epName;
      			$rssInfoList .= $rssShowInfo;

	                my $file_check = file_check($download_path,$search_value,$season,$episode);
	                my $dl_check = 0;

      	       		if ($file_check == 1) {
               	       		$hadDL = "Y";
               		} else {
                       		$dl_check = downloading_check($show,$season,$episode,$proper);
                       		if ($dl_check == 1) {
               	       			$hadDL = "Y";
				} else {
					$hadDL = "N";
				}
			}

			if ($hadDL eq 'Y') {
				$rssInfoList .= "<td><center>&#10004;</center></td>\n";
			} else {
  				$rssInfoList .= "<td><center>&#10007;</center></td>\n";
			}
      		$rssInfoList .= "</td></tr>\n";
		}
    		$rssInfoList .= "</table>\n";
		
		if ($show eq '' && $seasonEp eq '' && $epName eq ''){
			$rssInfoList = "<h3>No Shows Out Today &#9785;</h3>\n";
			$rssInfoList .= "<p>Find something else to do</p>\n";
		}
    		return $rssInfoList;
	} else {
		$rssInfoList = "<h3>No Shows Out Today &#9785;</h3>\n";
		$rssInfoList .= "<p>Find something else to do</p>\n";
    return $rssInfoList;
	}
}




