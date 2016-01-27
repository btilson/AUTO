#!/usr/local/sbin/perl-suid

use strict;
use warnings;
use CGI;
require "/var/www/html/auto/auto.pm";
require "/var/www/html/auto/auto_json.pm";
require "/var/www/html/auto/myep_rss.pm";
#require "./auto.pm";

$ENV{PATH} = "/bin:/usr/bin";

# Declare subroutine (for prototyping)
sub generate_page ($\%\@); 
sub generate_no_headers_page ($\%\@); 
sub cli_functions ($);

my $page;
my $headers;
my $db_editor_page;

#Set real UID to match Effective UID (for system calls etc)
$< = $> ;
#Set real GID to match Effective GID (for System calls etc)
$( = $) ;


$auto::cgi = new CGI;

$page = $auto::cgi->param('page');
$headers = $auto::cgi->param('headers');

$db_editor_page = $auto::cgi->param('db_editor_page');

my %pages = (
	index => 'Home',
	add => 'Add',
	operate => 'Operate',
	tcontrol => 'Transmission Control',
	rcontrol => 'RSS Control',
	mcontrol => 'Movie RSS Control',
	category => 'Categories',
	options => 'Options',
	dbmaint => 'Database Maintenance'
);

#dodgy array created to allow hash above to be pulled in a specific order
my @pages_short = ("index","add","operate","rcontrol","mcontrol","category","options");

$page = "index" unless defined($page);
$headers = "yes" unless defined($headers);
$ARGV[0] = "web" unless defined($ARGV[0]);

$db_editor_page = "NONE" unless defined($db_editor_page);

if ($db_editor_page ne "NONE") {
	$page = "dbmaint";
}

#Fork here if auto has been run with a cli switch otherwise run web based code
if ($ARGV[0] eq "cli") {
	#Running with CLI Switch, run CLI sub

	my $verbose = 0;

	print "Running AUTO in CLI mode\n" unless $verbose == 0;
	cli_functions($verbose);
} elsif ($headers eq "no") {
	generate_no_headers_page($page, %pages, @pages_short);
} else {
	generate_page($page, %pages, @pages_short);
}

#SUBS

sub generate_page ($\%\@) {

	my $page = shift;
	my (%pages) = %{(shift)};
	my (@pages_short) = @{(shift)};
	my $content = "";
	my $header = "";
	my $footer = "";
	my $endhtml = "";

	#determine the page type needed, and load the html from the subroutine
	if ($page eq "index") {
		$content = gen_index();
	} elsif ($page eq "add") {
		$content = gen_add();
	} elsif ($page eq "add_submit") {
		$content = gen_add_submit();
	} elsif ($page eq "operate") {
		$content = gen_operate("NOTHING");
	} elsif ($page eq "honour_submit") {
		$content = gen_honour_submit();
	} elsif ($page eq "pause_submit") {
		$content = gen_pause_submit();
	} elsif ($page eq "modify_submit") {
		$content = gen_modify_submit();
	} elsif ($page eq "remove_submit") {
		$content = gen_remove_submit();
	} elsif ($page eq "start_submit") {
		$content = gen_start_submit();
	} elsif ($page eq "rcontrol") {
		$content = gen_rcontrol();
	} elsif ($page eq "rcontrol_add_submit") {
		$content = gen_rcontrol_add_submit();
	} elsif ($page eq "rcontrol_remove_submit") {
		$content = gen_rcontrol_remove_submit();
	} elsif ($page eq "mcontrol") {
		$content = gen_mcontrol();
	} elsif ($page eq "mcontrol_add_submit") {
		$content = gen_mcontrol_add_submit();
	} elsif ($page eq "mcontrol_remove_submit") {
		$content = gen_mcontrol_remove_submit();
	} elsif ($page eq "category") {
		$content = gen_category();
	} elsif ($page eq "category_add_submit") {
		$content = gen_category_add_submit();
	} elsif ($page eq "category_remove_submit") {
		$content = gen_category_remove_submit();
	} elsif ($page eq "queue_list") {
		$content = gen_queue_list();
	} elsif ($page eq "queue_remove_submit") {
		$content = gen_queue_remove_submit();
	} elsif ($page eq "options") {
		$content = gen_options();
	} elsif ($page eq "options_submit") {
		$content = gen_options_submit();
	} elsif ($page eq "speed_submit") {
		$content = gen_speed_submit();
	} elsif ($page eq "dbmaint") {
		$content = gen_dbmaint();
	}

	if ($page =~ m/rcontrol/) {
		$page = "rcontrol";
	} elsif ($page =~ m/mcontrol/) {
    $page = "mcontrol";
	} elsif ($page =~ m/category/) {
		$page = "category";
	} elsif ($page =~ m/options/) {
		$page = "options";
	#} elsif ($page =~ m/submit/) {
	#	$page = "operate";
	}
	
	$header = generate_header($page, \%pages, \@pages_short);
	$footer = generate_footer(); 
	$endhtml = generate_endhtml(); 

	print "Content-type: text/html\n\n";
	print $header;
	
	#print "The page sent was ".$page . "<br />\n";
	
	print $content;

	print $footer;
	print $endhtml;
}
sub generate_no_headers_page ($\%\@) {

        my $page = shift;
        my (%pages) = %{(shift)};
        my (@pages_short) = @{(shift)};
        my $content = "";
        my $footer = "";

        #determine the page type needed, and load the html from the subroutine
        if ($page eq "index") {
                $content = gen_index();
        } elsif ($page eq "add") {
                $content = gen_add();
        } elsif ($page eq "add_submit") {
                $content = gen_add_submit();
        } elsif ($page eq "operate") {
                $content = gen_operate("NOTHING");
        } elsif ($page eq "honour_submit") {
                $content = gen_honour_submit();
        } elsif ($page eq "pause_submit") {
                $content = gen_pause_submit();
        } elsif ($page eq "modify_submit") {
                $content = gen_modify_submit();
        } elsif ($page eq "remove_submit") {
                $content = gen_remove_submit();
        } elsif ($page eq "start_submit") {
                $content = gen_start_submit();
        } elsif ($page eq "rcontrol") {
                $content = gen_rcontrol();
        } elsif ($page eq "rcontrol_add_submit") {
                $content = gen_rcontrol_add_submit();
        } elsif ($page eq "rcontrol_remove_submit") {
                $content = gen_rcontrol_remove_submit();
		} elsif ($page eq "mcontrol") {
                $content = gen_mcontrol();
        } elsif ($page eq "mcontrol_add_submit") {
                $content = gen_mcontrol_add_submit();
        } elsif ($page eq "mcontrol_remove_submit") {
                $content = gen_mcontrol_remove_submit();
        } elsif ($page eq "category") {
                $content = gen_category();
        } elsif ($page eq "category_add_submit") {
                $content = gen_category_add_submit();
        } elsif ($page eq "category_remove_submit") {
                $content = gen_category_remove_submit();
		} elsif ($page eq "queue_list") {
                $content = gen_queue_list();
		} elsif ($page eq "queue_remove_submit") {
                $content = gen_queue_remove_submit();
        } elsif ($page eq "options") {
                $content = gen_options();
        } elsif ($page eq "options_submit") {
                $content = gen_options_submit();
        } elsif ($page eq "speed_submit") {
                $content = gen_speed_submit();
        } elsif ($page eq "dbmaint") {
                $content = gen_dbmaint();
        }

        if ($page =~ m/rcontrol/) {
                $page = "rcontrol";
	} elsif ($page =~ m/mcontrol/) {
                $page = "mcontrol";
        } elsif ($page =~ m/category/) {
                $page = "category";
        } elsif ($page =~ m/options/) {
                $page = "options";
        #} elsif ($page =~ m/submit/) {
        #       $page = "operate";
        }
        
	$footer = generate_footer(); 

	print "Content-type: text/html\n\n";

	print $content;
	print $footer;
}

sub gen_index () {
	my %config = load_config();
	my $content = "<h1>Welcome to " . $config{app_name} . "</h1>\n";
	$content .= "<h2>The Advanced User-friendly Torrent Operations and Media Manipulation system</h2>\n";
	$content .= "<p>Please use any of the above tabs to navigate to whatever you need</p>\n";
	$content .= `$config{shell_ext}`;

	return $content;
}

