#!/usr/bin/perl

# Vishwajit Kolathur
# CMS - Sync V 0.5
# 23:30 19/12/12

use URI::Escape;
use LWP::Simple qw($ua head); # for the ping check
$ua->timeout(0.5); # timeout interval
use File::HomeDir; # for home directory access
use WWW::Mechanize;
$mech = WWW::Mechanize->new( onerror=> undef);

#  Checking whether to use the lan site or the public IP
#  LAN site usage will happen only if there is a computer responding
#  on the IP 172.16.100.125 else it will check for the connectivity 
#  to the Public IP 111.93.5.216 

$local_address = "http://172.16.100.125/";
$remote_address = "http://111.93.5.216/";
$name = "Academics"; #Folder name under which to store
$permissions = '0755'; #folder permissions
$folder = File::HomeDir->my_home . "/$name";

#begin IP Check Code
if(head($local_address)){
	print "Using the intranet site\n";
	$mech->get($local_address);
	$address = $local_address;
}
else {
	if(head($remote_address)){
		print "Using the internet site\n";
		$mech->get($remote_address);
		$address = $remote_address;
	}
	else{
		die "no internet access, no use\n";
	}
}
#end IP Check Code

#  Now that we know which version of the site to use
#  Check for the existance of the required Directory
#  Acadamics if it exists proceed else create it
#  Move into the "Academics" directory and check for
#  the existance of the courses.txt file
#  if it exists continue down the path, else create
#  and die asking user to fill it in

#begin courses check
chdir "$folder" or (chdir File::HomeDir->my_home and mkdir $name, oct($permissions) and chdir "Academics");
my $fileSpec ="courses.txt";
if ( -e $fileSpec ) {
    print "Reading from the file\n";
	open FILE, 'courses.txt';
	while(<FILE>) {
		my $dummy = $_;
		next if $dummy =~ m/^\#/;
		push @courses, $dummy;
	}
	close FILE;
	chomp(@courses);
	#print @courses;
} 
else {
		open FILE, '>courses.txt';
		close FILE;
	    die "No course list, please fill in the course list\nin your /home/Academics directory under the name courses.txt\n";

}
#end courses check

#  Now that we have reached the website we have to login
#  to the darn site, so i had to make a bot go press the guest
#  login button located below the username and password box
#  its somewhere there. (IF ONLY THE CMS TEAM MADE IT EASIER)

#begin login button bot
$mech->follow_link( text => 'login');
$mech->form_id( 'guestlogin' );
$mech->click_button( number => 1);
#end login button bot

#  Now use the array of courses to scout out courses in CMS
#  find all courses that are there and itteratively visit
#  in the visit, scrape all pure file links (what i mean by this is, from the .php?id=XXXXX we extract the actual hard coded url for the file
#  from the hard coded url, decode the URL to get a file name which we compare with acutal content of the foler, If it exists
#  if the folder doesnt exist for a course we create it and then download all the relevant files for that course

#start downloader
foreach $courses (@courses){
	next if $courses eq "";
	my $mech1 = $mech->clone();
	print "Course Code ERROR, course code $courses doesnt exist\n" and next if $mech1->follow_link( text_regex => qr/$courses/i ) eq undef;
	$mech1->follow_link( text_regex => qr/LS1/ );
	@c = $mech1->find_all_links();
	chdir "$courses" or (mkdir $courses, oct($permissions) and chdir $courses);
	print "from course $courses i have downloaded:\n"; 
	my $count = 0;
	foreach $c (@c){
		my $attr = $c->attrs();
		next if $attr->{onclick} eq "";
		my $w = substr $attr->{onclick}, 13,-17;
		$w =~ s/http:\/\/111\.93\.5\.216\//$address/ if ($w =~ m/^(http:\/\/111\.93\.5\.216\/)/);
		$w =~ s/http:\/\/172\.16\.100\.125\//$address/ if ($w =~ m/^(http:\/\/172\.16\.100\.125\/)/);
		my $dwn = $mech1->clone();
		my $fname = substr $attr->{onclick}, 59, -33;
		my @values = split('/', $fname);
		$fname = uri_unescape($values[-1]);
		my @all_files = glob '*';
		next if $fname ~~ @all_files;
		$dwn->get($w);
		$dwn->save_content($fname);
		print $fname;
		print "\n";
		$count = $count + 1;
	}
	print "--- Downloaded $count file(s) for $courses\n";
	chdir "$folder";
}
#end downloader
