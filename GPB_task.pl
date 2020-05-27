#!/usr/bin/perl -l
use CGI;
use strict;
our $cgi = new CGI;
use DBI;
print "Content-type: text/html\r\n\r\n";

sub send_html{	
	my $table = $_[0];
	local $a;
	my $fl;
	open($fl,'/var/local/GPB_TASK/application.html');
   
	while($a=<$fl>)	{
   		print $a; 
	}
	if($table){
		print $table;
	}
	close $fl;
}
sub get_logs_list{
	my ($args) = @_;
	my $dbh = DBI->connect("DBI:mysql:database=Perl_task;host=localhost",
                       'perl_task', 'paladium',
                       {'RaiseError' => 1});

	my $sql = <<'SQL';
select logs.log_str
  from 
  (SELECT CONCAT(l2.created,' ',l2.str) log_str,l2.int_id,l2.created 
     from log l2 
    where l2.address  = ?
    UNION ALL
   select CONCAT(m2.created,' ',m2.str) log_str, m2.int_id,m2.created  
     from message m2 
    where m2.str LIKE CONCAT('% ',?,' %')) logs
order by logs.int_id,logs.CREATED
SQL
    my $sql_exe = $dbh->prepare($sql);
       $sql_exe->execute($args->{addr},$args->{addr});
	my $log_list = $sql_exe->fetchall_arrayref({});
	my $table;
	my $log_list_length = scalar(@{$log_list});

	if($log_list_length> 0 && $log_list_length < 100){
		$table ='<table>';
		foreach my $log_str ( @{$log_list} ) {
            $table.='<tr><td>'.$log_str->{log_str}.'</td></tr>';
    	}
		$table.='</table>';
	}elsif($log_list_length >= 100){
		$table = 'Result contains more than 100 rows';
	}else{
		$table = '';
	}
	undef $log_list;
	$dbh->disconnect;
	return $table;
}
my $param = $cgi->{param};
if($param->{address}[0]){
	my $log_table =  get_logs_list({addr => $param->{address}[0]});
	send_html($log_table);
}else{
	send_html();
}