sub gen_add () {
	my %config = load_config();
	my %categories = load_categories();
	my $content;
	my $cat_count = scalar(keys %categories);
	
	if ($config{rss_sorting} eq "on") {
	$content = qq^<h2>Use this page to add a torrent to Transmission</h2>
<p><strong>Before I can start, I need to ask a few questions</strong></p>

<form action="$ENV{SCRIPT_NAME}" method="post" enctype="multipart/form-data">
<fieldset>
<legend>Location Information</legend>
<p>
<input type="hidden" name="page" value ="add_submit" />
Firstly, what type of torrent are we downloading?
<select name="type">^;

	foreach my $category (keys %categories) {
		$content .= qq^<option value="$category">$category</option>\n^;
	}

$content .= qq^</select>
</p>
<p>
Select the torrents you want to download 
<input type="hidden" name="MAX_FILE_SIZE" value="500000" /> <input name="file" type="file" multiple="" />
</p>
<p>
Or put the magnet link you want to download
<input type="text" size="40" maxlength="320" name="magnet" /> e.g. <strong>magnet:?xt=urn:ed2k:354B15E68FB8F36D7CD88FF...</strong>
</p>

</fieldset>
<p>
When did you want me to start the torrent?
<input type="radio" name="timing" value="now" checked="checked" />Start Immediately
<input type="radio" name="timing" value="on" />On-Peak Download
<input type="radio" name="timing" value="off" />Off-Peak Download
</p>
<fieldset>
<legend>Advanced Sorting only</legend>
<p>
what is the show's name?
<input type="text" size="20" maxlength="40" name="name" /> e.g. <strong>How I Met Your Mother</strong>
</p>

<p>
What season is it?
<input type="text" size="5" maxlength="2" name="season" /> e.g. <strong>04</strong>
</p>
</fieldset>
<p><input type="submit" value="Start the Torrent!" /></p>
</form>\n^;
} elsif ($config{rss_sorting} eq "off" && $cat_count == 1) {
	$content = qq^<h2>Use this page to add a torrent to Transmission</h2>
<p><strong>Please select the torrent file below:</strong></p>

<form action="$ENV{SCRIPT_NAME}" method="post" enctype="multipart/form-data">
<input type="hidden" name="page" value ="add_submit" />
<fieldset>
<legend>Add Torrent</legend>
<p>^;
	foreach my $category (keys %categories) {
		$content .= qq^<input type="hidden" size="20" maxlength="40" name="type" value="$category"/>\n^;
	}
$content .= qq^</p>
<p>
Select the torrents you want to download 
<input type="hidden" name="MAX_FILE_SIZE" value="500000" /> <input name="file" type="file" multiple="" />
</p>
<p>
Or put the magnet link you want to download
<input type="text" size="40" maxlength="320" name="magnet" /> e.g. <strong>magnet:?xt=urn:ed2k:354B15E68FB8F36D7CD88FF...</strong>
</p>
<p>
When did you want to start the torrent?
<input type="radio" name="timing" value="now" checked />Start Immediately
<input type="radio" name="timing" value="on" />On-Peak Download
<input type="radio" name="timing" value="off" />Off-Peak Download
</p>
</fieldset>
<input type="hidden" size="20" maxlength="40" name="name" />
<input type="hidden" size="5" maxlength="2" name="season" />
<p><input type="submit" value="Start the Torrent!" /></p>
</form>\n^;
}
#$content .= qq!<a class="contentbar" onclick="createOverlay('page=queue_list')";>View Queued Torrents List</a>!;
$content .= gen_queue_list();
return $content;
}

sub gen_add_submit () {
	my $cgi = get_cgi();
	
	my $type = $cgi->param("type");
	my $show_name = $cgi->param("name");
	my $season_no = $cgi->param("season");
	my @torrents = $cgi->param("file");
	my $magnet = $cgi->param("magnet");
	my $timing = $cgi->param("timing");
	
	my @upload_filehandles = $cgi->upload("file");

	my %categories = load_categories();
	
	my %config = load_config();

	my $torrent_path; 
	my $content;	

	my @category_info = split(/,/,$categories{$type});

	my $main_directory = $category_info[0];
	my $sorting = $category_info[1];

	#$type = clean_data($type);
	$show_name = clean_data($show_name);
	$season_no = clean_data($season_no);
	#$timing = clean_data($timing);

	if ($sorting eq "on") {
        	#Perform manipulation on necessary things
                #lower case the whole string
	        $show_name =~ tr/[a-z]/[A-Z]/;
	
       	        #Capitalise first letter of every word
                $show_name =~ s/(?<=\w)(.)/\l$1/g;

		# Strip leading and following spaces;
                $show_name =~ s/^\s*//g;
                $show_name =~ s/\s*$//g;

                #Swap whitespace for underscores
                $show_name =~ s/\s/\_/g;



		directory_check($main_directory."/".$show_name);
	}
	
	my $download_path = generate_download_path($type, $show_name, $season_no);
	
	directory_check($download_path);
		
	$download_path = $download_path."/";

	my $counter = 0;

	$content = "<p>";
	
	if ($torrents[0] eq "") {
		#No torrent name given, check magnets
		if ($magnet =~ m/^magnet\:/) {
			#magnet link found
			my %add_torrent_return = add_torrent($download_path,$magnet,$timing);	
			$content .= $add_torrent_return{info};

		} else {
			#No valid magnet or torrent found
			$content .= "No valid magnet or torrent found";
		}
	} else {
		foreach my $torrent_name (@torrents) {
			#my $torrent_name = $torrents[$counter];
			my $upload_filehandle = $upload_filehandles[$counter];
		
			$torrent_name = clean_data($torrent_name);
			$counter++;
	
			# Remove source (client) directory in file name (IE leaves it attached)
			$torrent_name =~ s/.*\\//g;
	
			# Remove ' marks, curly and square brackets - Can break torrent adding at times
			$torrent_name =~ s/\'//g;
			$torrent_name =~ s/\[//g;
			$torrent_name =~ s/\]//g;
			$torrent_name =~ s/\{//g;
			$torrent_name =~ s/\}//g;
	
			my $torrent_dir = $config{torrent_loc};
	
			open ( UPLOADFILE, ">$torrent_dir/$torrent_name" ) or die "$!";
			binmode UPLOADFILE;
	
			while ( <$upload_filehandle> )
			{
				print UPLOADFILE;
			}
	
			close UPLOADFILE;
	
			my %torrent_path_return = generate_torrent_path($torrent_name);
	
			if (!$torrent_path_return{error}) {
				$torrent_path = $torrent_path_return{torrent_path};	
			} else {
				$content = $torrent_path_return{error};
				return $content;
			}
	
			$content .= "Torrent $torrent_name: \n";
			
			my %add_torrent_return = add_torrent($download_path,$torrent_path,$timing);	
			$content .= $add_torrent_return{info};
	
		}
	}
	
	$content .= "</p>";

	my $filter = "download";	
	
	if ($timing eq "now") {	
		$content = gen_operate_content($content,$filter,"");
	} else {
		$content = gen_add();
	}

	return $content;
}

