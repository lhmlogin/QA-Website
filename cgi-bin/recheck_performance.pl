#!/usr/bin/perl

use CGI;
use DBI;
use File::Path;
use CGI::Carp 'fatalsToBrowser';

$|=1;

my $cgi=new CGI;
my %inputs = $cgi->Vars;

print "Content-type: text/plain\n\n";
print "the cgi script is running\n";

#get the uploaded file number
my $num_file=0;
foreach $KEY (keys(%inputs)){
	if($KEY =~ /file[0-9]+/) {
		$num_file++;
	}
}

if (-e "/id/workfile/Performance/recheck_log/recheck_result_log") {
	`rm /id/workfile/Performance/recheck_log/recheck_result_log`;
}

my $log_file="/id/workfile/Performance/recheck_log/recheck_result_log";
open(OUT,">>$log_file");

my $version1=$inputs{'version1'};
my $version2=$inputs{'version2'};
my $tmp_dir="/tmp";

#set environment variable as 10.20.30.231

$ENV{'FRONTLINE_NO_LOGIN_SCREEN'}="/auto_incam/server/users/billy";
$ENV{'GENESIS_DIR'}="/genesisdir";
$ENV{'TPATH'}="/AutoData/tPath";
$ENV{'GENESIS_VER'}="InCAM2.31";
$ENV{'VPATH'}="/AutoData/vPath/Linux.recheck";
$ENV{'SPATH'}="/genesisdir/Spath/genesis";
$ENV{'tmp_dir'}="/tmp";
$ENV{'PLATFORM'}="Linux";
$ENV{'FORMATS'}="/AutoData/Formats";
$ENV{'VERSION'}="InCAM";
$ENV{'HOME'}="/genesisdir/home";
$ENV{'mail_to'}="billy";
$ENV{'GENESIS_TMP'}="/tmp";

for(my $i=1;$i<=$num_file;$i++){
	my $FH=$cgi->upload("file".$i) or die "$!";
	my $module=$inputs{"module".$i};
	#my $server_ip = "10.20.30.231";
	my $dbh=DBI->connect("dbi:mysql:autotest",'root');
	#$dbh=DBI->connect("dbi:mysql:autotest:$server_ip",'genesis','genesis') or die "the database is not connected $!";
	my $sth1=$dbh->prepare(qq/select path from modules where name="$module"/);
	$sth1->execute();
	my $module_path_raw;
	$sth1->bind_columns(\$module_path_raw);
	$sth1->fetch();
	$sth1->finish();
	
	chomp($module_path_raw);
	
	my $module_path = `echo $module_path_raw | cut -f4- -d'/'`;
	chomp($module_path);
	my $mod = `echo $module_path | cut -f2- -d'/'`;
	chomp($mod);
	$mod =~ s/\//_/;

	while(<$FH>){
		chomp($_);
		if (($_ !~ /^\s+$/)&&($_ ne '')){
		my ($line,$job) = split(/\s+/,$_);
		
		#get the test script name
	if ($module eq "smo"){
		if ($job =~ /.*smo_splitshave.*/){
			$testname="smo_splitshave_test";
		}
		else {
			$testname="checklistcmp_test";
		}
	}
	elsif ($module eq "dml_net"){
		$testname="netlist_test";
	}
	else{
		$testname=`cd $ENV{'TPATH'}/$module_path ; ls *_test|grep -v "No match"`;
		chomp($testname);
	}
		
		
		$version = $version1;
		$ENV{'GENESIS_EDIR'}="/auto_incam/$version";
		$ENV{'INCAM_BUILD'}="/auto_incam/$version";
		$ENV{'GENESIS_EXEC'}="/auto_incam/$version/bin/InCAM";
		if (! -e "$ENV{'VPATH'}/$module_path"){
			mkpath("$ENV{'VPATH'}/$module_path",1,0755);
		}
		open(CUR,">$ENV{'VPATH'}/$module_path/${mod}.cur");
		open(EN,">$ENV{'VPATH'}/$module_path/${mod}.end");
		print CUR "$line"; 
		print EN "$line"; 
		close(EN);
		close(CUR);
		print "$ENV{'GENESIS_EXEC'} -x -s$ENV{'TPATH'}/$module_path/${testname} $module_path\n";
		`$ENV{'GENESIS_EXEC'} -x -s$ENV{'TPATH'}/$module_path/${testname} $module_path`;
		
		my $first_time=`cat $ENV{'GENESIS_DIR'}/home/executime_tmp/$module/$line.$job`;
		chomp($first_time);
		
		$version = $version2;
		$ENV{'GENESIS_EDIR'}="/auto_incam/$version";
		$ENV{'INCAM_BUILD'}="/auto_incam/$version";
		$ENV{'GENESIS_EXEC'}="/auto_incam/$version/bin/InCAM";
		
		open(CUR,">$ENV{'VPATH'}/$module_path/${mod}.cur");
		open(EN,">$ENV{'VPATH'}/$module_path/${mod}.end");
		print CUR "$line"; 
		print EN "$line"; 
		close(EN);
		close(CUR);
		print "$ENV{'GENESIS_EXEC'} -x -s$ENV{'TPATH'}/$module_path/${testname} $module_path\n";
		`$ENV{'GENESIS_EXEC'} -x -s$ENV{'TPATH'}/$module_path/${testname} $module_path`;
		
		my $second_time=`cat $ENV{'GENESIS_DIR'}/home/executime_tmp/$module/$line.$job`;
		chomp($first_time);
		chomp($second_time);
		
		print OUT "$line\t$job\t$first_time\t$second_time\n";
		}
	}
}

print "Finished!\n";
print "please check the log in /id/workfile/Performance/recheck_log/recheck_result_log";


close(OUT);

exit 0;
