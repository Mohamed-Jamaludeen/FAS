use strict;
use warnings;

use Falcon_perl;

my $app = Falcon_perl->apply_default_middlewares(Falcon_perl->psgi_app);
$app;