sub gen_operate_content ($$$) {

	my $alert = shift;
	my $filter = shift;
	my $filter_text = shift;

	$alert = "NOTHING" unless defined($alert);
	$filter_text = "" unless defined($filter_text);

	my $cgi = get_cgi();
	
	my %config = load_config();
	
	my $level = $config{view_mode};


	my $torrent_array = json_load_torrents();

        my @torrents = @$torrent_array;

	my $content = "";

	my $transmission_check = 1;
	my $transmission_error = "";

	my $dl_total = 0;
	my $down_total = 0;
	my $up_total = 0;
	my $torrent_count = 0;
	my $total_requested = 0;
	my $total_downloaded = 0;
	my $total_uploaded = 0;
	my $ids;
	my $ratio = 0;

	my %filters = (
		all => 'All',	
		active => 'Active',
		download => 'Downloading',	
		seed => 'Seeding',	
		pause => 'Paused',	
		error => 'Errored',	
		other => 'Other'
	);

	#Dodgy hack to force a sorted hash
	my @filters_short = ("all","active","download","seed","pause","error","other");
	
	if ($alert ne "NOTHING") {
		$content .= qq!<div id="alertbar">\n!;	
		$content .= "$alert";
		$content .= qq!</div>\n!;
	}

        if ($torrents[0] eq "error") {
		$transmission_check = 0;
		$transmission_error = $torrents[1];
        } 

	$content .= qq!<div id="filterbar">\n!;	
	$content .= qq!|!;

 	foreach my $key(@filters_short) {
                my $value = $filters{$key};
		if ($filter eq $key) {
			$content .= qq!<a class="selected" href="/auto/auto.pl?page=operate&amp;filter=$key">&nbsp;$value </a>|\n!;
		} else {
			$content .= qq!<a class="unselected" href="/auto/auto.pl?page=operate&amp;filter=$key">&nbsp;$value </a>|\n!;	
		}
	}

	$content .= qq!<div id="viewsetbar">\n!;
	
	$content .= qq^<!--Placeholder comment-->^;
	$content .= qq!</div>\n!;
	
	$content .= qq!</div>\n!;	
	
	$content .= qq!<div class="breakerbar_small"></div>\n!;

	if ($transmission_check eq 0) {
		if ($transmission_error =~ m/^500/) {
			$content .= "<h3>Transmission does not appear to be running</h3>\n";
			$content .= qq!To start it click <a href="/auto/auto.pl?page=start_submit">Here</a><br />\n!;
		} else {
			$content .= "<h3>An error has occured with the transmission-daemon</h3>\n";
		 	$content .= qq!The reported error is $transmission_error<br />\n!;
		}	
			
		return $content;
        }

	foreach my $torrent (@torrents) {

		my %torrent_details;
		my @line;

		#$torrent = "BLANK_ENTRY" unless defined($torrent);
		my (%torrent) = %{($torrent)};

		#Define variables for use below
		my $id = $torrent{"id"};
		my $name = $torrent{"name"};
		my $error = $torrent{"error"};
		my $errorString = $torrent{"errorString"};
		my $eta = $torrent{"eta"};
		my $isFinished = $torrent{"isFinished"};
		my $leftUntilDone = $torrent{"leftUntilDone"};
		my $peersGettingFromUs = $torrent{"peersGettingFromUs"};
		my $peersSendingToUs = $torrent{"peersSendingToUs"};
		my $rateDownload = $torrent{"rateDownload"};
		my $rateUpload = $torrent{"rateUpload"};
		my $sizeWhenDone = $torrent{"sizeWhenDone"};
		my $status = $torrent{"status"};
		my $downloadedEver = $torrent{"downloadedEver"};
		my $uploadedEver = $torrent{"uploadedEver"};
		my $uploadRatio = $torrent{"uploadRatio"};

		my $converted_eta = convert_time($eta);

		my $converted_rateDownload = convert_data($rateDownload);
		my $converted_rateUpload = convert_data($rateUpload);
		
		my $converted_sizeWhenDone = convert_data($sizeWhenDone);	

		#Legacy check for older transmission-remote (pre 1.83, likely pre 1.80)
		if ($torrent =~ m/Could.*Connect/ || $torrent =~ m/Couldn\'t\sconnect/ || $torrent =~ m/couldn't\sconnect/) {
			$content .= "<h3>Transmission does not appear to be running</h3>";
			$content .= qq!To start it click <a href="/auto/auto.pl?page=start_submit">Here</a>!;
			next;
		}

		$name =~ s/[^[:ascii:]]+//g;  # get rid of non-ASCII characters 

		# Transmission status codes seem to be semi usable for this, 
		# so far i have found:
		# 0 - Seems to be paused as well (2.42 maybe)
		# 2 - validating
		# 4 - downloading (seems to also contain errored) 
		# 6 - Seems to be seeding as well - Possibly idle?
		# 8 - seems to be seeding
		# 16 - Paused
		# anything else?

		if ($filter eq "download") {
			if ($status != 4) {
				next;
			}
		} elsif ($filter eq "active") {
			if ($peersGettingFromUs == 0 && $peersSendingToUs == 0) {
				next;
			}
		} elsif ($filter eq "other") {
			if ($status != 2) {
				next;
			}
		} elsif ($filter eq "error") {
			if ($error == 0) {
				next;
			}	
		} elsif ($filter eq "seed") {
			if ($status != 8 && $status != 6) {
				next;
			}
		} elsif ($filter eq "pause") {
			if ($status != 16 && $status != 0) {
				next;
			}
		}

		if ($filter_text ne "") {
			if ($name !~ m/$filter_text/i) {
				next;
			}
		}

		$torrent_count++;
	
		my $total_left = 0;

		if ($sizeWhenDone != 0) {
			$total_left = $leftUntilDone / $sizeWhenDone * 100;
		} else {
			$total_left = 100;
		}

		my $downloaded = $sizeWhenDone - $leftUntilDone;

		my $converted_downloaded = convert_data($downloaded);

		my $converted_downloadedEver = convert_data($downloadedEver);
		my $converted_uploadedEver = convert_data($uploadedEver);

		$total_downloaded = $total_downloaded + $downloaded;
		$total_uploaded = $total_uploaded + $uploadedEver;
		$total_requested = $total_requested + $sizeWhenDone;
 
		$total_left = sprintf("%.1f", $total_left);

		my $total = 100-$total_left;
	
		$total = sprintf("%.1f", $total);	

		#-----------TOP BAR PORTION----------------#	
		$content .= qq!<div class="contentbar">\n!;
		$content .= qq!<table class="topcontent"><tr>\n!;

               	if ($total_left != 0) {
			if ($error != 0) {	
				$content .= qq!<td style="width:65%">$id - $name ($total%) <img height="15px" src="images/error.jpg" title="$errorString" alt="$errorString" /></td>\n!;
			} else {
				$content .= qq!<td style="width:65%">$id - $name ($total%)</td>\n!;
			}
		} else {
			if ($error != 0) {	
				$content .= qq!<td style="width:65%">$id - $name <img height="15px" src="images/error.jpg" title="$errorString" alt="$errorString" /></td>\n!;
			} else {
			$content .= qq!<td style="width:65%">$id - $name</td>\n!;
			}
		}
		 
		
		$content .= qq!<td style="width:35%" align="right">!;
		
		if ($status == 16 || $status == 0) {
			$content .= qq!<a class="contentbar" href="/auto/auto.pl?page=pause_submit&amp;id=$id&amp;pause=false&amp;filter=$filter">Resume</a> | !;
		} else {
			$content .= qq!<a class="contentbar" href="/auto/auto.pl?page=pause_submit&amp;id=$id&amp;pause=true&amp;filter=$filter">Pause</a> | !;
		}
		#$content .= qq!<a class="contentbar" href="/auto/auto.pl?page=modify_submit&amp;id=$id">Edit</a> | !;
		$content .= qq!<a class="contentbar" onclick="createOverlay('page=modify_submit&amp;headers=no&amp;id=$id')";>Edit</a> | !;
		#$content .= qq!<a class="contentbar" href="/auto/auto.pl?page=remove_submit&amp;id=$id&amp;filter=$filter">Remove</a></td>\n!;
		$content .= qq!<a class="contentbar" onclick="createOverlay('page=remove_submit&amp;headers=no&amp;id=$id&amp;filter=$filter')";>Remove</a></td>\n!;
		$content .= "</tr></table></div>\n";
                
		
		#-----------PERCENT BAR PORTION------------#
		$content .= qq!<div class="percentbar">\n!;
                

		if ($error != 0) {	
			if ($total != 0) {
                		if ($total eq "100.0") {
					$content .= qq!<div class="error_done_percent" style="width:$total%">&nbsp;</div>\n!;
				} else {
					$content .= qq!<div class="error_pt_done_percent" style="width:$total%">&nbsp;</div>\n!;
				}
                	}
                	if ($total_left != 0) {
                       		$content .= qq!<div class="error_missing_percent" style="width:$total_left%">&nbsp;</div>\n!;
                	}
		} elsif ($status == 16 || $status == 0) {
			if ($total != 0) {
                		if ($total eq "100") {
					$content .= qq!<div class="pause_done_percent" style="width:$total%">&nbsp;</div>\n!;
				} else {
					$content .= qq!<div class="pause_pt_done_percent" style="width:$total%">&nbsp;</div>\n!;
				}
                	}
                	if ($total_left != 0) {
                       		$content .= qq!<div class="pause_missing_percent" style="width:$total_left%">&nbsp;</div>\n!;
                	}
		} else {	
			if ($total != 0) {
                		if ($total eq "100.0") {
					$content .= qq!<div class="done_percent" style="width:$total%">&nbsp;</div>\n!;
				} else {
					$content .= qq!<div class="pt_done_percent" style="width:$total%">&nbsp;</div>\n!;
				}
              		}
                	if ($total_left != 0) {
                       		$content .= qq!<div class="missing_percent" style="width:$total_left%">&nbsp;</div>\n!;
                	}
		}
		$content .= qq!</div>\n!;
	
		#----------BOTTOM SUMMARY PORTION-------------#	
		$content .= qq!<div class="contentbar">\n!;
		$content .= qq!<table class="bottomcontent"><tr>\n!;
	
              	if ($total eq "100.0") {
			$content .= qq!<td style="width:25%">Downloaded: $converted_downloadedEver Uploaded: $converted_uploadedEver</td>\n!;
		} else {
			$content .= qq!<td style="width:25%">Downloaded: $converted_downloaded of $converted_sizeWhenDone</td>\n!;
		}

		$content .= qq!<td style="width:7%"><img height="14px" src="images/arrow_down.jpg" title="Downloaded: $converted_downloadedEver" />$converted_rateDownload</td>\n!;
		$content .= qq!<td style="width:7%"><img height="14px" src="images/arrow_up.jpg" title="Uploaded: $converted_uploadedEver" />$converted_rateUpload</td>\n!;
		if ($eta >= 1) {
			$content .= qq!<td style="width:43%">eta: $converted_eta</td>\n!;
		} else {
			$content .= qq!<td style="width:43%">&nbsp;</td>\n!;
		}
		$content .= qq!<td style="width:4%" align="right"><img height="14px" src="images/seed.png" title="Seeds: Peers we are getting data from" />$peersSendingToUs</td>\n!;
		#$content .= qq!<td style="width:6%" align="right">Seeds: $peersSendingToUs</td>\n!;
		$content .= qq!<td style="width:4%" align="right"><img height="14px" src="images/leech.png" title="Leechers: Peers we are sending data too" />$peersGettingFromUs</td>\n!;
		#$content .= qq!<td style="width:8%" align="right">Leechers: $peersGettingFromUs</td>\n!;
		$content .= qq!<td style="width:10%" align="right">Ratio: $uploadRatio</td>\n!;
		$content .= "</tr></table></div>\n";
		
		$content .= qq!<div class="breakerbar"></div>\n!;

		$up_total = $up_total + $rateUpload;
		$down_total = $down_total + $rateDownload;
		if ($uploadRatio != -1) {
			$ratio = $ratio + $uploadRatio;
		}

		$ids .= "$id,";

	}

	if ($torrent_count == 0) {
		if ($filter_text eq "") {
			if ($filter eq "all") {
				$content .= "Sorry, there are no torrents running right now\n";
			}  elsif ($filter eq "error") {
				$content .= "Nice! There are no ". lc($filters{$filter}) ." torrents right now\n";
			}  else {
				$content .= "Sorry, there are no ". lc($filters{$filter}) ." torrents right now\n";
			}
		} else {
			if ($filter eq "all") {
				$content .= "Sorry, there are no torrents running right now that match $filter_text\n";
			}  elsif ($filter eq "error") {
				$content .= "Nice! There are no ". lc($filters{$filter}) ." torrents right now that match $filter_text\n";
			}  else {
				$content .= "Sorry, there are no ". lc($filters{$filter}) ." torrents right now that match $filter_text\n";
			}
		}
		return $content;
	}

        my $total = 0;

	if ($total_requested == 0) {
		$total = "0";
	} else {
		$total = $total_downloaded / $total_requested * 100;
	}

	my $ratio_avg = $ratio / $torrent_count;

	$ratio_avg = sprintf("%.2f", $ratio_avg);
	$dl_total = sprintf("%.2f", $dl_total);
	$total = sprintf("%.0f", $total);

        $total =~ s/\%//g;
	
	my $converted_down_total = convert_data($down_total);
	my $converted_up_total = convert_data($up_total);

	my $converted_total_downloaded = convert_data($total_downloaded);
	my $converted_total_uploaded = convert_data($total_uploaded);
	my $converted_total_requested = convert_data($total_requested);

        my $total_left = 100-$total;

                #-----------TOP BAR PORTION----------------#
                $content .= qq!<div class="contentbar">\n!;
                $content .= qq!<table class="topcontent"><tr>\n!;

                $content .= qq!<td style="width:65%">Summary</td>\n!;

                $content .= qq!<td style="width:35%" align="right">!;

                $content .= qq!<a class="contentbar" href="/auto/auto.pl?page=pause_submit&amp;id=$ids&amp;pause=true&amp;filter=$filter">Pause all</a> | !;
                $content .= qq!<a class="contentbar" href="/auto/auto.pl?page=pause_submit&amp;id=$ids&amp;pause=false&amp;filter=$filter">Resume all</a> | !;
                $content .= qq!<a class="contentbar" href="/auto/auto.pl?page=remove_submit&amp;id=$ids&amp;filter=$filter">Remove all</a></td>\n!;
                $content .= "</tr></table></div>\n";


                #-----------PERCENT BAR PORTION------------#
                $content .= qq!<div class="percentbar">\n!;

                if ($total != 0) {
                        if ($total eq "100") {
                                $content .= qq!<div class="done_percent" style="width:$total%">&nbsp;</div>\n!;
			} else {
                                $content .= qq!<div class="pt_done_percent" style="width:$total%">&nbsp;</div>\n!;
                        }
                }
                if ($total_left != 0) {
                        $content .= qq!<div class="missing_percent" style="width:$total_left%">&nbsp;</div>\n!;
                }
                $content .= qq!</div>\n!;

                #----------BOTTOM SUMMARY PORTION-------------#
                $content .= qq!<div class="contentbar">\n!;
                $content .= qq!<table class="bottomcontent"><tr>\n!;

                $content .= qq!<td style="width:25%">Downloaded: $converted_total_downloaded of $converted_total_requested</td>\n!;
		$content .= qq!<td style="width:7%"><img height="14px" src="images/arrow_down.jpg" title="Downloaded: $converted_total_downloaded" />$converted_down_total</td>\n!;
		$content .= qq!<td style="width:7%"><img height="14px" src="images/arrow_up.jpg" title="Uploaded: $converted_total_uploaded" />$converted_up_total</td>\n!;
                $content .= qq!<td style="width:43%">&nbsp;</td>\n!;
                $content .= qq!<td style="width:18%" align="right">Avg Ratio: $ratio_avg</td>\n!;
                $content .= "</tr></table></div>\n";

                if ($filter eq "all" || $filter eq "seed") {
			 $content .= qq!<tr><td colspan="5"><div class="breakerbar"></div></td></tr>\n!;
			 $content .= qq!<tr><td><a href="#top"><input type="button" name="Back to Top" value="Back to Top"></a></td></tr>\n!;
			 $content .= "</table>\n";
		} else {
			 $content .= "</table>\n";
			 $content .= qq!<div class="breakerbar"></div>\n!;
		}
	$content .= "\n";
	return $content;
}

