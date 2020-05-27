#!/usr/bin/perl -l
use strict;
use warnings;
use DBI;
use Data::Dumper;
our $dbh;
our $err_fh;
open ($err_fh,'>>', 'log_error.log') or die "Couldn't open error file: $!";

sub main{
	proc_fill_db('mail.log');
}

sub proc_fill_db{
	my ($filename) = @_;
	# открытие файла
	my $log_fh;
	open ($log_fh,'<', $filename) or die "Couldn't open log file: $!";
	#чтение файла в массив
	my @log = <$log_fh>;

	#print Dumper(@log);
#	my @right_flags =
	foreach my $str (@log) {
		my ($date,$time,$int_id,$flag,$message) = split(/\s/,$str , 5);
		if ($flag  eq '<='){
			my ($addr) = $message =~ /^([^\s]*)\s/;
			my ($id) = $message =~ /id=([^\@]*)\@/;
			#print 'id: '.$id.'/n';
			$message = $int_id.' '.$flag.' '.$message;
			if($id){
				insert_message({ timestamp =>$date.' '.$time,
					 int_id => $int_id,
					 id => $id,
					 msg => $message});
			}else{
				insert_log({int_id => $int_id,
					    msg=> $message,
					    addr=>$addr,
					    timestamp => $date.' '.$time});
			}
		}elsif ( grep {$_ eq $flag} ('=>','->','**','==') ) {
			my ($addr) = $message =~ /^([^\s]*)\s/;
			my $id = $message =~ /id=*\s/;
			my $message = $int_id.' '.$flag.' '.$message;
			insert_log({int_id => $int_id,
					    msg=> $message,
					    addr=>$addr,
					    timestamp => $date.' '.$time});
		}else{
			$message = $int_id.' '.$flag.' '.$message;
			#my ($addr) = $message =~ /^([^\s]*)\s/;
			insert_log({int_id => $int_id,
				    msg => $message,
				    addr => undef,
				    timestamp => $date.' '.$time});
		}
	}	
	undef @log;
	close $log_fh;
}
sub insert_message{
    my ($args) = @_;
    my $sql = 'INSERT INTO message (created, id, int_id, str)
	           VALUES(?,?,?,?)';
    my $sql_exe = $dbh->prepare($sql);
    if(!$sql_exe->execute($args->{timestamp},$args->{id},$args->{int_id},$args->{msg})){
		print $err_fh 'Duplicate id: '.$args->{int_id}.' Error: '.$DBI::errstr.' \n';
	}
}
sub insert_log{
    my ($args) = @_;
    my $sql = 'INSERT INTO log (created, int_id, str,address)
	           VALUES(?,?,?,?)';
    my $sql_exe = $dbh->prepare($sql);
    if (!$sql_exe->execute($args->{timestamp},$args->{int_id},$args->{msg},$args->{addr})){
		print $err_fh 'Duplicate id: '.$args->{int_id}.' Error: '.$DBI::errstr.' \n';
	}
}
$dbh = DBI->connect("DBI:mysql:database=Perl_task;host=localhost",
                       'perl_task', 'paladium',
                       {'RaiseError' => 0, 'PrintError' => 0});
					   
main();
$dbh->disconnect;
close $err_fh;
1;
