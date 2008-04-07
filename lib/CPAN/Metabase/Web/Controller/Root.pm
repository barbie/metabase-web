use strict;
use warnings;
package CPAN::Metabase::Web::Controller::Root;
use base 'Catalyst::Controller::REST';

# XXX: until there's a real analyzer
use lib "$ENV{HOME}/code/projects/CPAN-Metabase/t/lib";

our $VERSION = '0.001';
$VERSION = eval $VERSION; # convert '1.23_45' to 1.2345

use CPAN::Metabase::Gateway;
use CPAN::Metabase::Analyzer::Test;

my $gateway;
sub _gateway {
  return $gateway ||= CPAN::Metabase::Gateway->new({
    analyzers => [ CPAN::Metabase::Analyzer::Test->new ],
  });
}

# /submit/dist/RJBS/Acme-ProgressBar-1.124.tar.gz/Test-Report
#  submit dist 0    1                             2
sub submit : Chained('/') CaptureArgs(0) {
  warn "SUBMIT @_";
}

sub dist : Chained('submit') Args(3) ActionClass('REST') {
  my ($self, $c, $dist_author, $dist_file, $type) = @_;
  warn "DIST @_";

  { # XXX: 
    return $self->status_bad_request($c, message => 'invalid dist author')
      unless $dist_author =~ /\A[A-Z]+\z/;

    return $self->status_bad_request($c, message => 'invalid distribution')
      unless $dist_file =~ /\.tar\.gz\z/;
  }

  $c->stash(
    user_id     => 'rjbs', # this needs to come from auth and a shared source
    dist_author => $dist_author,
    dist_file   => $dist_file,
    type        => $type,
  );
}

sub dist_POST {
  my ($self, $c) = @_;

  $c->stash->{content} = $c->req->param('payload');

  my $result = eval { $self->_gateway->handle($c->stash); };

  unless ($result) {
    my $error = $@;
    warn $error; # XXX: we should catch and report Permission exceptions
                 # -- rjbs, 2008-04-07

    return $self->status_bad_request($c, message => "gateway failure: $error");
  }

  warn "ABOUT TO BE CREATED";
  return $self->status_created(
    $c,
    location => 'http://www.google.com/',
    entity   => { guid => 'unknown' },
  );
}

BEGIN{ *dist_PUT = \&dist_POST; }

1;
