package Constants;
use strict;
use warnings;
use Exporter;
use base qw/Exporter/;
our @EXPORT_OK = qw/ROOT LIB_ROOT DSN DB_USER DB_PASS DB_NAME TRUE FALSE DELETE_PSW USE_PSW/;

use constant ROOT => "/home/zhiqiang.xu/htdocs/www/test_project";
use constant LIB_ROOT => ROOT . '/lib';
use constant TRUE => 1;
use constant FALSE => 0;
use constant DELETE_PSW => 'sdc';
use constant USE_PSW => 'sdc';

1
