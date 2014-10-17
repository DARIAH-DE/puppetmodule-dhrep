#!/bin/bash
# Run script as user root!

# Some settings.
NI='installing_the_noid >>>'
NOID_USER=tgnoid
HOME=/home/$NOID_USER
WWW_DATA=www-data
MINTER_PREFIX=textgrid
echo "$NI noid user is $NOID_USER"
echo "$NI minter prefix is $MINTER_PREFIX"

# Change to tgnoid home dir.
cd $HOME
echo "$NI changed to folder /home/$NOID_USER/"

# Download and unpack NOID from CPAN.
wget http://search.cpan.org/CPAN/authors/id/J/JA/JAK/Noid-0.424.tar.gz
tar -zxvf Noid-0.424.tar.gz
echo "$NI downloaded and unpacked the noid from cpan"

# Compile and install NOID.
cd Noid-0.424
perl Makefile.PL
make
make test
echo "$NI compiled and tested the noid"

# Patch NOID binary.
patch noid < $HOME/tgnoid.patch
echo "$NI patched the noid script to avoid warning messages"

# Do install the NOID.
make install
echo "$NI Installed the noid"

# Create some folders and copy NOID binaries to destination folder.
mkdir ../htdocs
mkdir ../htdocs/nd
echo "$NI created folders /htdocs/nd/"
cp noid ../htdocs/nd
echo "$NI copied the noid binary to /htdocs/nd/"
cd ../htdocs/nd

# Create hard links for HTTP binaries.
ln noid ./noidr_$MINTER_PREFIX
ln noid ./noidu_$MINTER_PREFIX
echo "$NI hardlinks created to the noid"

# Create minter folder for TextGrid and create TextGrid minter
mkdir textgrid
cd textgrid
noid dbcreate $MINTER_PREFIX:.zee
echo "$NI minter $MINTER_PREFIX:.zee created"
cd ..

# Change user, group, and permissions.
cd $HOME/htdocs
chown -R $NOID_USER:$NOID_USER .
chgrp -R $WWW_DATA nd/textgrid
chmod -R 664 nd/textgrid/NOID
chmod 775 nd/textgrid
chmod 775 nd/textgrid/NOID
echo "$NI recursively set user, group, and permissions"

# Test minting the first 13 TExtGrid URIs.
cd nd/textgrid
noid mint 7
echo "$NI first seven textgrid uris successfully minted"

# Add apache config from within the apache config file:
# modules/textgrid/manifests/resources/apache.pp
echo "$NI apache configuration already added by tgnoid.pp"

# Apache ssecurity is added from within the file tgnoid.pp.
echo "$NI security already added by tgnoid.pp"

# DONE.
echo "$NI ready"
