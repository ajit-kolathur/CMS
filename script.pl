use LWP::Simple qw($ua head);
$ua->timeout(0.5);
my $local_address = "http://172.16.100.125/";
my $remote_address = "http://111.93.5.216/";
if(head($local_address)){
	print "intranet\n";
}
else {
	if(head($remote_address)){
		print "internet\n";
	}
	else{
		print "no net\n";
	}
}