sub gen_operate ($) {

        my $alert = shift;
	my $content = "";

        my $cgi = get_cgi();
        my $filter = $cgi->param("filter");
        my $filter_text = $cgi->param("filter_text");

        $alert = "NOTHING" unless defined($alert);
        $filter = "active" unless defined($filter);
        $filter_text = "" unless defined($filter_text);
	
	$filter = clean_data($filter);

	$content = qq!<script type="text/javascript">

//-----------------------------------------------------------

function getAjaxVar() {

  var ajaxRequest;

  try {

    // Opera 8.0+, Firefox, Safari

    ajaxRequest = new XMLHttpRequest();

  }

  catch (e) {

    // Internet Explorer Browsers

    try {

      ajaxRequest = new ActiveXObject("Msxml2.XMLHTTP");

    }

    catch (e) {

      try {

        ajaxRequest = new ActiveXObject("Microsoft.XMLHTTP");

      }

      catch (e) {

        // Something went wrong

        alert("Your browser broke");

        return false;

      }

    }

  }

  return ajaxRequest;

}

//-----------------------------------------------------------

function refresh_timer() {
  //load_data();!;

	if ($filter eq "active" || $filter eq "download" || $filter eq "other") {
		$content.= qq!
  setInterval ( "load_data()", 2000);!;

	} else {
		$content.= qq!
  setInterval ( "load_data()", 5000);!;
	}

	$content .= qq!
}

//-----------------------------------------------------------
function load_data() {

  var ajaxRequest = getAjaxVar();
  var url = "auto.pl";
  var filterText = document.getElementById("filter_text").value;
  var params = "page=operate&headers=no!;

$content .= qq!&filter=$filter!;
$content .= qq!&filter_text=" + filterText +!;

$content .= qq!"&dummy=" + new Date().getTime();

  ajaxRequest.onreadystatechange = function() {

    if(ajaxRequest.readyState == 4 && ajaxRequest.status == 200) {

      //alert(ajaxRequest.responseText);

	var outputText = ajaxRequest.responseText;

	var divContainer = document.getElementById("container");
	divContainer.innerHTML = outputText;
    }

  }

  ajaxRequest.open("GET", url + "?" + params, true);

  ajaxRequest.send(null);

}
//-----------------------------------------------------------

function createOverlay(pageToLoad) {

   var ajaxRequest = getAjaxVar();

   var container = document.getElementById("container");
   var pageHeight = Math.max((container.clientHeight + 100), window.innerHeight || 0);

   var overlay = document.createElement("div");
   overlay.setAttribute("id","overlay");
   overlay.setAttribute("class", "overlay");
   overlay.onclick = restore;
   overlay.setAttribute("style","height:" + pageHeight + "px");
   overlay.style.height = pageHeight;
   document.body.appendChild(overlay);

   var overlayHTML = document.createElement("div");
   overlayHTML.setAttribute("id","overlayHTML");
   overlayHTML.setAttribute("class", "overlayHTML");
   overlayHTML.innerHTML = "please wait while the data loads";

   document.body.appendChild(overlayHTML);
   var url = "auto.pl";

   ajaxRequest.onreadystatechange = function() {

    if(ajaxRequest.readyState == 4 && ajaxRequest.status == 200) {

      //alert(ajaxRequest.responseText);

	var outputText = ajaxRequest.responseText;

	var overlayHTML = document.getElementById("overlayHTML");
	overlayHTML.innerHTML = outputText;

	CollapsibleLists.apply(); 

	if (pageToLoad.indexOf("modify") >= 0) {
		var list = document.getElementById("list");
		var listHeight = overlayHTML.clientHeight - 225;
   		list.setAttribute("style","height:" + listHeight + "px");
   		overlay.style.height = listHeight;
	}
    }

  }

  ajaxRequest.open("GET", url + "?" + pageToLoad, true);

  ajaxRequest.send(null);
  

}
//----------------------------------------------------------

function restore() {

 document.body.removeChild(document.getElementById("overlay"));
 document.body.removeChild(document.getElementById("overlayHTML"));
}

 
//-----------------------------------------------------------

function filter_text(filterText) {
  var ajaxRequest = getAjaxVar();
  var url = "auto.pl";
  var params = "page=operate&headers=no!;

$content .= qq!&filter=$filter!;
$content .= qq!&filter_text=" + filterText +!;

$content .= qq!"&dummy=" + new Date().getTime();

  ajaxRequest.onreadystatechange = function() {

    if(ajaxRequest.readyState == 4 && ajaxRequest.status == 200) {

      //alert(ajaxRequest.responseText);

	var outputText = ajaxRequest.responseText;

	var divContainer = document.getElementById("container");
	divContainer.innerHTML = outputText;
    }

  }

  ajaxRequest.open("GET", url + "?" + params, true);

  ajaxRequest.send(null);

  //alert("text entered is " + filterText);
}
//-----------------------------------------------------------
</script>!;

	$content .= gen_operate_content($alert,$filter,$filter_text);

	return $content;
}

sub gen_honour_submit () {
	my $cgi = get_cgi();
	
	my $id = $cgi->param("id");
	my $honour = $cgi->param("honour");
	
	my $content = "";	

	#Remove an error star if present in ID field
	$id =~ s/\*//g;
	
	$content = honour_torrent($id,$honour);

	$content = gen_operate($content);

	return $content;
}

sub gen_pause_submit () {
	my $cgi = get_cgi();
	
	my $id = $cgi->param("id");
	my $pause = $cgi->param("pause");
	
	my $content = "";
	my $count = 0;	

	#Remove an error star if present in ID field
	$id =~ s/\*//g;
	
	my (%results) = %{(json_pause_torrent($id,$pause))};

	if ($results{"result"} eq "success") {
		if ($id =~ m/,/) {
			$id =~ s/,$//;
			$content = "torrents $id ";
		} else {
			$content = "torrent $id ";
		}
			
		if ($pause eq "true") {
			$content .= "paused\n";	
		} else {
			$content .= "resumed\n";	
		}
	} else {
		$content .= "sorry an error has occured\n";
	}

	$content = gen_operate($content);

	return $content;
}

