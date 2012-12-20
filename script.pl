#!/usr/bin/perl

# Vishwajit Kolathur
# CMS - Sync V 0.1
# 23:30 19/12/12

use LWP::Simple qw($ua head); # for the ping check
use File::HomeDir; # for home directory access
$ua->timeout(0.5); # timeout interval

#  Checking whether to use the lan site or the public IP
#  LAN site usage will happen only if there is a computer responding
#  on the IP 172.16.100.125 else it will check for the connectivity 
#  to the Public IP 111.93.5.216 

my $local_address = "http://172.16.100.125/";
my $remote_address = "http://111.93.5.216/";
my $name = "Academics"; #Folder name under which to store
my $permissions = '0755'; #folder permissions
my $folder = File::HomeDir->my_home . "/$name";

#begin IP Check Code
if(head($local_address)){
	print "Using the intranet site\n";
}
else {
	if(head($remote_address)){
		print "Using the internet site\n";
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
	my @courses;
	for (my $i = 0 ; $i < 8 ; $i++) {
		my $dummy = <FILE>;
		if($dummy =~ m/^\#/){
			next;
		}
		push @courses, $dummy;
	}
	close FILE;
	chomp(@courses);
	print @courses;
} 
else {
		open FILE, '>courses.txt';
		close FILE;
	    die "No course list, please fill in the course list\nin your /home/Academics directory under the name courses.txt\n";

}
#end courses check


