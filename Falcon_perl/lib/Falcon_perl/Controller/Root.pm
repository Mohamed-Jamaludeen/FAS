package Falcon_perl::Controller::Root;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use MIME::Base64;
use File::Copy;
use Spreadsheet::Read qw(ReadData);
use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use DateTime;
use Date::Calc;
use Date::Manip;

# use 'Catalyst::View::TT';

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

Falcon_perl::Controller::Root - Root Controller for Falcon_perl

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut



sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    if ($c->session->{status} eq 'success') {
    		$c->stash(login => 'success');
    		$c->response->redirect("main");
    } else {
    	my $code = randomCode($self, $c, 10);
    	$c->session->{rand} = $code;
    	$c->stash( rand => $code );
    	$c->stash->{template} = 'index.tt';	
    }
    
}

sub login :Local {
	my ($self, $c) = @_;
	$c->log->debug(" NOW in login");
	$c->log->debug(" username" . $c->req->params->{username});
	print " NOW in login";
	my $login_stats = undef;
	

	my ($userno, $role) = $c->model('db_connect')->login_status( $c->req->params->{username},$c->req->params->{password});
	
# $c->log->debug("userno " . $userno);
# $c->log->debug(userno);

	# $c->session->{rand};
    
    
	if(($c->req->params->{username}) && ($c->req->params->{password})){
	
		
	# 	my $pwd = decode_base64($c->req->params->{password});
	# 	my $rand = $c->session->{rand};
	# 	$pwd =~ s/$rand//g;
	# 	# $c->log->debug(" rand is --->" . $c->session->{rand});
	# 	# $c->log->debug(" Alhamdulillah the pwd is --->" . $pwd);
	# 	my ($userid, $role) = $c->model('db_connect')->login_status( $c->req->params->{user},$pwd);
		if ($userno) {

			$c->log->debug(" role" . $role);
					$login_stats = 'success';
					$c->stash(loginstat => $login_stats);
					$c->session->{status} = 'success';
					$c->session->{userno} = $userno;
					$c->session->{role} = $role;
					# $c->stash->{template} = 'main.tt';
					if($role eq 'agent'){
						$c->response->redirect("main");
					} elsif($role eq 'ops') {
						$c->response->redirect("flightadd");
					} elsif($role eq 'admin') {
						$c->response->redirect("main");
					}
					
					
					
		} else {
					$c->log->debug(" in else");
					$login_stats = 'Username or password incorrect';
					$c->stash(loginstat => $login_stats);
					$c->stash( template => 'index.tt' );	
		}

	} else {
		$c->log->debug(" out else");
		$login_stats = 'Please enter Username and password';
		$c->stash(loginstat => $login_stats);
		$c->stash( template => 'index.tt' );
    }
	
}

=head2 default

Standard 404 error page

=cut

sub main : Local Args(0) {
	my ( $self, $c ) = @_;

	$c->stash->{template} = 'main1.tt';
}

sub main1 : Local Args(0) {
	my ( $self, $c ) = @_;

	$c->stash->{template} = 'main.tt';
}

sub flights : Local Args(0) {
	my ( $self, $c ) = @_;
	my $flights = $c->model('db_connect')->getflights($c->session->{userno});
	$c->stash(flights => $flights);
	$c->stash->{template} = 'flights.tt';
}

sub flightsadd : Local Args(0) {
	my ( $self, $c ) = @_;

	my $stat1 = $c->model('db_connect')->flight_add($c->req->params->{arrival},$c->req->params->{crew},$c->req->params->{departure},$c->req->params->{destination},$c->req->params->{flight},$c->req->params->{origin},$c->req->params->{pilots},$c->session->{userno});

		if ($stat1){
			print "updated....";

			$c->stash(update_status => "Updated Successfuly");
			$c->session->{update_status} = "$c->req->params->{flight} : Updated Successfuly";
			# $c->stash(template => 'psd_dashboard.tt');
			my $rand = $c->session->{rand};
			$c->response->redirect("/flights"); 
		} else {

			print "couldn't be updated....";
			$c->stash(update_status => "couldn't be updated.... please try again");
			$c->session->{update_status} = "couldn't be updated.... please try again";
			$c->response->redirect("/flightadd");

		}

}

sub flightadd : Local Args(0) {
	my ( $self, $c ) = @_;

	$c->stash->{template} = 'flightadd.tt';
}

sub passengers : Local Args(1) {
	my ( $self, $c, $flightid ) = @_;

	my $pax = $c->model('db_connect')->getpax($c->session->{userno},$flightid);
	my $flights = $c->model('db_connect')->getsingleflight($c->session->{userno},$flightid);
	$c->stash(pax => $pax);
	$c->stash(flights => $flights);
	$c->stash->{template} = 'passengers.tt';
}