sub gen_modify_submit () {
	my $cgi = get_cgi();
	my $id = $cgi->param("id");
	
	my $content = "";	

	my $raw_info = get_torrent_info($id);
	my %torrent_info = parse_torrent_info($raw_info);

	my $torrent_name = "errored";	
	$torrent_name = $torrent_info{name} if defined($torrent_info{name});

	my $torrent_files = get_torrent_files($id);

	# Ensure there are no errors in the file JSON call
        my $transmission_check = 1;
        my $transmission_error = "";

        my @torrents = @$torrent_files;

	
        if ($torrents[0] eq "error") {
                $transmission_error = $torrents[1];

                if ($transmission_error =~ m/^500/) {
                        $content .= "<h3>Transmission does not appear to be running</h3>\n";
                        $content .= qq!To start it click <a href="/auto/auto.pl?page=start_submit">Here</a><br />\n!;
                } else {
                        $content .= "<h3>An error has occured with the transmission-daemon</h3>\n";
                        $content .= qq!The reported error is $transmission_error<br />\n!;
                }

                return $content;
        }

	my $files_html = parse_torrent_files($id,$torrent_files,$torrent_name);

	$content .= "<h1>$torrent_info{name}</h1>\n";
	$content .= $torrent_info{have_size}."/".$torrent_info{total_size}." ($torrent_info{wanted_size} wanted, $torrent_info{verified_size} verified)<br />\n";
	$content .= $torrent_info{honours}."<br />\n";

	$content .= "<h3>Torrent Files</h3>\n";
	$content .= $files_html;

	return $content;
}

sub gen_remove_submit () {
	my $cgi = get_cgi();
	
	my $id = $cgi->param("id");
	my $confirm = $cgi->param("confirm");
	my $filter = $cgi->param("filter");
	my $filter_text = $cgi->param("filter_text");

	my $content = "";	
	my $errors = "";	
	my $count = 0;
	my $total_torrents;
	my $running_hash;
	my %torrent_file_return;
	my %config = load_config();
	
	$confirm = "no" unless defined($confirm);
	$filter_text = "" unless defined($filter_text);

	#Remove an error star if present in ID field
	$id =~ s/\*//g;

	my @ids;

	if ($id !~ m/,/) {
		$running_hash = get_running_hash($id);
		%torrent_file_return = get_db_entry($running_hash);
		@ids = $id;
	} else {
		# Multiples found
		@ids = split(/,/,$id);
	}
		
	$total_torrents = @ids;

	if ($confirm ne "yes") {
		#$content = qq!<div id="alertbar">!;
		$content .= "<h1>Delete confirmation</h1>\n";
		$content .= "<h2>You are about to remove:</h2>\n";

		if ($total_torrents == 1) {
			$content .= "<h3>$torrent_file_return{torrent}</h3>\n";
			$content .= "<h3>ID $id in Transmission</h3>\n";
		} else {
			$content .= "<h3>Multiple Items ($total_torrents torrents)</h3>\n";
		}

		$content .= "<h2>From the <strong>Database</strong> and <strong>Transmission</strong></h2>\n";
		if ($config{remove_data} eq "on") {
			$content .= "<h2>The data at the following location will also be deleted</h2>\n";
			$content .= "<h3>$config{rss_down_loc}</h3>\n";
		}
		$content .= "<h2>Are you sure you wish to do this?</h2>\n";
		$content .= qq!<p><a href="/auto/auto.pl?page=remove_submit&id=$id&confirm=yes&filter=$filter&filter_text=$filter_text"><em>Click here to confirm this deletion</em></a></p>\n!;
		$content .= "<h3>OR</h3>\n";
		$content .= qq!<p><a href="/auto/auto.pl?page=operate"><em>Return to Operate page</em></a></p>\n!;
		#$content .= "</div>\n";
		
		return $content;
	}
	
	foreach my $single_id (@ids) {
		$running_hash = get_running_hash($single_id);
		%torrent_file_return = get_db_entry($running_hash);
        	
		if (!$torrent_file_return{error}) {
      #Run the remove and delete code here 
      $content .= db_delete_running_entry($torrent_file_return{torrent});
			$content .= "<br />\n";
			$content .= remove_torrent($single_id);
			$content .= "<br />\n";
			$count++;
		} else {
                	$errors = $torrent_file_return{error};
		}
	}
	
	if ($count >= 2) {
		$content = "Removed $count torrents from transmission<br />\n";
	}

	$content .= $errors;

	$content = gen_operate($content);
	
	return $content;
}

sub gen_start_submit () {
	my $cgi = get_cgi();
	
	my $content = "";
	
	$content = "<h3>Starting Transmission</h3>";
	$content .= "<p>Transmission is starting up, it should start up quickly, but may take a while to load";
	$content .= " all the torrents from the database.<br />Please be patient, you should be able to see them popping up";
	$content .= " on the operate page within a few seconds</p><br />\n";

	my $ignored_content = cli_start_transmission();
	
	#Commented out as transmission directory should handle this now	
	#system("/var/www/html/auto/auto.pl cli load_database > /dev/null 2>&1 &");
	
	return $content; 	
}

sub gen_rcontrol () {
	my $content = "";

	my %shows = load_rss_shows();

	#$content = "RSS Shows found in DB<br />\n";
	
	my $alert = load_my_eps_today();
	if ($alert ne 'failed') {
		$content .= qq!<div id="alertbar">\n!;
  	$content .= "$alert";
  	$content .= qq!</div>\n!;
	}

	$content .= qq!<div id="rss">!;
	$content .= qq!<form action="$ENV{SCRIPT_NAME}" method="post">\n!;
	$content .= qq!<input type="hidden" name="page" value ="rcontrol_add_submit" />!;
	$content .= "<table rules=\"rows\">";
	$content .= "<tr>\n<td>&nbsp;</td>\n";
	$content .= "<td><h3>Show</h3></td>\n";
	$content .= "<td><h3>Inclusion Values</h3></td>\n";
	$content .= "<td><h3>Exclusion Values</h3></td>\n</tr>\n";
	foreach my $key ( sort { $a cmp $b } keys %shows ) {
        	my $value = $shows{$key};
		my @inc_exc_values = split(/&/,$value);
		my $include = $inc_exc_values[0];
		my $exclude = $inc_exc_values[1];
	
		$include = "" unless defined($include);
		$exclude = "" unless defined($exclude);
        
		$content .= qq!<tr>\n!;	
		$content .= qq!<td width="10%"><input type="button" name="Remove" value="Remove" onclick="location.href = '/auto/auto.pl?page=rcontrol_remove_submit&amp;show=$key'" /></td>\n!;
		$content .= qq!<td>$key</td>\n!;
		$content .= qq!<td>$include</td>\n!;
		$content .= qq!<td>$exclude</td>\n!;
		$content .= qq!</tr>\n!;
    	}
	$content .= qq!<tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>\n!;
	$content .= qq!<tr>\n!;
	$content .= qq!<td><input type="submit" value="Add new show" /></td>\n!;
	$content .= qq!<td><input type="text" size="30" maxlength="40" name="name" /></td>\n!;
	$content .= qq!<td><input type="text" size="20" maxlength="40" name="inclusions" /></td>\n!;
	$content .= qq!<td><input type="text" size="20" maxlength="40" name="exclusions" /></td>\n!;
	$content .= qq!</tr>\n!;
	$content .= "</table>\n";
	$content .= "</form>\n";
	$content .= "</div>\n";
	
	return $content;
}

sub gen_rcontrol_add_submit () {
	my $cgi = get_cgi();
	
	my $show = $cgi->param("name");
	my $inclusions = $cgi->param("inclusions");
	my $exclusions = $cgi->param("exclusions");

	$inclusions = "" unless defined($inclusions);
	$exclusions = "" unless defined($exclusions);

	my $content = "";

	$content = gen_rcontrol();

	if ($show ne "") {
		my %db_add_rss_show_return = db_add_rss_show($show,$inclusions,$exclusions);	
	}

	return $content;
}

sub gen_rcontrol_remove_submit () {
	my $cgi = get_cgi();
	
	my $show = $cgi->param("show");
	my $confirm = $cgi->param("confirm");

	$confirm = "no" unless defined($confirm);
	
	my $content = "";	

	if ($confirm ne "yes") {
		$content = qq!<div id="alertbar">!;
		$content .= "<h1>Delete confirmation</h1>\n";
		$content .= "<h2>You are about to remove:</h2>\n";
		$content .= "<h2><em>$show</em></h2>\n";
		$content .= "<h2>From the <strong>RSS Database</strong></h2>\n";
		$content .= "<h3>Are you sure you wish to do this?</h3>\n";
		$content .= qq!<p><a href="/auto/auto.pl?page=rcontrol_remove_submit&show=$show&confirm=yes"><em>Click here to confirm this deletion</em></a></p>\n!;
		$content .= "<h3>OR</h3>\n";
		$content .= qq!<p><a href="/auto/auto.pl?page=rcontrol"><em>Return to RSS Control</em></a></p>\n!;
		$content .= "</div>\n";
		
		return $content;
	}
	
        #Run the remove and delete code here 
        $content .= db_delete_rss_entry($show);
	
	#$content = "Deleting from Database<br />\n";
	#$content .= "<br />\n";
	
	$content = gen_rcontrol();
	
	return $content;
}

