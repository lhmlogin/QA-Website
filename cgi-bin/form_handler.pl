#!/usr/bin/perl

$|=1;
$ENV{'FRONTLINE_NO_LOGIN_SCREEN'}="/home/hamm/.incam";
print "Content-Type: text/plain\n\n";

print "\n==============================================\n";

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
$inputs{'comment'} =~ s/ /_/g;
#print "$form";
my $INCAM = "/frontline/InCAM";
my $TOUCHCAM = "/frontline/TouchCAM";
my $script_dir = "/var/www/cgi-bin";
#print "${inputs{'module'}}.pl $inputs{'filename'} $inputs{'module'} $inputs{'tik'} $inputs{'checklist'} $inputs{'layer'} $inputs{'comment'}";

if ($inputs{'software'} eq "InCAM"){
	print "start to run InCAM\n";
	system("$INCAM/$inputs{'version'}/bin/InCAM -x -s$script_dir/${inputs{'module'}}.pl $inputs{'filename'} $inputs{'module'} $inputs{'tik'} $inputs{'step'} $inputs{'checklist'} $inputs{'layer'} $inputs{'comment'}");
	print "finished running\n";
}elsif ($inputs{'software'} eq "TouchCAM"){
	system("$TOUCHCAM/$inputs{'version'}/bin/TouchCAM -x -s$script_dir/${inputs{'module'}}.pl $inputs{'filename'} $inputs{'module'} $inputs{'tik'} $inputs{'step'} $inputs{'checklist'} $inputs{'layer'} $inputs{'comment'}");
}

exit 0;