sub addpass : Local Args(1) {
	my ( $self, $c, $flightid ) = @_;
	my $flights = $c->model('db_connect')->getsingleflight($c->session->{userno},$flightid);
	
	$c->stash(userno => $c->session->{userno});
	$c->stash(flights => $flights);
	$c->stash->{template} = 'addpass.tt';
}

sub uploadpass : Local Args(0) {
	my ( $self, $c ) = @_;
	$c->log->debug("##############Came In #############");
	my $upload   = $c->req->upload('file');
	my $code = randomCode($self,$c,10);
	my $filename = $code . "-" . $upload->filename;
	$filename =~s/\s/_/igs;
	my $fullpath = $c->path_to('root', 'static','files', 'temp_uploads', $filename);
	my $chk = $upload->copy_to( $fullpath );
# print "Full path --->  " . $fullpath;
# $c->log->debug("Full path --->  " . $fullpath);
	my $book = ReadData ($fullpath);
my ($sex,$surname,$docno,$seat,$destination,$notes);
	my @rows = Spreadsheet::Read::rows($book->[1]);
		foreach my $i (1 .. scalar @rows) {
			
    		foreach my $j (1 .. scalar @{$rows[$i-1]}) {
    			$sex = $rows[$i-1][1];
    			$surname = $rows[$i-1][2];
    			$docno = $rows[$i-1][7];
    			$seat = $rows[$i-1][11];
    			$destination = $rows[$i-1][15];
    			$notes = $rows[$i-1][21];

	# $c->log->debug("##############Came In #############". $i);

    			
			}

			# my $stat1 = $c->model('db_connect')->pax_add($sex,$surname,$docno,$seat,$destination,$notes,$c->session->{userno},$c->req->params->{flightid});
			# unless ($stat1){
   #      		print $fh "$account_number\t$name\n";
   #      		print "failed to update";
			# }
		}

		# $c->log->debug("##############Status is #############  " . $stat1);
	# $c->stash->{template} = 'addpass.tt';
	$c->response->redirect("/passengers/".$c->req->params->{flightid});
}

sub pass_det : Local Args(2) {
	my ( $self, $c, $flightid, $seq_no) = @_;

	my $pax_details = $c->model('db_connect')->getsinglepax($flightid,$seq_no);
	my $flights = $c->model('db_connect')->getsingleflight($c->session->{userno},$flightid);
	
	$c->stash(paxdetails => $pax_details);
	$c->stash(flights => $flights);
	$c->stash->{template} = 'passengers_details.tt';
}

sub pass_seat : Local Args(2) {
	my ( $self, $c, $flightid, $docno) = @_;

	my $pax_details = $c->model('db_connect')->getsinglepax($flightid,$docno);
	$c->stash(paxdetails => $pax_details);
	$c->stash->{template} = 'seating.tt';
}

sub pass_seat1 : Local Args(2) {
	my ( $self, $c, $flightid, $docno) = @_;

	my $pax_details = $c->model('db_connect')->getsinglepax($flightid,$docno);
	$c->stash(paxdetails => $pax_details);
	$c->stash->{template} = 'seating_pop.tt';
}

sub pass_ticket : Local Args(2) {
	my ( $self, $c, $flightid, $docno) = @_;

	my $pax_details = $c->model('db_connect')->getsinglepax($flightid,$docno);
	$c->stash(paxdetails => $pax_details);
	# $c->stash->{template} = 'ticket.tt';
	# $c->stash->{template} = 'ticket1.tt';
	$c->stash->{template} = 'ticket2.tt';
}


sub checkinpass : Local Args(0) {
	my ( $self, $c ) = @_;
	
	my $stat = $c->model('db_connect')->pax_update($c->session->{userno},$c->req->params);
	$c->response->redirect("/passengers/".$c->req->params->{flightid});
}






sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub randomCode {
        my ( $self, $c, $passwordsize) = @_;
         # print "passwordsize is " . $passwordsize;
        my @alphanumeric = ('a'..'z', 'A'..'Z', 0..9);
        my $randpassword = join '', map $alphanumeric[rand @alphanumeric], 0..$passwordsize;
        # print "password is " . $randpassword;
        return $randpassword;
}

sub logout :Local {
	my ($self, $c) = @_;
	$c->response->header('X-Frame-Options' => 'DENY');
	my $databridge = $c->model('Databridge');
	$c->log->debug(" NOW in log out");
	$c->delete_session();
	$self = '';
	$c->response->redirect('/');
	
}


=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
