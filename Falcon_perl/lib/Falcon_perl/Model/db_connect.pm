package Falcon_perl::Model::db_connect;
use Moose;
use namespace::autoclean;
use DBI;
use Data::Dumper;
use Data::Dump qw(dump);
# use base 'Catalyst::Model::DBI';

extends 'Catalyst::Model';


 
# __PACKAGE__->config(
#   dsn           => 'DBI:Pg:falcon=mydb;host=localhost',
#   username      => 'pgsql',
#   password      => 'Jamal@123',
#   options       => { AutoCommit => 1 },
#   loglevel      => 1
# );

my $dbh;
# use Falcon_perl::Util qw/get_db_connect_params get_db_schema/;
# my $_MYSCHEMA = get_db_schema(Falcon_perl->config(), 'dudb');

sub _dbconnect {
		# $dbh = DBI->connect(
		# 		get_db_connect_params(DuApp->config(), 'mycom'),
		# 		{ 'RaiseError' => MyCommunity::Mycom->config->{dev} }
		# 	);
		$dbh = DBI->connect ('dbi:Pg:dbname=Falcon;host=127.0.0.1','postgres', 'Jamal@123', { AutoCommit => 1 });
		# print "dbh is " . $dbh;
		# print Dumper($dbh);
		# $dbh = DBI->connect ('dbi:Pg:dbname=Du_dev;host=10.52.40.67','postgres', 'jamdev777**', { AutoCommit => 1 });
}




sub _autoconnect {
	if ($dbh) {
		my $rv = $dbh->pg_ping;
		if ($rv < 1) { undef $dbh; }
	}
	unless ($dbh) { _dbconnect(); }
}

sub login_status {
	my ($self, $user, $pwd) = @_;

	_autoconnect();
	print "username is" . $user;
	my $userno;
	my $role;
	my $inv_access;

	$user    = $dbh->quote($user);
	$pwd 	= $dbh->quote($pwd);
	my $sqlst     = qq{SELECT userno, role FROM flcn.users where "username" = $user and "password" = $pwd};
	my $sth       = $dbh->prepare($sqlst);

	$sth->execute;
	print "the query is --->" . $sqlst;
	while (my $rowhashptr = $sth->fetchrow_hashref()) {
			$userno = $rowhashptr->{'userno'};
			$role = $rowhashptr->{'role'};
	}
	$sth->finish();

	unless ($dbh->err()) {
		my $sqlst1     = qq{UPDATE flcn.users SET lastlogin=now() WHERE userno=$userno};
		my $sth1       = $dbh->prepare($sqlst1);		
		$sth1->execute;
	}
	return ($userno, $role);
}

sub db_disconnect {
	$dbh->disconnect();
}


sub flight_add {
	my ($self,$arrival,$crew,$departure,$destination,$flight,$origin,$pilots,$userno) = @_;
	_autoconnect();

	$arrival	= $dbh->quote($arrival);
	$crew		= $dbh->quote($crew);
	$departure	= $dbh->quote($departure);
	$destination= $dbh->quote($destination);
	$flight		= $dbh->quote($flight);
	$origin		= $dbh->quote($origin);
	$pilots		= $dbh->quote($pilots);



	
	my $sqlst =
	  qq{INSERT INTO flcn.flights(arrival, crew, departure, destination, flightno, origin, pilots, userno, addtime) VALUES 
	  	($arrival,$crew,$departure,$destination,$flight,$origin,$pilots,$userno,now()); };

		# print "SQL is ---> " . $sqlst; 
	
	my $sth       = $dbh->prepare($sqlst);
	unless ($dbh->err()) {
		$sth->execute;
		return $sth->err() ? 0 : 1;
	}
	return 0;
}


sub getflights {
	my ($self, $userid, $reportee) = @_;
	_autoconnect();

	my $sqlst;
	# if($userid eq 6001){
		$sqlst     = qq{
			SELECT flightno, origin, destination, departure, arrival, flightid,
			(select count(*) from flcn.passenger as b where b.flightid = flightid and check_in_time is not null) as chincnt, 
			(select count(*) from flcn.passenger as b where b.flightid = flightid and board_time is not null) as bdgcnt,
			(select count(*) from flcn.passenger as b where b.flightid = flightid ) as passcnt
			FROM flcn.flights;
		};	
	# } elsif($reportee){
	# 	$sqlst     = qq{select sm_name,customer_name,to_char(start_date, 'YYYY,MM,DD') as start_date from dudb.meetings where userid IN
 # 						(select "Userid" from dudb."Users" where "Reporting" = $userid)};	
	# } else {
	# 	$sqlst     = qq{select sm_name,customer_name,to_char(start_date, 'YYYY,MM,DD') as start_date from dudb.meetings where userid = $userid};	
	# } 
	
	
	my @flights;
	my $sth = $dbh->prepare($sqlst);
	$sth->execute;
	while (my $rowhashptr = $sth->fetchrow_hashref) {
		push (@flights, $rowhashptr);
	}
	$sth->finish();
	return \@flights;

}