sub gen_mcontrol () {
	my $content = "";
	my %config = load_config();
	my %movies = load_rss_movies();
	my $entry_ref=1;
	#$content = "RSS movies found in DB<br />\n";

	$content .= qq!<div id="alertbar">\n!;
	$content .= "<h3>Movie RSS List</h3>\n";
  	$content .= "<p>The following list monitors your movie rss feed.  If a match is found an email is sent and the entry is removed.<br />\n";
	$content .= "The match isnt automatically downloaded, it is up to the user to act on the notification.</p>\n";
	$content .= "<p><em>Note: For IMDB lookup to work the year must be the first of the comma delimited inclusions.</em></p>\n";
  	$content .= qq!</div>\n!;
	$content .= qq!<form action="$ENV{SCRIPT_NAME}" method="post">\n!;
	$content .= qq!<input type="hidden" name="page" value ="mcontrol_add_submit" />!;
	$content .= qq!<div id="rss">!;
	 
	$content .= "<table rules=\"rows\">";
	$content .= "<tr>\n<td>&nbsp;</td>\n";
	$content .= "<td><h3>Movie</h3></td>\n";
	$content .= "<td><h3>Inclusion Values</h3></td>\n";
	$content .= "<td><h3>Exclusion Values</h3></td>\n</tr>\n";
	foreach my $key ( sort { $a cmp $b } keys %movies ) {
        my $value = $movies{$key};
		my @inc_exc_values = split(/&/,$value);
		my $include = $inc_exc_values[0];
		my $exclude = $inc_exc_values[1];
		my $imdb_code = $inc_exc_values[2];
		my $dvd_release_date = $inc_exc_values[3];
		my $theater_release_date = $inc_exc_values[4];
	
		$include = "" unless defined($include);
		$exclude = "" unless defined($exclude);
		$imdb_code = "" unless defined($imdb_code);
		$dvd_release_date = "" unless defined($dvd_release_date);
		$theater_release_date = "" unless defined($theater_release_date);
		
		$content .= qq!<tr>\n!;	
		$content .= qq!<td width="10%"><a href="/auto/auto.pl?page=mcontrol_remove_submit&movie=$key"><input type="button" name="Remove" value="Remove"></a></td>\n!;
		if ($imdb_code eq "NA") {
			if ( $dvd_release_date eq 'NA' && $theater_release_date eq 'NA' ) {
				$content .= qq!<td>$key</td>\n!;
			} else {
				$content .= qq!<td><div onClick="openClose($entry_ref)" style="cursor:hand; cursor:pointer"><b>$key</b></div>
				<div id="$entry_ref" class="texter">Expected Release Dates<br />
				Theater: $theater_release_date<br />
				Retail: $dvd_release_date<br /><br />
				</div></td>\n!;
			}
			$entry_ref++;
		}
		else {
			if ( $dvd_release_date eq 'NA' && $theater_release_date eq 'NA' ) {
				$content .= qq!<td><a href=$config{imdb_link}$imdb_code>$key</a></td>\n!;
			} else {
			$content .= qq!<td><div onClick="openClose($entry_ref)" style="cursor:hand; cursor:pointer"><b>$key</b></div>
			<div id="$entry_ref" class="texter"><a href=$config{imdb_link}$imdb_code>IMDB Info</a><br />Expected Release Dates<br />
			Theater: $theater_release_date<br />
			Retail: $dvd_release_date<br /><br />
			</div></td>\n!;
			}
			$entry_ref++;
		}
		$content .= qq!<td>$include</td>\n!;
		$content .= qq!<td>$exclude</td>\n!;
		$content .= qq!</tr>\n!;
    	}

	$content .= qq!<tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>\n!;
	$content .= qq!<tr>\n!;
	$content .= qq!<td><input type="submit" value="Add new movie" /></td>\n!;
	$content .= qq!<td><input type="text" size="20" maxlength="40" name="name" /></td>\n!;
	$content .= qq!<td><input type="text" size="20" maxlength="40" name="inclusions" /></td>\n!;
	$content .= qq!<td><input type="text" size="20" maxlength="40" name="exclusions" /></td>\n!;
	$content .= qq!</tr>\n!;
	$content .= "</table>\n";
	$content .= "</form>\n";
	$content .= "</div>\n";
	
	# call my episodes rss module to get todays movies
	#$content .= myep_today_rss();
	
	return $content;
}

sub gen_mcontrol_add_submit () {
	my $cgi = get_cgi();
	
	my $movie = $cgi->param("name");
	my $inclusions = $cgi->param("inclusions");
	my $exclusions = $cgi->param("exclusions");

	$inclusions = "" unless defined($inclusions);
	$exclusions = "" unless defined($exclusions);

	my $content = "";

	$content = gen_mcontrol();

	if ($movie ne "") {
		my %db_add_rss_movie_return = db_add_rss_movie($movie,$inclusions,$exclusions);	
	}

	return $content;
}

sub gen_mcontrol_remove_submit () {
	my $cgi = get_cgi();
	
	my $movie = $cgi->param("movie");
	my $confirm = $cgi->param("confirm");

	$confirm = "no" unless defined($confirm);
	
	my $content = "";	

	if ($confirm ne "yes") {
		$content = qq!<div id="alertbar">!;
		$content .= "<h1>Delete confirmation</h1>\n";
		$content .= "<h2>You are about to remove:</h2>\n";
		$content .= "<h2><em>$movie</em></h2>\n";
		$content .= "<h2>From the <strong>Movie RSS Database</strong></h2>\n";
		$content .= "<h3>Are you sure you wish to do this?</h3>\n";
		$content .= qq!<p><a href="/auto/auto.pl?page=mcontrol_remove_submit&movie=$movie&confirm=yes"><em>Click here to confirm this deletion</em></a></p>\n!;
		$content .= "<h3>OR</h3>\n";
		$content .= qq!<p><a href="/auto/auto.pl?page=mcontrol"><em>Return to Movie RSS Control</em></a></p>\n!;
		$content .= "</div>\n";
		
		return $content;
	}
	
        #Run the remove and delete code here 
        $content .= db_delete_rss_movie_entry($movie);
	
	#$content = "Deleting from Database<br />\n";
	#$content .= "<br />\n";
	
	$content = gen_mcontrol();
	
	return $content;
}
	
sub gen_category () {
	my $content = "";

	my %categories = load_categories();
	
	#$content = "Categories found in DB<br />\n";
	$content .= qq!<div id="cat">!;
	$content .= qq!<form action="$ENV{SCRIPT_NAME}" method="post">\n!;
	$content .= qq!<input type="hidden" name="page" value ="category_add_submit" />!;
	
	$content .= "<table>\n";
	$content .= "<tr>\n<td>&nbsp;</td><td><h3>Category</h3></td>\n<td><h3>Directory Location</h3></td><td width=\"300\">Advanced Sorting</td>\n</tr>\n";
	foreach my $key ( sort { $a cmp $b } keys %categories ) {
        	my $value = $categories{$key};
       		my @value = split(/,/,$value); 
		$content .= qq!<tr>\n!;
		$content .= qq!<td width="10%"><a href="/auto/auto.pl?page=category_remove_submit&category=$key"><input type="button" name="Remove" value="Remove"></a></td>\n!;
		$content .= qq!<td>$key</td>\n!;
		$content .= qq!<td>$value[0]</td>\n!;
		$content .= qq!<td>$value[1]</td>\n!;
		$content .= qq!</tr>\n!;
  }
	$content .= qq!<tr>\n!;
	$content .= qq!<td><input type="submit" value="Add new category" /></td>\n!;
	$content .= qq!<td><input type="text" size="20" maxlength="20" name="category" /></td>\n!;
	$content .= qq!<td><input type="text" size="30" maxlength="90" name="location" /></td>\n!;
	$content .= qq!<td><input type="checkbox" name="sorting" /></td>\n!;
	$content .= qq!</tr>\n!;
	$content .= "</table>\n";
	$content .= "</form>\n";
	$content .= "</div>\n";
	
	return $content;
}

sub gen_category_add_submit () {
	my $cgi = get_cgi();
	
	my $category = $cgi->param("category");
	my $location = $cgi->param("location");
	my $sorting = $cgi->param("sorting");

	my $content = "";

	$location =~ s/\/$//;

	my %db_add_category_return = db_add_category($category,$location,$sorting);	
	$content = $db_add_category_return{info};

	return $content;
}

sub gen_category_remove_submit () {
	my $cgi = get_cgi();
	
	my $category = $cgi->param("category");
	my $confirm = $cgi->param("confirm");

	$confirm = "no" unless defined($confirm);
	
	my $content = "";	

	if ($confirm ne "yes") {
		$content = "<h1>Delete confirmation</h1>\n";
		$content .= "<h2>Are you about to remove:</h2>\n";
		$content .= "<h3>$category</h3>\n";
		$content .= "<h2>From the <strong>Database</strong></h2>\n";
		$content .= "<h3>Are you sure you wish to do this?</h3>\n";
		$content .= qq!<p><a href="/auto/auto.pl?page=category_remove_submit&category=$category&confirm=yes"><em>Click here to confirm this deletion</em></a></p>\n!;
		
		return $content;
	}
	
        #Run the remove and delete code here 
	$content = "Deleting from Database<br />\n";
        $content .= db_delete_category($category);
	$content .= "<br />\n";
}

