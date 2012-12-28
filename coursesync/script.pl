#!/usr/bin/perl

# Vishwajit Kolathur
# CMS - Sync V 0.75
# 23:30 19/12/12

$version = "0.75 beta";
use URI::Escape;
use LWP::Simple qw($ua head); # for the ping check
$ua->timeout(0.5); # timeout interval
use File::HomeDir; # for home directory access
use WWW::Mechanize;

#Global Variables
$mech = WWW::Mechanize->new( onerror=> undef);
$local_address = "http://172.16.100.125/";
$remote_address = "http://111.93.5.216/";
$name = "Academics"; #Folder name under which to store
$permissions = '0755'; #folder permissions
$folder = File::HomeDir->my_home . "/$name";
$fileSpec =".courses.txt";

#  Command line argument supporting menu
#  this calls the respective subroutine
#  also offers help and version check

#start command line argument handling
if($#ARGV == -1){
	print "No command line arguments found, use --help to find out commands\n";
	exit;
}
my $option = $ARGV[0];
shift @ARGV;
if ($option eq "add")	{ &add(@ARGV);}
elsif ($option eq "sync")	{&sync;}
elsif ($option eq "--help") {&help;}
elsif ($option eq "--version")	{&version;}
elsif ($option eq "update")	{&update;}
elsif ($option eq "log")	{&log;}
elsif ($option eq "courses")	{&courses;}
elsif ($option eq "remove")	{&remove(@ARGV);}
else { exit;}
exit;
#end command line argument handling

#  Removing courses from the course list
#  supports multiple removal, and works
#  checks for multiple occurances also

#start course removal
sub remove{
	my @rem = @_;
	my $count = $#rem;
	my @courses;
	chdir "$folder" or (chdir File::HomeDir->my_home and mkdir $name, oct($permissions) and chdir $name);
	if ( -e $fileSpec ) {
		open FILE, $fileSpec;
		while(<FILE>){
			push @courses, $_;
		}
		close FILE;
		chomp(@courses);
		open FILE, '>'.$fileSpec;
		print "Cant remove any courses, there arent any in the first place\n" if($#courses == 0);
		if($#rem %2 eq 0){
			print "cant remove, one or more of the courses dont exhibit proper syntax, check @rem\n";
			return;
		}
		for(my $i=0; $i <= $count; $i = $i + 2){
			push @del, "$rem[$i] $rem[$i+1]";
		}
		my %delh;
		@delh{@del} = ();
		@courses = grep ! exists $delh{$_}, @courses;
		foreach $courses (@courses){
			print FILE "$courses\n";
		}
		close FILE;
	} 
	else {
			print "No Course List yet, create one using add, use --help for syntax\n";
	}
	&courses;
}
#end course removal

#  Displays contents of courselist

#start course display
sub courses{
	chdir "$folder" or (chdir File::HomeDir->my_home and mkdir $name, oct($permissions) and chdir $name);
	if ( -e $fileSpec ) {
		open FILE, $fileSpec;
		print "The following are the contents of your course list:\n";
		while(<FILE>){
			print $_;
		}
		close FILE;
	} 
	else {
			print "No Course List yet, create one using add, use --help for syntax\n";
	}

}
#end course display

#  A log file display mechanism to
#  see whats going on, and also
#  helps in bug checks

#start log display
sub log{
	my $logSpec;
	chdir "$folder" or (chdir File::HomeDir->my_home and mkdir $name, oct($permissions) and chdir $name);
	if ( -e $logSpec ) {
	    print "Reading the file\n";
		open LOG, $logSpec;
		print "The following are the contents of your Log File:\n";
		while(<LOG>){
			print $_;
		}
		close LOG;
	} 
	else {
		print "The Log is Empty\n";	
	}

}
#end log display

#  Command line update check
#  NON FUNCTIONAL
#  Still need to write this

#start update
sub update{
	print "I really dont know how i am going to manage this, lets see, not ready yet :-p\n";
}
#end update

#  Version Display subroutine
#start version
sub version{
	print "You are currently running a version: $version\n";
}
#end version

#  Help Subroutine, Just prints help text

#start help
sub help{
	print("\nThe following are the commands:\nadd\t\tthis allows you to add multiple courses, syntax: <add discipline course_code discipline course_code....>\nsync\t\tthis allows you to sync between the CMS and ur directory\n--version\tthis will allow you to find the CourseSync version number\nupdate\t\tthis will allow you to update the CourseSync application\nlog\t\tthis will allow you to look at the action logs, what was added, what was removed etc\ncourses\t\tthis prints all the courses you have in your course list\nremove\t\tthis allows you to remove courses that you dont want, but this will not remove the past downloaded content\n\n");
}
#end help

#  Core Sync subroutine
#  the main syncing part of the program

#start sync
sub sync{
	#  Checking whether to use the lan site or the public IP
	#  LAN site usage will happen only if there is a computer responding
	#  on the IP 172.16.100.125 else it will check for the connectivity 
	#  to the Public IP 111.93.5.216 
	
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
	chdir "$folder" or (chdir File::HomeDir->my_home and mkdir $name, oct($permissions) and chdir $name);
	if ( -e $fileSpec ) {
	    print "Reading from course list\n";
		open FILE, $fileSpec;
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
			open FILE, '>'.$fileSpec;
			close FILE;
		    print "No course list, please fill in the course list\nby executing the add command\n";
			exit;
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
			if ($w =~ m/^(http:\/\/111\.93\.5\.216\/)/) {$w =~ s/http:\/\/111\.93\.5\.216\//$address/;} 
			else {$w =~ s/http:\/\/172\.16\.100\.125\//$address/;}
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
}
#end sync

#  Functions to add courses to the course list

#start course add
sub add{
	my @args = @_;
	my $count = $#args;
	chdir "$folder" or (chdir File::HomeDir->my_home and mkdir $name, oct($permissions) and chdir $name);
	if ( -e $fileSpec ) {
	    print "Writing to the file\n";
		open FILE, '>>'.$fileSpec;
		print "The enetered course set is incomplete, enter the \"discipline course_code\" for each course\nverify @args\n" and exit if ($count%2 eq 0);
		for(my $i=0; $i <= $count; $i = $i + 2){
			print FILE "$args[$i] $args[$i+1]\n";
		}
		close FILE;
		open FILE, $fileSpec;
		print "The following are the contents of your course list\n";
		while(<FILE>){
			print $_;
		}
		close FILE;
	} 
	else {
			open FILE, '>'.$fileSpec;
			die "The enetered course set is incomplete, enter the \"discipline course_code\" for each course\nverify @args" if ($count%2 eq 0);
			for(my $i=0; $i < $count; $i = $i + 2){
				print FILE "$args[i] $args[i+1]\n";
			}
			close FILE;
	
	}
}
#end course add
