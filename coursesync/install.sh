#!/bin/bash
sudo perl -MCPAN -e 'install LWP::Simple'
sudo perl -MCPAN -e 'install URI::Escape'
sudo perl -MCPAN -e 'install "File::HomeDir"'
sudo perl -MCPAN -e 'install WWW::Mechanize'
chmod +x script.pl
sudo cp -p script.pl /usr/local/bin/CourseSync
sudo cp .CourseSync.1 /usr/share/man/man1/CourseSync.1
