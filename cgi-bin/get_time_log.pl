#!/usr/bin/perl

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

my $version1="$inputs{'version1'}";
my $version2="$inputs{'version2'}";
our $os_name = "$inputs{'platform'}";#should fill "Linux" or "WINDOWS_NT"
our $log_dir="/workfile/Performance/logs";

if (($version1 eq "")||($version2 eq "")){
	print "Content-Type: text/plain\n\n";
	print "Warning:\n";
	print "Please Enter Version Number First\n";
	
exit 0;
}

if (-e $log_dir) {
    `mv $log_dir $log_dir.$$`;
}

print "Content-Type: text/html\n\n";

#mkpath("$log_dir",1,0755);
`mkdir -p $log_dir`;
&get_version_basefile($version1);
&get_version_basefile($version2);
&compare($version1,$version2);


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
	<p>please find the log in /id/workfile/Performance/logs</p>
	<img src="../images/finish-logo.png" alt="finished" border="0" />
</div>

</body>
</html>
	
HTML

exit 0;


sub get_version_basefile{
	my $version=$_[0];

my $root_dir1="/genesisdir/home/time_log";
my $root_dir2="/genesisdir/home/runtime_log";
my $module_file="$log_dir/modules";
my $checklist_time="$log_dir/checklist_time_$version";
my $runtime="$log_dir/runtime_$version";

open(MODULE, ">$module_file");
chdir "$root_dir1";
print MODULE `ls *$os_name*$version`;
close(MODULE);
open(MODULE,"<$module_file");

while(<MODULE>){
	chomp($_);
	my $input_file="$root_dir1/$_";
	open(INPUT,"<$input_file");
	while(<INPUT>){
		chomp($_);
		my $existflag=0;
		my $line=$_;
		my ($line_num,$job_name,@other)=split(" ",$line);
		if ($line_num !~ /\d+/){
			next;
		}else{
			if (! -e "$checklist_time"){
				`touch "$checklist_time"`;
			}
			open(B1,"<$checklist_time");
			while(<B1>){
				chomp($_);
				my $line_tmp=$_;
				my ($line_num_tmp,$job_name_tmp,@other_cmp)=split(" ",$line_tmp);
				if (($line_num == $line_num_tmp)&&("$job_name" eq "$job_name_tmp")){
					$existflag=1;
				}
			}
			close(B1);
			if ($existflag == 0){
				open(B1,">>$checklist_time");
				print B1 "$line\n";
				close(B1);
			}
		}
	}
	close(INPUT);
}

close(MODULE);






open(MODULE, ">$module_file");
chdir "$root_dir2";
print MODULE `ls *$os_name*$version`;
close(MODULE);
open(MODULE,"<$module_file");

while(<MODULE>){
	chomp($_);
	my $input_file="$root_dir2/$_";
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


sub compare{
	my $version1=$_[0];
	my $version2=$_[1];
	my $runtime_v1="$log_dir/runtime_$version1";
	my $checklist_time_v1="$log_dir/checklist_time_$version1";
	my $runtime_v2="$log_dir/runtime_$version2";
	my $checklist_time_v2="$log_dir/checklist_time_$version2";
	
	my $result_runtime="$log_dir/result_runtime_all.txt";
	my $result_checklist_time="$log_dir/result_checklist_time_prog.txt";
	open(RUNTIME,">>$result_runtime");
	open(CHECKLIST_TIME,">>$result_checklist_time");
	print CHECKLIST_TIME "LINE\tJOB\t$version1\t$version2\tDIFF_TIME\n";
	print RUNTIME "LINE\tJOB\t$version1\t$version2\tDIFF_TIME\n";
	open(RUN_V1,"$runtime_v1");
	open(CHECK_V1,"$checklist_time_v1");
	
	while(<CHECK_V1>){
		chomp($_);
		my ($line1,$job1,$step1,$layer1,$chklst1,$pre_time1,$cur_time1,@other1)=split("\t",$_);
		open(CHECK_V2,"$checklist_time_v2");
		while(<CHECK_V2>){
			chomp($_);
			my ($line2,$job2,$step2,$layer2,$chklst2,$pre_time2,$cur_time2,@other2)=split("\t",$_);
			if(($line1==$line2)&&("$job1" eq "$job2")){
				my $difftime=$cur_time2-$cur_time1;
				print CHECKLIST_TIME "$line1\t$job1\t$cur_time1\t$cur_time2\t$difftime\n";
				last;
			}
		}
		close(CHECK_V2);	
	}
	close(CHECK_V1);
	
	
	
	
	while(<RUN_V1>){
		chomp($_);
		my ($line1,$job1,$step1,$layer1,$pre_time1,$cur_time1,@other1)=split("\t",$_);
		open(RUN_V2,"$runtime_v2");
		while(<RUN_V2>){
			chomp($_);
			my ($line2,$job2,$step2,$layer2,$pre_time2,$cur_time2,@other2)=split("\t",$_);
			if(($line1==$line2)&&("$job1" eq "$job2")){
				my $difftime=$cur_time2-$cur_time1;
				print RUNTIME "$line1\t$job1\t$cur_time1\t$cur_time2\t$difftime\n";
				last;
			}
		}
		close(RUN_V2);	
	}
	close(RUN_V1);
}


