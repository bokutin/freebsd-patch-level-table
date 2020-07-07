package FreeBSD_PatchLevelTable::View;

use Date::Parse;
use File::Spec::Functions;
use FreeBSD_PatchLevelTable::Container;
use HTTP::Status qw(status_message);
use IO::All;
use JSON::MaybeXS qw(:legacy);
use List::Util qw(sum uniq);
use POSIX qw(strftime);
use Safe::Isa;
use Time::Duration ();

1;
