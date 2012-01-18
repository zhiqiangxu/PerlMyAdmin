package Configuration;
use strict;
use warnings;
use Exporter;
use base qw/Exporter/;
our @EXPORT_OK = qw/DSN DB_USER DB_PASS DB_NAME/;

use constant DSN => "DBI:mysql:test_shore:localhost";
use constant DB_NAME => 'test_shore';
use constant DB_USER => "root";
use constant DB_PASS => "111111";


1