sub pax_add {
	my ($self,$sex,$surname,$docno,$seat,$destination,$notes,$userno,$flightid) = @_;
	_autoconnect();

	$sex			= $dbh->quote($sex);
	$surname		= $dbh->quote($surname);
	$docno			= $dbh->quote($docno);
	$seat			= $dbh->quote($seat);
	$destination	= $dbh->quote($destination);
	$notes			= $dbh->quote($notes);
	



	
	my $sqlst =
	  qq{INSERT INTO flcn.passenger("sex", "surname", "document_number", "seat", "destination", "special_notes", userno, addtime, updtime, flightid) VALUES 
	  	($sex,$surname,$docno,$seat,$destination,$notes,$userno,now(),now(),$flightid); };

		print "SQL is ---> " . $sqlst; 
	
	my $sth       = $dbh->prepare($sqlst);
	unless ($dbh->err()) {
		$sth->execute;
		return $sth->err() ? 0 : 1;
	}
	return 0;
}

sub getpax {
	my ($self, $userid, $flightid) = @_;
	_autoconnect();

	$flightid			= $dbh->quote($flightid);
	my $sqlst = qq{select * from flcn.passenger where flightid= $flightid};	
	
	my @pax;
	my $sth = $dbh->prepare($sqlst);
	$sth->execute;
	while (my $rowhashptr = $sth->fetchrow_hashref) {
		push (@pax, $rowhashptr);
	}
	$sth->finish();
	return \@pax;

}

sub getsinglepax {
	my ($self, $flightid, $seq_no) = @_;
	_autoconnect();

	my $flightid_q		= $dbh->quote($flightid);
	$seq_no			= $dbh->quote($seq_no);
	my $sqlst = qq{select * from flcn.passenger where flightid= $flightid_q and seq_no = $seq_no};	
	
	my $sth = $dbh->prepare($sqlst);
	$sth->execute;
	my $ref = $sth->fetchrow_hashref;
	$sth->finish();
	$ref->{flightid}=$flightid;
	unless ($dbh->err()) {
		return $ref;
	}

}

sub getsingleflight {
	my ($self, $userno, $flightid) = @_;
	_autoconnect();

	# my $sqlst = qq{select * from flcn.flights where flightid= $flightid};	
	my $sqlst = qq{select flightno, origin, destination, departure, arrival, flightid, departure - interval '30 minutes' as boardingtime,
			(select count(*) from flcn.passenger as b where b.flightid = flightid and check_in_time is not null) as chincnt, 
			(select count(*) from flcn.passenger as b where b.flightid = flightid and board_time is not null) as bdgcnt,
			(select count(*) from flcn.passenger as b where b.flightid = flightid ) as passcnt
			
		from flcn.flights where flightid= $flightid};	
	
	my $sth = $dbh->prepare($sqlst);
	$sth->execute;
	my $ref = $sth->fetchrow_hashref;
	$sth->finish();
	unless ($dbh->err()) {
		return $ref;
	}

}

sub pax_update {
	my ($self,$userno, $params) = @_;
	_autoconnect();
$params->{sex}				= $dbh->quote($params->{sex});
$params->{boardcomm}		= $dbh->quote($params->{boardcomm});
$params->{bweight}			= $dbh->quote($params->{bweight});
$params->{company}			= $dbh->quote($params->{company});
$params->{from_value0}		= $dbh->quote($params->{from_value0});
$params->{gender}			= $dbh->quote($params->{gender});
$params->{name}				= $dbh->quote($params->{name});
$params->{optimaexpiry}		= $dbh->quote($params->{optimaexpiry});
$params->{optimano}			= $dbh->quote($params->{optimano});
$params->{passcomm}			= $dbh->quote($params->{passcomm});
$params->{paxtype}			= $dbh->quote($params->{paxtype});
$params->{seat}				= $dbh->quote($params->{seat});
$params->{surname}			= $dbh->quote($params->{surname});
$params->{syspaexpiry}		= $dbh->quote($params->{syspaexpiry});
$params->{syspano}			= $dbh->quote($params->{syspano});
$params->{syspano}			= $dbh->quote($params->{syspano});
$params->{crew_pax}			= $dbh->quote($params->{crew_pax});
$params->{final_destination}= $dbh->quote($params->{final_destination});
$params->{onward_flight}	= $dbh->quote($params->{onward_flight});
$params->{destination}		= $dbh->quote($params->{destination});

	
	my $sqlst =
	  qq{
	  	UPDATE flcn.passenger SET 
	  	seat = $params->{seat},
	  	sex= $params->{sex},
	  	surname=$params->{surname}, 
	  	first_names=$params->{name}, 
	  	syspaexpiry=$params->{syspaexpiry}, 
	  	crew_pax=$params->{crew_pax}, 
	  	destination=$params->{destination}, 
	  	final_destination=$params->{final_destination}, 
	  	onward_flight=$params->{onward_flight}, 
	  	company=$params->{company}, 
	  	check_in_time=now(), 
	  	special_notes=$params->{seat}, 
	  	userno=$userno, 
	  	updtime=now(), 
	  	document_number=$params->{optimano}, 
	  	flightid=$params->{flightid},
	  	checkintime= now()
	WHERE seq_no = $params->{seq_no}
};

		print "SQL is ---> " . $sqlst; 
	
	my $sth       = $dbh->prepare($sqlst);
	unless ($dbh->err()) {
		$sth->execute;
		return $sth->err() ? 0 : 1;
	}

	return 0;
}

 
1;

=head1 NAME

Falcon_perl::Model::db_connect - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.


=encoding utf8

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