sub gen_queue_list () {
	my $content = "";

	my %on_peak_queue = load_on_peak_queue();
	my %off_peak_queue = load_off_peak_queue();
	
	my %config = load_config();
	my $on_peak_start = $config{on_peak_start};
	my $off_peak_start = $config{off_peak_start};
	
	$content .= qq!<div id="add">!;
	$content .= qq!<form action="$ENV{SCRIPT_NAME}" method="post">\n!;
	$content .= qq!<input type="hidden" name="page" value ="queue_add_submit" />!;
	if ((%on_peak_queue) || (%off_peak_queue)) {
		$content .= "<fieldset>\n<legend>Queued Torrent List</legend>\n";
		$content .= "<table>\n";
		
		if (%on_peak_queue) {
			$content .= "<tr>\n<td>&nbsp;</td><td><strong>On Peak Torrent (scheduled for $on_peak_start hours)</strong></td>\n<td><strong>Download Location</strong></td></tr>\n";
			foreach my $key ( sort { $a cmp $b } keys %on_peak_queue ) {
					my $value = $on_peak_queue{$key};
					my @value = split(/,/,$value); 
				$content .= qq!<tr>\n!;
				$content .= qq!<td width="10%"><input type="button" name="Remove" value="Remove" onclick="location.href='/auto/auto.pl?page=queue_remove_submit&on_peak_queue_torrent=$key'" /></td>\n!;
				if ($key =~ m/\/.*\/(\w.*)\.torrent$/ig) {
					$content .= qq!<td>$1</td>\n!;
				}
				$content .= qq!<td>$value[0]</td>\n!;
				$content .= qq!</tr>\n!;
			}
			$content .= qq!<tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>\n!;
		}
		if (%off_peak_queue) {
			$content .= "<tr>\n<td>&nbsp;</td><td><strong>Off Peak Torrent (scheduled for $off_peak_start hours)</strong></td>\n<td><strong>Download Location</strong></td></tr>\n";
			foreach my $key ( sort { $a cmp $b } keys %off_peak_queue ) {
					my $value = $off_peak_queue{$key};
					my @value = split(/,/,$value); 
				$content .= qq!<tr>\n!;
				$content .= qq!<td width="10%"><input type="button" name="Remove" value="Remove" onclick="location.href='/auto/auto.pl?page=queue_remove_submit&off_peak_queue_torrent=$key'" /></td>\n!;
				if ($key =~ m/\/.*\/(\w.*)\.torrent$/ig) {
					$content .= qq!<td>$1</td>\n!;
				}
				$content .= qq!<td>$value[0]</td>\n!;
				$content .= qq!</tr>\n!;
			}
		}
		$content .= "</table>\n";
		$content .= "</fieldset>\n";
	}
	$content .= "</form>\n";
	$content .= "</div>\n";
	
	return $content;
}

sub gen_queue_remove_submit () {
	my $cgi = get_cgi();
	
	my $on_peak_queue_torrent = $cgi->param("on_peak_queue_torrent");
	my $off_peak_queue_torrent = $cgi->param("off_peak_queue_torrent");
	my $confirm = $cgi->param("confirm");

	$confirm = "no" unless defined($confirm);
	
	my $content = "";	
	
	if ($on_peak_queue_torrent) {
		if ($confirm ne "yes") {
			$content = "<h2>Delete confirmation</h2>\n";
			$content .= "<h3>You are about to remove:</h3>\n";
			$content .= "<h3>$on_peak_queue_torrent</h3>\n";
			$content .= "<h3>From the <strong>Database</strong></h3>\n";
			$content .= "<h3>Are you sure you wish to do this?</h3>\n";
			$content .= qq!<p><a href="/auto/auto.pl?page=queue_remove_submit&on_peak_queue_torrent=$on_peak_queue_torrent&confirm=yes"><em>Click here to confirm this deletion</em></a></p>\n!;
			return $content;
		}
		#Run the remove and delete code here 
		$content = qq^<div id="alertbar">Deleted from Database:<br />\n^;
		$content .= db_delete_on_peak_queue($on_peak_queue_torrent);
		$content .= "</div>\n";
		$content .= gen_add();
	}
	elsif ($off_peak_queue_torrent) {
		if ($confirm ne "yes") {
				$content = "<h2>Delete confirmation</h2>\n";
				$content .= "<h3>You are about to remove:</h3>\n";
				$content .= "<h3>$off_peak_queue_torrent</h3>\n";
				$content .= "<h3>From the <strong>Database</strong></h3>\n";
				$content .= "<h3>Are you sure you wish to do this?</h3>\n";
				$content .= qq!<p><a href="/auto/auto.pl?page=queue_remove_submit&off_peak_queue_torrent=$off_peak_queue_torrent&confirm=yes"><em>Click here to confirm this deletion</em></a></p>\n!;
				return $content;
		}
		#Run the remove and delete code here 
		$content = qq^<div id="alertbar">Deleted from Database:<br />\n^;
		$content .= db_delete_off_peak_queue($off_peak_queue_torrent);
		$content .= "</div>\n";
		$content .= gen_add();
	}
}
	
sub gen_options () {
	
	my @options_short = ("daemon_loc","remote_loc","remote_user","remote_pass","torrent_loc","email_addr","rss_loc","movie_rss_loc","rss_down_loc","rss_state","rss_sorting","rss_ratio","rss_time","transmission_port","global_ratio","remove_data","last_active","seed_time","on_peak_start","on_peak_up_speed_kb","on_peak_down_speed_kb","off_peak_start","off_peak_up_speed_kb","off_peak_down_speed_kb");
	
	my %options = (
		daemon_loc => 'Daemon Location',
		remote_loc => 'Remote Location',
		remote_user => 'Remote Username',
		remote_pass => 'Remote Password',
		torrent_loc => 'Torrent Location',
		email_addr => 'Email Addresses',
		rss_loc => 'RSS Source Location',
		movie_rss_loc => 'Movie RSS Location',
		rss_down_loc => 'RSS Download Location',
		rss_state => 'RSS Automatic Downloads',
		rss_sorting => 'RSS Folder Sorting',
		rss_ratio => 'RSS Ratio Limit',
		rss_time => 'RSS Refresh Timer',
		transmission_port => 'Transmission Port',
		global_ratio => 'Global Ratio Limit',
		remove_data => 'Remove Data',
		last_active => 'Auto Delete - Since Last Activity',
		seed_time => 'Auto Delete - To Seed For',
		on_peak_start => 'On-Peak Start Time',
		on_peak_up_speed_kb => 'On-Peak Upload Speed Limit',
		on_peak_down_speed_kb => 'On-Peak Download Speed Limit',
		off_peak_start => 'Off-Peak Start Time',
		off_peak_up_speed_kb => 'Off-Peak Upload Speed Limit',
		off_peak_down_speed_kb => 'Off-Peak Download Speed Limit'
	);
	
	my $count = 0;
	my $content = "";
	my %config = load_config();
	
	$content .= qq!<div id="conf_table">\n!;	
	$content .= qq!<form action="$ENV{SCRIPT_NAME}" method="post"><p>\n!;
	$content .= qq!<input type="hidden" name="page" value ="options_submit" /></p>!;
	
	foreach my $key ( @options_short ) {
        	my $value = $config{$key};
        	
		if ($count == 0) {
			$content .= "<fieldset>\n<legend>File Location Options</legend>\n";
			$content .= "<table>\n";
			
		}
		if ($count == 5) {
			$content .= "</table>\n";
			$content .= "</fieldset>\n<p> </p><fieldset>\n<legend>RSS Options</legend>\n";
			$content .= "<table>\n";
		}
		if ($count == 13) {
			$content .= "</table>\n";
			$content .= "</fieldset>\n<p> </p><fieldset>\n<legend>Transmission Options</legend>\n";
			$content .= "<table>\n";
		}
		if ($count == 18) {
			$content .= "</table>\n";
			$content .= "</fieldset>\n<p> </p><fieldset>\n<legend>On-Peak Options</legend>\n";
			$content .= "<table>\n";
		}
		if ($count == 21) {
			$content .= "</table>\n";
			$content .= "</fieldset>\n<p> </p><fieldset>\n<legend>Off-Peak Options</legend>\n";
			$content .= "<table>\n";
		}
		
		#Check if its the binary locations, if so increase field size
		if ($options{$key} =~ m/Email/ || $options{$key} =~ m/RSS Source/ || $options{$key} =~ m/Movie RSS/ || $options{$key} =~ m/Tvrage RSS/ || $options{$key} =~ m/API Key/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td><input type="text" size="50" name="$key" value="$value" /></td></tr>\n!;
		} elsif ($options{$key} =~ m/Location/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td><input type="text" size="35" name="$key" value="$value" /></td></tr>\n!;
		} elsif ($options{$key} =~ m/Username/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td width="50"><input type="text" size="15" name="$key" value="$value" /></td><td rowspan="2"> (Leave blank if no authentication set for Transmission Remote)</td></tr>\n!;
		} elsif ($options{$key} =~ m/Password/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td width="50"><input type="password" size="15" name="$key" value="$value" /></td></tr>\n!;
		} elsif ($options{$key} =~ m/Remove Data/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td>On<input type="radio" name="$key" value="on" !; 
			if ($value eq "on") {
				$content .= qq!checked ="checked"!;
			}
			$content .= qq!/>&nbsp;Off<input type="radio" name="$key" value="off" !;
			if ($value eq "off") {
				$content .= qq!checked ="checked"!;
			}
			$content .= qq!/>&nbsp;&nbsp;&nbsp;(If <strong>OFF</strong>, data retained, <strong>ONLY</strong> torrent removed from client)</td></tr>\n!;
		} elsif ($options{$key} =~ m/Auto Delete/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td><input type="text" size="5" name="$key" value="$value" /> Days</td></tr>\n!;
		} elsif ($options{$key} =~ m/RSS Refresh/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td><select name="$key"><option value="5" !;
			if ($value eq "5") {
				$content .= qq!selected="yes"!;
			}
			$content .= qq!>5 minutes</option><option value="10" !;
			if ($value eq "10") {
				$content .= qq!selected="yes"!;
			}
			$content .= qq!>10 minutes</option><option value="15" !;
			if ($value eq "15") {
				$content .= qq!selected="yes"!;
			}
			$content .= qq!>15 minutes</option></select></td></tr>\n!;
		} elsif ($options{$key} =~ m/Speed Limit/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td><input type="text" size="5" name="$key" value="$value" /> KBps</td></tr>\n!;
		} elsif ($options{$key} =~ m/RSS Automatic Downloads/ || $options{$key} =~ m/RSS Folder Sorting/) {
			$content .= qq!<tr><td width="250">$options{$key}</td><td>On<input type="radio" name="$key" value="on" !; 
			if ($value eq "on") {
				$content .= qq!checked ="checked"!;
			}
			$content .= qq!/>&nbsp;Off<input type="radio" name="$key" value="off" !;
			if ($value eq "off") {
				$content .= qq!checked ="checked"!;
			}
			$content .= qq!/></td></tr>\n!;
		} else {
			$content .= qq!<tr><td width="250">$options{$key}</td><td><input type="text" size="5" name="$key" value="$value" /></td></tr>\n!;
		}
		$count ++;
		if ($count == 24) {
			$content .= "</table>\n";
		}
		
  }
	$content .= "</fieldset>\n";
	
	
	$content .= qq!<p><input type="submit" name="form_submit" value="Save Changes" />&nbsp;\n!;
	$content .= qq!<input type="submit" name="form_submit" value="Set On-Peak Speed" />&nbsp;\n!;
	$content .= qq!<input type="submit" name="form_submit" value="Set Off-Peak Speed" />\n!;
	$content .= qq!</p></form>\n!;
	$content .= qq!</div>\n!;

	return $content;
}

