#!/usr/bin/perl

use lib qw(/frontline/InCAM/release/app_data/perl);
use incam;

my $job_path="/workfile/jobs";
my ($filename,$module,$tik,$step,$checklist,$layer,$comment)=($ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3],$ARGV[4],$ARGV[5],$ARGV[6]);
our $orig_flag = 0;

$comment =~ s/_/ /g;
$comment =~ s/\!/\\!/g;
$comment =~ s/\./\\./g;

my $database="db1";

my $status_file="/frontline/incam_info";


open(OUT,">>$status_file");

$host='localhost';
$f = new incam($host);
my $job_name="tst.dfm.${module}.${tik}";

$f->COM(import_open_job,db=>"$database",path=>"$job_path/$filename",name=>"$job_name",analyze_surfaces=>"no",create_customer=>"yes",keep_nls=>"yes");
$f->COM(open_job,job=>"$job_name");
$f->COM(open_entity,job=>"$job_name",type=>"step",name=>"$step",iconic=>"no");
$f->COM(check_inout,job=>"$job_name",mode=>"out",ent_type=>"job");




#delete extra steps
$f->INFO(units => "mm",
         entity_type => "job",
         entity_path => "$job_name",
	 data_type   => "STEPS_LIST");
#my @step_num=$f->{doinfo}{gSTEPS_LIST};
if ($#{$f->{doinfo}{gSTEPS_LIST}} > 1){
	foreach $exist_step (@{$f->{doinfo}{gSTEPS_LIST}}){
		if ($exist_step eq $step){
			next;
		}else{
			$f->COM(delete_entity,job=>"$job_name",name=>"$exist_step",type=>"step");
		}
	}
}

#delete CAM_GUIDE
$f->INFO(units => "mm",
         entity_type => "job",
         entity_path => "$job_name",
	 data_type   => "CAM_GUIDE_LIST");

if ($#{$f->{doinfo}{gCAM_GUIDE_LIST}} > 0){
	foreach $exist_cam_guide (@{$f->{doinfo}{gCAM_GUIDE_LIST}}){
		$f->COM(delete_guide,guide=>"$exist_cam_guide");
	}
}

#delete Forms
$f->INFO(units => "mm",
         entity_type => "job",
         entity_path => "$job_name",
	 data_type   => "FORMS_LIST");

if ($#{$f->{doinfo}{gFORMS_LIST}} > 0){
	foreach $exist_form (@{$f->{doinfo}{gFORMS_LIST}}){
		$f->COM(delete_form,job=>"$job_name",form=>"$exist_form");
	}
}

#delete extra checklist
$f->INFO(units => "mm",
         entity_type => "step",
         entity_path => "$job_name/$step",
	 data_type   => "CHECKS_LIST");

if ($#{$f->{doinfo}{gCHECKS_LIST}}>1){
	foreach $exist_checklist (@{$f->{doinfo}{gCHECKS_LIST}}){
		if ($exist_checklist eq $checklist){
			next;
		}else{
			$f->COM(chklist_delete,chklist=>"$exist_checklist");
		}
	}
}

#delete netlist
$f->VOF;
$f->COM(netlist_delete,job=>"$job_name",step=>"$step",type=>"cad",layers_list=>"");
$f->COM(netlist_delete,job=>"$job_name",step=>"$step",type=>"ref",layers_list=>"");
$f->COM(netlist_delete,job=>"$job_name",step=>"$step",type=>"cur",layers_list=>"");
$f->VON;



$f->INFO(units => "mm",
         entity_type => "matrix",
         entity_path => "$job_name/matrix");
for (my $i=0;$i<$#{$f->{doinfo}{gROWname}};$i++){
	$matrix_layer{"$f->{doinfo}{gROWname}[$i]"}=$f->{doinfo}{gROWcontext}[$i];
}

foreach $LYR (@{$f->{doinfo}{gROWname}}){
	if ($matrix_layer{"$LYR"} eq "misc"){
		my $regex = '/.*'+$layer+'.*orig.*/';
		if (("$LYR" ne "${layer}+++")||("$LYR" !~ "$regex")){
			$f->COM(delete_layer,layer=>$LYR);
		}
		if ("$LYR" =~ "$regex"){
			our $orig_layer=$LYR;
			$orig_flag = 1;
		}
		if ("$LYR" eq "${layer}+++"){
			our $orig_layer=$LYR;
			$orig_flag = 1;
		}

	}
}

if ($orig_flag == 0){
	print OUT "do not exist orig or +++ layer, please check!";
	exit 1;
}

$f->COM(copy_layer,source_job=>"$job_name",source_step=>"$step",source_layer=>"$orig_layer",dest=>'layer_name',dest_step=>"$step",dest_layer=>"$layer",mode=>'replace',invert=>'no',copy_notes=>'no',copy_attrs=>'new_layers_only',copy_sr_feat=>'no');
$f->COM(affected_layer,mode=>"all",affected=>"no");
$f->COM(affected_layer,name=>"$layer",mode=>"single",affected=>"yes");
$f->COM(chklist_run,chklist=>"$checklist",nact=>1,area=>'global');
$f->COM(copy_layer,source_job=>"$job_name",source_step=>"$step",source_layer=>"$layer",dest=>'layer_name',dest_step=>"$step",dest_layer=>'ref',mode=>'replace',invert=>'no',copy_notes=>'no',copy_attrs=>'new_layers_only',copy_sr_feat=>'no');
$f->COM(copy_layer,source_job=>"$job_name",source_step=>"$step",source_layer=>"$orig_layer",dest=>'layer_name',dest_step=>"$step",dest_layer=>"$layer",mode=>'replace',invert=>'no',copy_notes=>'no',copy_attrs=>'new_layers_only',copy_sr_feat=>'no');

#rename checklist
$f->COM(chklist_rename,chklist=>"$checklist",newname=>"${checklist}.linux");

$f->COM(save_job,job=>"$job_name",override=>"no",skip_upgrade=>"no");
$f->COM(check_inout,job=>"$job_name",mode=>"in",ent_type=>"job");
$f->COM(editor_page_close);
$f->COM(close_job,job=>"$job_name");

my $new_line="$job_name\t$step\t$layer\t$checklist\tref\t0.5\t0\tref\t$comment";
my $basefile="/frontline/smo_test_base";

open(BASE,"<$basefile");
my $end_line=0;
my $i=1;
while(<BASE>){
	chomp($_);
	my $line=$_;
	if (($line =~ /^\s+$/)||($line =~ /^$/)){
		$end_line=$i;
		last;
	}
	$i++;
}
if ($end_line==0){
	$end_line=$i;
	`echo "$new_line" >> "$basefile"`;
}else{
	my $command = qq!sed -i $end_line' s/^\$/$new_line/' "$basefile"!;
	`echo "$command" |csh`;
}
close(BASE);

$f->COM(close_toolkit,save_log=>"no");

close(OUT);
exit 0;



