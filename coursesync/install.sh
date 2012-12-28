#!/bin/bash
DIR = $(pwd)
get_cpanm(){
    if [ \! -f /usr/local/bin/cpanm ]; then
		cd $TMP_DIR && curl --insecure -L http://cpanmin.us | perl - App::cpanminus
		if [ \! -f /usr/local/bin/cpanm ]; then
		echo "Downloading from cpanmin.us failed, downloading from xrl.us"
		curl -LO http://xrl.us/cpanm &&
		chmod +x cpanm &&
		mv cpanm /usr/local/bin/cpanm
		fi
	fi
	CPANM=$(which cpanm);
	if [ \! -f "$CPANM" ]; then
		echo "ERROR: Unable to find cpanm"
		return 1;
	fi
	return 0
}
get_cpanm
cpanm --sudo LWP::Simple URI::Escape File::HomeDir WWW::Mechanize
cd $DIR
chmod +x script.pl
cp -p script.pl /usr/local/bin/CourseSync
install -g 0 -o 0 -m 0644 .CourseSync.1 /usr/local/man/man1/CourseSync.1
gzip /usr/local/man/man1/CourseSync.1