sub gen_options_submit () {
	my $cgi = get_cgi();

	my $content = "";
	
	my $submit_button = $cgi->param("form_submit");

	# Capture the on-peak / off-peak Speed submit buttons here, and send to correct section of code
	if ($submit_button =~ m/Speed/) {
		$content = gen_speed_submit();
	} else {
		my $off_peak_start = $cgi->param("off_peak_start");
		my $off_peak_up = $cgi->param("off_peak_up_speed_kb");
		my $off_peak_down = $cgi->param("off_peak_down_speed_kb");
		my $on_peak_start = $cgi->param("on_peak_start");
		my $on_peak_up = $cgi->param("on_peak_up_speed_kb");
		my $on_peak_down = $cgi->param("on_peak_down_speed_kb");
		my $daemon_loc = $cgi->param("daemon_loc");
		my $remote_loc = $cgi->param("remote_loc");
		my $remote_user = $cgi->param("remote_user");
		my $remote_pass = $cgi->param("remote_pass");
		my $torrent_loc = $cgi->param("torrent_loc");
		my $rss_loc = $cgi->param("rss_loc");
		my $movie_rss_loc = $cgi->param("movie_rss_loc");
		my $email_addr = $cgi->param("email_addr");
		my $remove_data = $cgi->param("remove_data");
		my $last_active = $cgi->param("last_active");
		my $seed_time = $cgi->param("seed_time");
		my $rss_state = $cgi->param("rss_state");
		my $rss_sorting = $cgi->param("rss_sorting");
		my $rss_ratio = $cgi->param("rss_ratio");
		my $rss_time = $cgi->param("rss_time");
		my $rss_down_loc = $cgi->param("rss_down_loc");
		my $transmission_port = $cgi->param("transmission_port");

		my %db_options_return = db_set_options($off_peak_start,$off_peak_up,$off_peak_down,$on_peak_start,$on_peak_up,$on_peak_down,$daemon_loc,$remote_loc,$remote_user,$remote_pass,$torrent_loc,$rss_loc,$movie_rss_loc,$email_addr,$rss_state,$rss_sorting,$rss_ratio,$rss_time,$rss_down_loc,$transmission_port,$remove_data,$last_active,$seed_time);	
		$db_options_return{info} .= apply_crontab($off_peak_start,$on_peak_start);	
		$content = $db_options_return{info};
	}

	$content .= gen_options();

	return $content;
}

sub gen_speed_submit () {
	my $cgi = get_cgi();
	my $period = $cgi->param("form_submit");
	
	my $content = "";
	my $ignored_content = "";
	
	$content = "<h3>$period</h3>";

	if ($period =~ m/Off/) {
		$ignored_content = cli_set_off_peak_speed();
	} else {
		$ignored_content = cli_set_on_peak_speed();
	}

	return $content; 	
}

sub gen_dbmaint () {
	my $cgi = get_cgi();
	
	#require "./db.pm";
	require "/var/www/html/auto/db.pm";

	my $content = load_page("\/usr\/local\/bin\/auto.db");

	return $content;
}

sub cli_functions ($) {
	
	my $content = "";
	my $verbose = shift;
	
	$ARGV[1] = "nothing" unless defined($ARGV[1]);

	if ($ARGV[1] eq "start_trans") {
		print "Starting Transmission now\n";
		print "This may take a short time, i have to wait for it to start!\n";
		
		$content = cli_start_transmission();
		print $content;
		
		#Commented out as Transmission directory will handle this
		#print "Reading the database now for torrents to re-add\n";
		#$content = cli_add_db_torrents();	
		print $content;
	}

	if ($ARGV[1] eq "start_transmission") {
		print "Starting Transmission now\n";
		print "This may take a short time, i have to wait for it to start!\n";
		
		$content = cli_start_transmission();
	} elsif ($ARGV[1] eq "load_database") {
		print "Reading the database now for torrents to re-add\n";
		$content = cli_add_db_torrents();	
	} elsif ($ARGV[1] eq "set_off") {				
		$content = cli_set_off_peak_speed();
	} elsif ($ARGV[1] eq "set_on") {				
		$content = cli_set_on_peak_speed();
	} elsif ($ARGV[1] eq "off_peak") {				
		$content = cli_off_peak_ops();
	} elsif ($ARGV[1] eq "on_peak") {				
		$content = cli_on_peak_ops();
	} elsif ($ARGV[1] eq "start_off_peak") {
		$content = cli_start_queue_torrents("off");
	} elsif ($ARGV[1] eq "start_on_peak") {
		$content = cli_start_queue_torrents("on");
	} elsif ($ARGV[1] eq "rss") {				
		$content = cli_rss($verbose);
		if ($content ne "") {
			send_mail($content);
		}
	} elsif ($ARGV[1] eq "movierss") {				
		$content = cli_movierss($verbose);
	} elsif ($ARGV[1] eq "del_old_torrents") {				
		$content = cli_delete_old_torrents();
	} elsif ($ARGV[1] eq "update_movierss_dates") {				
		$content = cli_update_movierss_dates();
	} elsif ($ARGV[1] eq "sync_trans_auto") {				
		$content = sync_trans_auto();
	} elsif ($ARGV[1] eq "clean_up") {				
		$content = cli_clean_up();
	} elsif ($ARGV[1] eq "my_eps") {				
		$content = retrieve_my_eps_today();
	} elsif ($ARGV[1] eq "version") {				
		$content = "AUTO v1.0\n";
	} elsif ($ARGV[1] eq "test") {				
		$content = cli_test();
	} elsif ($ARGV[1] eq "name_check") {				
		$content = cli_name_check($ARGV[2],$ARGV[3]);
	} elsif ($ARGV[1] eq "help") {				
		$content = cli_help();
	} elsif ($ARGV[1] eq "nothing") {				
		$content = cli_help();
	} else {
		$content = cli_help();
	}
	
	print $content;

}

sub get_cgi {
        return $auto::cgi;
}

sub send_mail ($) {
	my $content = shift;

	my @content_array = split(/\n/,$content);
	
	my %config = load_config();
	my $emails = $config{email_addr};

	my $files = "";
	my $temp_torrent = "";
	my $count = 0;

	foreach my $line (@content_array) {
		# If line equals success, add 1 to counter to files output
		if ($line =~ m/"Success"/i) {
			$count++;
		}

		# torrent is only added to files if two sucessful Success messages are received
		# One for changing the directory
		# And one for inserting the torrent itself
		if ($count == 2) {	
			$files .= $temp_torrent;
			$count = 0;
		}

		# Check if line matches a torrent download
		if ($line =~ m/Torrent\sfile\s(.*\.torrent)/i) {
			$count = 0;
			# If so, store torrent in variable
			$temp_torrent = $1."<br />\n";
		}
	}	

	#make sure we actually have someting to say!
	if ($files ne "") {
	
		my $auto_url = $config{auto_url};
		my $page_url = $auto_url . "?page=operate&filter=download" if $auto_url; 
		
		my $sendmail = "/usr/sbin/sendmail -f downloads -t";
		my $subject = "Subject: AUTO has begun downloading file(s)\n";
		my $send_to = "To: ".$emails."\n";
	 
		open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";
		#print SENDMAIL $reply_to;
		print SENDMAIL $subject;
		print SENDMAIL $send_to;
		print SENDMAIL "Content-type: text/html\n\n";
		print SENDMAIL "<html>\n";
		print SENDMAIL "<p>Hi User,<br />\n";
		print SENDMAIL "The following file(s) have begun downloading<br />\n";
		print SENDMAIL "<br />";
		print SENDMAIL "<strong>" . $files . "</strong>\n";
		# print SENDMAIL "<strong>Filename:</strong> " . $content_array[8] . "<br />";
		print SENDMAIL "<br />\n";
		print SENDMAIL "<a href=\"" . $page_url . "\">AUTO Download Page</a><br />\n"  if $page_url;
		print SENDMAIL "<br />\n";
		print SENDMAIL "Enjoy the rest of your day!!</p>\n";
		print SENDMAIL "</html>";
		close(SENDMAIL)	
	
	}
}
