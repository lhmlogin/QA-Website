#!/usr/bin/perl

use DBI;
use File::Path;

$|=1;



 if ( $ENV{'REQUEST_METHOD'} eq "GET" &&
      $ENV{'QUERY_STRING'} ne '') {
     $form = $ENV{'QUERY_STRING'};
     }
 elsif ( $ENV{'REQUEST_METHOD'} eq "POST" ) {
     read(STDIN,$form, $ENV{'CONTENT_LENGTH'});
 } else {
     print "\n At least fill something! I cannot work with empty strings";
     exit;
     }

 #
 # Now the variable $form has your input data.
 # Create your associative array.
 #
     foreach $pair (split('&', $form)) {
         if ($pair =~ /(.*)=(.*)/) {  # found key=value;
         ($key,$value) = ($1,$2);     # get key, value.
         $value =~ s/\+/ /g;  # substitute spaces for + signs.
         $value =~ s/%(..)/pack('c',hex($1))/eg;
         $inputs{$key} = $value;   # Create Associative Array.
         }
     }

my $prefix="$inputs{'big_version'}";
my $version="$inputs{'version_num'}";
our $os_name = "$inputs{'platform'}";#should fill "Linux" or "WINDOWS_NT"
our $log_dir="/workfile/Performance/upload_db";

if (($prefix eq "")||($version eq "")){
	print "Content-Type: text/plain\n\n";
	print "Warning:\n";
	print "Please Enter Version Number First\n";
	
exit 0;
}

if (-e $log_dir) {
    `rm -r $log_dir`;
}

print "Content-Type: text/html\n\n";

#mkpath("$log_dir",1,0755);
`mkdir -p $log_dir`;
&get_version_basefile($version);

our $suffix;

if ($os_name eq "Linux"){
	$suffix="linux";
}
if ($os_name eq "WINDOWS_NT"){
	$suffix="windows";
}

my $in="$log_dir/runtime_$version";


#my $dbh=DBI->connect("dbi:mysql:performance:10.20.30.231",'genesis','genesis');
my $dbh=DBI->connect("dbi:mysql:performance",'root');
#the table's name and field's name should not be "lines","time" etc.
$dbh->do("create table ${prefix}_${version}_${suffix} (line varchar(32),job varchar(128),step varchar(128),layer varchar(128),cur_time int,platform varchar(128))");
open(IN,"$in");
while(<IN>){
	chomp($_);
	my @lines=split(/\s+/,$_);
	#print "$lines[0],$lines[1],$lines[2],$lines[3],$lines[5],$lines[7]";
	#should add quotes to the varchar variables
	$dbh->do(qq/insert into ${prefix}_${version}_${suffix} values("$lines[0]","$lines[1]","$lines[2]","$lines[3]",$lines[5],"$lines[7]")/) or die "can't insert record $!";
}
$dbh->disconnect();
close(IN);


print <<HTML;
<html>
<head>
<title>Leading You Up Front</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />

<style type="text/css">
#finish {
    position: relative;
    top: 50px;
}

</style>

</head>
<body bgcolor="#FFFFFF">



<div id="finish" align="center">
	<img src="../images/finish-logo.png" alt="finished" border="0" />
</div>

</body>
</html>
	
HTML

exit 0;




sub get_version_basefile{
	my $version=$_[0];
	

my $root_dir="/genesisdir/home/runtime_log";
my $module_file="$log_dir/modules";
my $runtime="$log_dir/runtime_$version";


open(MODULE, ">$module_file");
chdir "$root_dir";
print MODULE `ls *$os_name*$version`;
close(MODULE);
open(MODULE,"<$module_file");

while(<MODULE>){
	chomp($_);
	my $input_file="$root_dir/$_";
	open(INPUT,"<$input_file");
	while(<INPUT>){
		chomp($_);
		my $existflag=0;
		my $line=$_;
		my ($line_num,$job_name,@other)=split(" ",$line);
		if ($line_num !~ /\d+/){
			next;
		}else{
			if (! -e "$runtime"){
				`touch "$runtime"`;
			}
			open(B2,"<$runtime");
			while(<B2>){
				chomp($_);
				my $line_tmp=$_;
				my ($line_num_tmp,$job_name_tmp,@other_cmp)=split(" ",$line_tmp);
				if (($line_num == $line_num_tmp)&&("$job_name" eq "$job_name_tmp")){
					$existflag=1;
				}
			}
			close(B2);
			if ($existflag == 0){
				open(B2,">>$runtime");
				print B2 "$line\n";
				close(B2);
			}
		}
	}
	close(INPUT);
}

close(MODULE);

}

	
