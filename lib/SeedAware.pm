package SeedAware;

# This is a SAS component.

#===============================================================================
#
#  This is a small set of utilities that handle differences for running
#  software in the SEED environment, versus outside of it, and a small
#  number of other commands for safely running external programs from
#  within a perl script.
#
#===============================================================================
#  Commands that run, read from, or write to a process, allowing control over
#  the other input streams, as would normally be handled by a shell.
#
#      $status = system_with_redirect(         \%redirects,  @cmd_and_args )
#      $status = system_with_redirect(         \%redirects, \@cmd_and_args )
#      $fh     = write_to_pipe_with_redirect(  \%redirects,  @cmd_and_args )
#      $fh     = write_to_pipe_with_redirect(  \%redirects, \@cmd_and_args )
#      $fh     = read_from_pipe_with_redirect( \%redirects,  @cmd_and_args )
#      $fh     = read_from_pipe_with_redirect( \%redirects, \@cmd_and_args )
#
#      $status = system_with_redirect(          @cmd_and_args, \%redirects )
#      $status = system_with_redirect(         \@cmd_and_args, \%redirects )
#      $fh     = write_to_pipe_with_redirect(   @cmd_and_args, \%redirects )
#      $fh     = write_to_pipe_with_redirect(  \@cmd_and_args, \%redirects )
#      $fh     = read_from_pipe_with_redirect(  @cmd_and_args, \%redirects )
#      $fh     = read_from_pipe_with_redirect( \@cmd_and_args, \%redirects )
#
#  Redirects:
#
#      stdin  => $file  # Process will read from $file
#      stdout => $file  # Process will write to $file
#      stderr => $file  # stderr will be sent to $file (e.g., '/dev/null')
#
#  The file name may begin with '<' or '>', but these are not necessary.
#  If the supplied name begins with '>>', output will be appended to the file.a  
#
#  Simpler versions without redirects:
#
#      $string = run_gathering_output( $cmd, @args )
#      @lines  = run_gathering_output( $cmd, @args )
#
#  Line-by-line read from command:
#
#      while ( $line = run_line_by_line( $cmd, @args ) ) { ... }
#
#      my $cmd_and_args = [ $cmd, @args ];
#      while ( $line = run_line_by_line( $cmd_and_args ) ) { ... }
#
#      Close the file handle before end of file:
#
#      close_line_by_line( $cmd, @args )
#      close_line_by_line( $cmd_and_args )
#
#      Find out the file handle associated with the command and args:
#
#      $fh = line_by_line_fh( $cmd, @args )
#      $fh = line_by_line_fh( $cmd_and_args )
#
#-----------------------------------------------------------------------------
#  Read the entire contents of a file or stream into a string.  This command
#  if similar to $string = join( '', <FH> ), but reads the input by blocks.
#
#     $string = slurp_input( )                 # \*STDIN
#     $string = slurp_input(  $filename )
#     $string = slurp_input( \*FILEHANDLE )
#
#-----------------------------------------------------------------------------
#  Locate commands in special bin directories.  If not in a seed environment,
#  it just returns the bare command:
#
#     $command_possibly_with_path = executable_for( $command )
#
#-----------------------------------------------------------------------------
#  Locate the directory for temporary files in a SEED-aware, but not SEED-
#  dependent manner:
#
#     $tmp = location_of_tmp( )
#     $tmp = location_of_tmp( \%options )
#
#  The function returns the first valid directory that is writable by the user
#  in the sequence:
#
#     $options->{ tmp }
#     $FIG_Config::temp
#     /tmp
#     .
#
#  Failure returns undef.
#
#-----------------------------------------------------------------------------
#  Locate or create a temporary directory for files in a SEED-aware, but not
#  SEED-dependent manner.
#
#     $tmp_dir              = temporary_directory( $name, \%options )
#   ( $tmp_dir, $save_dir ) = temporary_directory( $name, \%options )
#     $tmp_dir              = temporary_directory(        \%options )
#   ( $tmp_dir, $save_dir ) = temporary_directory(        \%options )
#
#  If defined, $tmp_dir will be the path to a temporary directory.
#  If true, $save_dir indicates that the directory already existed, and
#  therefore should not be deleted as the completion of its temporary
#  usage.
#
#  If $name is supplied, the directory in "tmp" is to have this name.  This
#  is also available as an option.
#
#  Failure returns undef.
#
#  The placement of the directory is the value returned by location_of_tmp().
#
#  Options:
#
#     base     => $base     # Base string for name of this temporary directory,
#                           #      to which a random string will be appended.
#     name     => $name     # Name of this temporary directory (without path).
#     save_dir => $bool     # Set $save_dir output (don't delete when done)
#     tmp      => $tmp      # Directory in which the directory is to be placed
#                           #      (D = location_of_tmp( $options )).
#     tmp_dir  => $tmp_dir  # Name of the directory including implicit or
#                           #      explict path.  This option overrides name.
#
#  The options       { tmp => 'my_home', name => 'my_name' }
#  are equivalent to { tmp_dir => 'my_home/my_name' }
#
#-----------------------------------------------------------------------------
#  Create a name for a new file or directory that will not clobber an existing
#  one. File name DOES NOT INCLUDE the directory.
#
#     $file_name = new_file_name( )
#     $file_name = new_file_name( $base_name )
#     $file_name = new_file_name( $base_name, $extention )
#     $file_name = new_file_name( $base_name, $extention, $in_directory )
#
#  The name is derived by adding an underscore and 8 random characterss (or
#  12 random digits) to a base file name (D = temp) in a directory (D = .).
#-----------------------------------------------------------------------------
#  Create a name for a new file or directory that will not clobber an existing
#  one. File name INCLUDES any directory supplied.
#
#     $path_name = tmp_file_name( )
#     $path_name = tmp_file_name( $base_name )
#     $path_name = tmp_file_name( $base_name, $extention )
#     $path_name = tmp_file_name( $base_name, $extention, $in_directory )
#
#  Create and open new file that will not clobber an existing one.
#  File name INCLUDES any directory supplied.
#
#     ( $fh, $path_name ) = open_tmp_file( )
#     ( $fh, $path_name ) = open_tmp_file( $base_name )
#     ( $fh, $path_name ) = open_tmp_file( $base_name, $extention )
#     ( $fh, $path_name ) = open_tmp_file( $base_name, $extention, $in_directory )
#
#  The name is derived by adding an underscore and 8 random characterss (or
#  12 random digits) to a base file name (D = temp) in a directory
#  (D = location_of_tmp()). This means there will always be a directory,
#  even if just './'.
#===============================================================================
use strict;
use Carp;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
        system_with_redirect
        write_to_pipe_with_redirect
        read_from_pipe_with_redirect

        run_gathering_output
        run_line_by_line
        slurp_input

        executable_for
        location_of_tmp
        temporary_directory
        new_file_name
        );
our @EXPORT_OK = qw(
        close_line_by_line
        line_by_line_fh
        new_file_name
        tmp_file_name
        open_tmp_file
        );

my($REAL_STDIN, $REAL_STDOUT, $REAL_STDERR);
BEGIN {
    open $REAL_STDIN,  '<&='  . fileno(*STDIN);
    open $REAL_STDOUT, '>>&=' . fileno(*STDOUT);
    open $REAL_STDERR, '>>&=' . fileno(*STDERR);
}

#
# Bah. On Windows, redirecty stuff needs IPC::Run.
#
# I do not have the IPC::Run version of system_with_redirect() etc. correct -- GJO
#

our $have_ipc_run;
if ($^O =~ /win32/i)
{
    $have_ipc_run = eval { require IPC::Run; };
}


#
#  In case we are running in a SEED, pull in the FIG_Config
#
our $in_SEED;
BEGIN
{
    $in_SEED = eval { require FIG_Config; };
}



#===============================================================================
#  Commands that run, read from, or write to a process, allowing control over
#  the other input streams, as would normally be handled by a shell.
#
#      $status = system_with_redirect(         \%redirects,  @cmd_and_args )
#      $status = system_with_redirect(         \%redirects, \@cmd_and_args )
#      $fh     = write_to_pipe_with_redirect(  \%redirects,  @cmd_and_args )
#      $fh     = write_to_pipe_with_redirect(  \%redirects, \@cmd_and_args )
#      $fh     = read_from_pipe_with_redirect( \%redirects,  @cmd_and_args )
#      $fh     = read_from_pipe_with_redirect( \%redirects, \@cmd_and_args )
#
#      $status = system_with_redirect(          @cmd_and_args, \%redirects )
#      $status = system_with_redirect(         \@cmd_and_args, \%redirects )
#      $fh     = write_to_pipe_with_redirect(   @cmd_and_args, \%redirects )
#      $fh     = write_to_pipe_with_redirect(  \@cmd_and_args, \%redirects )
#      $fh     = read_from_pipe_with_redirect(  @cmd_and_args, \%redirects )
#      $fh     = read_from_pipe_with_redirect( \@cmd_and_args, \%redirects )
#
#  Redirects:
#
#      stdin  => $file  # Where process should read from
#      stdout => $file  # Where process should write to
#      stderr => $file  # Where stderr should be sent (/dev/null comes to mind)
#
#  '>' and '<' are not necessary, but use '>>' for appending to output files.  
#===============================================================================
sub system_with_redirect
{
    @_ or return undef;
    my $opts = ( $_[0]  && ref $_[0]  eq 'HASH' ) ? shift
             : ( $_[-1] && ref $_[-1] eq 'HASH' ) ? pop
             :                                      {};
    @_ && defined $_[0] or return undef;
    my @cmd_and_args = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    @cmd_and_args && ( $cmd_and_args[0] = executable_for( $cmd_and_args[0] ) )
        or return -1;

    my $stat;
    if ( $have_ipc_run )
    {
        my @run_args = ( \@cmd_and_args );
        push @run_args, ipc_run_stdin(  $opts->{stdin}  );
        push @run_args, ipc_run_stdout( $opts->{stdout} );
        push @run_args, ipc_run_stderr( $opts->{stderr} );
        $stat = ! IPC::Run::run( @run_args );
    }
    else
    {
        my $pid;

        #  Parent process waits on its child
        if ( $pid = fork )
        {
            wait;
            $stat = $?;
        }

        #  Child process adjusts its file handles and does an exec()
        elsif ( defined $pid )
        {
	    local *STDIN = $REAL_STDIN;
	    local *STDOUT = $REAL_STDOUT;
	    local *STDERR = $REAL_STDERR;

            #  Give the child its own file handles, modified as requested
	    open STDIN,  fixin(  $opts->{stdin}  ) if defined $opts->{stdin};
	    open STDOUT, fixout( $opts->{stdout} ) if defined $opts->{stdout};
	    open STDERR, fixout( $opts->{stderr} ) if defined $opts->{stderr};
            exec( @cmd_and_args );
            # point of no return
        }

        else
        {
            my $cmd = join( ' ', @cmd_and_args );
            print STDERR "Failed to fork '$cmd'.\n";
            $stat = -1;
        }
    }

    $stat;
}


sub write_to_pipe_with_redirect
{
    @_ or return undef;
    my $opts = ( $_[0]  && ref $_[0]  eq 'HASH' ) ? shift
             : ( $_[-1] && ref $_[-1] eq 'HASH' ) ? pop
             :                                      {};
    @_ && defined $_[0] or return undef;
    my @cmd_and_args = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    @cmd_and_args && ( $cmd_and_args[0] = executable_for( $cmd_and_args[0] ) )
        or return -1;

    if ( $have_ipc_run )
    {
        my ( $fh, $output );
        my @run_args = ( \@cmd_and_args, '<pipe', \*IPC_IN );
        push @run_args, ipc_run_stdout( $opts->{stdout} );
        push @run_args, ipc_run_stderr( $opts->{stderr} );
        return \*IPC_IN if IPC::Run::run( @run_args );
        my $cmd = join( ' ', @cmd_and_args );
        print STDERR "Failed IPC::Run::run() of '$cmd'.\n";
        return undef;
    }

    #  Parent process returns file handle
    my ( $pid, $fh );
    return $fh if ( $pid = open( $fh, '|-' ) );

    #  Child process adjusts its file handles and does an exec()
    if ( defined $pid )
    {
        #  Give the child its own file handles, modified as requested
        open STDOUT, fixout( $opts->{stdout} ) if defined $opts->{stdout};
        open STDERR, fixout( $opts->{stderr} ) if defined $opts->{stderr};
        exec( @cmd_and_args );
        # point of no return
    }

    #  Fork failed
    my $cmd = join( ' ', @cmd_and_args );
    print STDERR "Failed to fork write to '$cmd'.\n";
    return undef;
}


sub read_from_pipe_with_redirect
{
    @_ or return undef;
    my $opts = ( $_[0]  && ref $_[0]  eq 'HASH' ) ? shift
             : ( $_[-1] && ref $_[-1] eq 'HASH' ) ? pop
             :                                      {};
    @_ && defined $_[0] or return undef;
    my @cmd_and_args = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;

    @cmd_and_args && ( $cmd_and_args[0] = executable_for( $cmd_and_args[0] ) )
        or return -1;

    if ( $have_ipc_run )
    {
        my ( $fh, $output );
        my @run_args = ( \@cmd_and_args, '>pipe', \*IPC_OUT );
        push @run_args, ipc_run_stdin(  $opts->{stdin} );
        push @run_args, ipc_run_stderr( $opts->{stderr} );
        return \*IPC_OUT if IPC::Run::run( @run_args );
        my $cmd = join( ' ', @cmd_and_args );
        print STDERR "Failed IPC::Run::run() of '$cmd'.\n";
        return undef;
    }

    #  Parent process returns file handle
    my ( $pid, $fh );
    return $fh if ( $pid = open( $fh, '-|' ) );

    #  Child process adjusts its file handles and does an exec()
    if ( defined $pid )
    {
        #  Give the child its own file handles, modified as requested
        open STDIN,  fixin(  $opts->{stdin}  ) if defined $opts->{stdin};
        open STDERR, fixout( $opts->{stderr} ) if defined $opts->{stderr};
        exec( @cmd_and_args );
        # point of no return
    }

    #  Fork failed
    my $cmd = join( ' ', @cmd_and_args );
    print STDERR "Failed to fork read from '$cmd'.\n";
    return undef;
}


#  Format an input file request:

sub fixin
{
    local $_ = shift;
    return ( ! defined $_ )    ? '<-'
         : /^(\+?<)\s*(\S.*)$/ ? "$1$2"
         : /^(.+)$/            ? "<$1"
         :                       '<-';
}


#  Format an output file request:

sub fixout
{
    local $_ = shift;
    return ( ! defined $_ )         ? '>-'
         : /^(\+?>{1,2})\s*(\S.*)$/ ? "$1$2"
         : /^(.+)$/                 ? ">$1"
         :                            '>-';
}


#  Format file requests for IPC::Run:

sub ipc_run_stdin
{
    local $_ = shift;
    return ( ! defined $_ )  ? ()
         : ref( $_ )         ? ( '<', $_ )
         : /^\+?<\s*(\S.*)$/ ? ( '<', $1 )
         : /^(.+)$/          ? ( '<', $1 )
         :                     ();
}

sub ipc_run_stdout
{
    local $_ = shift;
    return ( ! defined $_ )      ? ()
         : ref( $_ )             ? ( '>', $_ )
         : /^\+?(>>?)\s*(\S.*)$/ ? ( $1,  $2 )
         : /^(.+)$/              ? ( '>', $1 )
         :                         ();
}

sub ipc_run_stderr
{
    my @list = ipc_run_stdout( @_ );
    $list[0] = "2$list[0]" if @list;
    @list;
}


#===============================================================================
#  Fork a command and read its output without invoking a shell.  This is
#  safer than the perl pipe command, which runs the command in a shell.
#  But note that these commands only work for simple commands, not complex
#  pipes (though the user could make a command file that implements any pipe
#  desired).
#
#      $string = run_gathering_output( $cmd, @args )
#      @lines  = run_gathering_output( $cmd, @args )
#
#  This command is meant of situations in which the expected volume of output
#  will not stress the available memory.  For larger volumes of output that
#  can be processed a line at a time, there is the run_line_by_line() function.
#
#  Note that it is faster to read the whole output to a string and then split
#  it than it is to use the array form of the command.  Also note that it
#  is faster to use the output as the list of a foreach statement than to
#  put it into an array.  The line-by-line form is slowest, but, as noted
#  above, will handle arbitrarily large outputs.
#
#-----------------------------------------------------------------------------
#  Command                                                            Time (sec)
#-----------------------------------------------------------------------------
#  my $data = run_gathering_output( 'cat', 'big_file' );                  0.3
#  my @data = split /\n/, run_gathering_output( 'cat', 'big_file' );      1.4
#  my @data = run_gathering_output( 'cat', 'big_file' );                  1.9
#
#  foreach ( split /\n/, run_gathering_output( 'cat', 'big_file' ) ) {};  0.9
#  foreach ( run_gathering_output( 'cat', 'big_file' ) ) {};              1.5
#  while ( $_ = run_line_by_line( 'cat', 'big_file' ) ) {};               2.2
#-----------------------------------------------------------------------------
#
#  run_line_by_line()
#
#      while ( $line = SeedAware::run_line_by_line( $cmd, @args ) ) { ... }
#
#      my $cmd_and_args = [ $cmd, @args ];
#      while ( $line = SeedAware::run_line_by_line( $cmd_and_args ) ) { ... }
#
#  Run a command, reading output line-by-line. This is similar to an input pipe,
#  but it does not invoke the shell. Note that the argument list must be passed
#  one command line argument per function argument.  Subsequent calls with the
#  same command and args return sequential lines.  Multiple instances with
#  different comands or args can be interlaced, with the command and args
#  serving as a key to the stream to be read.  Thus, the second form can be
#  run in multiple instances by using different array references.  For unclear
#  reasons, this version is slower.
#
#  Close the file handle before end of file:
#
#      close_line_by_line( $cmd, @args )
#      close_line_by_line( $cmd_and_args )
#
#  Find out the file handle associated with the command and args:
#
#      $fh = line_by_line_fh( $cmd, @args )
#      $fh = line_by_line_fh( $cmd_and_args )
#
#===============================================================================

sub run_gathering_output
{
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    return () if ! ( @_ && defined $_[0] );

    #
    # Run the command in a safe fork-with-pipe/exec.
    #
    my @cmd_and_args = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
    my $name = join( ' ', @cmd_and_args );

    if ($have_ipc_run)
    {
        my $out;
        my $ok = IPC::Run::run(\@cmd_and_args, '>', \$out);
        if (wantarray)
        {
            my @out;
            open(my $fh, "<", \$out);
            @out = <$fh>;
            close($fh);
            return @out;
        }
        else
        {
            return $out;
        }
    }

    open( PROC_READ, '-|', @cmd_and_args ) || die "Could not execute '$name': $!\n";

    if ( wantarray )
    {
        my @out;
        local $_;
        while( <PROC_READ> ) { push @out, $_ }  # Faster than @out = <PROC_READ>
        close( PROC_READ ) or confess "FAILED: '$name' with error return $?";
        return @out;
    }
    else
    {
        my $out = '';
        my $inc = 1048576;
        my $end =       0;
        my $read;
        while ( $read = read( PROC_READ, $out, $inc, $end ) ) { $end += $read }
        close( PROC_READ ) or die "FAILED: '$name' with error return $?";
        return $out;
    }
}


#  Deal with multiple streams
my %handles;

sub run_line_by_line
{
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    return () if ! ( @_ && defined $_[0] );

    my $key  = join( ' ', @_ );

    my $fh;
    if ( ! ( $fh = $handles{ $key } ) )
    {
        #
        #  Run the command in a safe fork-with-pipe/exec.
        #
        my @cmd_and_args = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_;
        my $name = join( ' ', @cmd_and_args );
        open( $fh, '-|', @cmd_and_args ) || die "Could not exec '$name':\n$!\n";
        $handles{ $key } = $fh;
    }

    my $line = <$fh>;
    if ( ! defined( $line ) )
    {
        delete( $handles{ $key } );
        close( $fh );
    }

    $line;
}

#
#  Provide a method to close the pipe early.
#
sub close_line_by_line
{
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    return undef if ! ( @_ && defined $_[0] );

    my $name = join( ' ', @_ );
    my $fh;
    ( $fh = $handles{ $name } ) or return undef;
    delete( $handles{ $name } );
    close( $fh );
}

#
#  Provide a method to learn the file handle.  This could create problems
#  if the caller does something bad.  One possible use is simply to see if
#  the pipe exists.
#
sub line_by_line_fh
{
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    return undef if ! ( @_ && defined $_[0] );
    $handles{ join( ' ', @_ ) };
}


#-----------------------------------------------------------------------------
#  Read the entire contents of a file or stream into a string.  This command
#  if similar to $string = join( '', <FH> ), but reads the input by blocks.
#
#     $string = SeedAware::slurp_input( )                 # \*STDIN
#     $string = SeedAware::slurp_input(  $filename )
#     $string = SeedAware::slurp_input( \*FILEHANDLE )
#
#-----------------------------------------------------------------------------
sub slurp_input
{
    my $file = shift;
    my ( $fh, $close );
    if ( ref $file eq 'GLOB' )
    {
        $fh = $file;
    }
    elsif ( $file )
    {
        if    ( -f $file )                    { $file = "<$file" }
        elsif ( $_[0] =~ /^<(.*)$/ && -f $1 ) { }  # Explicit read
        else                                  { return undef }
        open $fh, $file or return undef;
        $close = 1;
    }
    else
    {
        $fh = \*STDIN;
    }

    my $out =      '';
    my $inc = 1048576;
    my $end =       0;
    my $read;
    while ( $read = read( $fh, $out, $inc, $end ) ) { $end += $read }
    close $fh if $close;

    $out;
}


#===============================================================================
#  Locate commands in special bin directories
#
#  $command = SeedAware::executable_for( $command, \%options )
#
#  Currently, no options are supported.
#===============================================================================
sub executable_for
{
    my ( $prog, $opts ) = @_;

    return undef if ! defined( $prog ) || $prog !~ /\S/;   # undefined or empty
    return ( -x $prog ? $prog : undef ) if $prog =~ /[\\\/]/;  # includes path
    $opts ||= {};

    if ( $in_SEED )
    {
        foreach my $bin ( $FIG_Config::blastbin, $FIG_Config::ext_bin )
        {
            return "$bin/$prog" if defined $bin && -d $bin && -x "$bin/$prog";
        }
    }

    #  If we cannot get the search path, return the program name

    return $prog if ! $ENV{PATH};

    # Explicit windows support.

    if ($^O eq 'MSWin32')
    {
        foreach my $bin ( split /;/, $ENV{PATH} )
        {
            next if $bin eq '' || ! -d $bin;
            for my $suffix ('', '.exe', '.cmd', '.bat')
            {
                my $tmp = "$bin\\$prog$suffix";
                if (-x $tmp)
                {
                    return $tmp;
                }
            }
        }
    }
    else
    {
        foreach my $bin ( split /:/, $ENV{PATH} )
        {
            return "$bin/$prog" if defined $bin && -d $bin && -x "$bin/$prog";
        }
    }

    return undef;   # fall-through means it is not in the path
}


#===============================================================================
#  Locate the directory for temporary files in a SEED-aware, but not SEED-
#  dependent manner:
#
#     $tmp = SeedAware::location_of_tmp( \%options )
#
#===============================================================================
sub location_of_tmp
{
    my $options = ref( $_[0] ) eq 'HASH' ? shift : {};

    foreach my $tmp ( $options->{tmp}, $FIG_Config::temp, $ENV{TEMP}, $ENV{TMPDIR}, $ENV{TEMPDIR}, '/tmp', '.' )
    {
       return $tmp if defined $tmp && -d $tmp && -w $tmp;
    }

    return undef;
}


#===============================================================================
#  Locate or create a temporary directory for files in a SEED-aware, but not
#  SEED-dependent manner.  The placement of the directory depends on the
#  environment, or can be specified as an option.
#
#     $tmp_dir              = SeedAware::temporary_directory( $name, \%opts )
#   ( $tmp_dir, $save_dir ) = SeedAware::temporary_directory( $name, \%opts )
#     $tmp_dir              = SeedAware::temporary_directory(        \%opts )
#   ( $tmp_dir, $save_dir ) = SeedAware::temporary_directory(        \%opts )
#
#  If $name is supplied, the directory in "tmp" is to have this name.
#  $save_dir indicates that the directory already existed, and should not be
#  deleted.
#
#  Options:
#
#     base     => $base      # Base string for name of directory
#     name     => $name      # Name for directory in "tmp"
#     save_dir => $bool      # Set $save_dir output (don't delete when done)
#     tmp      => $tmp       # Directory in which the directory is to be placed
#     tmp_dir  => $tmp_dir   # Name of the directory including implicit or
#                                   explict path.  This option overrides name.
#
#  The options       { tmp => 'my_home', name => 'my_name' }
#  are equivalent to { tmp_dir => 'my_home/my_name' }
#
#===============================================================================
sub temporary_directory
{
    my $name    = defined( $_[0] ) && ! ref( $_[0] )           ? shift : undef;
    my $options = defined( $_[0] ) &&   ref( $_[0] ) eq 'HASH' ? shift : {};

    my $save_dir = $options->{ savedir } || $options->{ save_dir };

    my $tmp_dir = $options->{ tmpdir } || $options->{ tmp_dir };
    if ( defined $tmp_dir && length $tmp_dir )
    {
        $save_dir = $options->{ save_dir } = 1 if -d $tmp_dir;
    }
    else
    {
        $name = $options->{ name } if ! ( defined $name && $name ne '' );

        if ( defined $name && $name ne '' )
        {
            my $tmp = location_of_tmp( $options );
            return ( wantarray ? () : undef ) if ! $tmp;
            $tmp_dir = "$tmp/$name";
            $save_dir = $options->{ save_dir } = 1 if -d $tmp_dir;
        }
        else
        {
            my $base = $options->{ base } || 'tmp_dir';
            $tmp_dir = tmp_file_name( $base );
        }
    }

    if ( ! -d $tmp_dir )
    {
        mkdir $tmp_dir or return ( wantarray ? () : undef );
    }

    wantarray ? ( $tmp_dir, $save_dir ) : $tmp_dir;
}


#===============================================================================
#  Create a name for a new file or directory that will not clobber an existing
#  one. File name DOES NOT INCLUDE the directory (unless it is supplied as
#  part of the base_name).
#
#     $file_name = new_file_name( )
#     $file_name = new_file_name( $base_name )
#     $file_name = new_file_name( $base_name, $extention )
#     $file_name = new_file_name( $base_name, $extention, $in_directory )
#
#  The name is derived by adding an underscore and 8 random characterss (or
#  12 random digits) to a base file name (D = temp) in a directory (D = .).
#  To handle some old code, the base name can include the directory.
#===============================================================================
sub new_file_name
{
    my ( $base, $ext, $dir ) = @_;

    if ( defined $base && ! ( defined $dir && length $dir ) && $base =~ m#^(.*/)([^/]*)$# )
    {
        ( $dir, $base ) = ( $1, $2 );
        return tmp_file_name( $base, $ext, $dir );
    }

    $base =  'temp' if ! ( defined $base && length $base );
    $base =~ /_$/ or $base .= '_';  # End base with _

    $ext  = ''     if !   defined $ext;
    $ext  =~ s/^([^.])/.$1/;   # Start ext with .

    $dir  = '.'  if ! defined $dir && $base !~ m,^/,;

    my ( $fh, $name );
    if ( eval { require File::Temp } )
    {
        $base .= 'XXXXXXXX';
        my @args = ( $base, OPEN => 0 );
        push @args, ( SUFFIX => $ext ) if $ext;
        push @args, ( DIR    => $dir ) if $dir;
        {
            no warnings;
            ( undef, $name ) = File::Temp::tempfile( @args );
        }

        $name =~ s/^.*[\/\\]//;  # Remove directory (unix or windows)
    }
    #  Fall back to my old method if we do not have File::Temp
    else
    {
        if ( length $dir )
        {
            $dir =~ /\/$/ or $dir .= '/';  # End dir with /
            $base = "$dir$base";
        }
        while ( 1 )
        {
            my $r  = rand( 1e6 );
            my $ir = int( $r );
            $name  = sprintf "%s%06d%06d%s", $base, $ir, int(1e6*($r-$ir)), $ext;
            last if ! -e "$dir$name";
        }
    }

    $name;
}


#===============================================================================
#  Create a name for a new file or directory that will not clobber an existing
#  one. File name INCLUDES any directory supplied.
#
#     $path_name = tmp_file_name( )
#     $path_name = tmp_file_name( $base_name )
#     $path_name = tmp_file_name( $base_name, $extention )
#     $path_name = tmp_file_name( $base_name, $extention, $in_directory )
#
#  Create and open new file that will not clobber an existing one.
#  File name INCLUDES any directory supplied.
#
#     ( $fh, $path_name ) = open_tmp_file( )
#     ( $fh, $path_name ) = open_tmp_file( $base_name )
#     ( $fh, $path_name ) = open_tmp_file( $base_name, $extention )
#     ( $fh, $path_name ) = open_tmp_file( $base_name, $extention, $in_directory )
#
#  The name is derived by adding an underscore and 8 random characterss (or
#  12 random digits) to a base file name (D = temp) in a directory
#  (D = location_of_tmp()). This means there will always be a directory,
#  even if just './'.
#===============================================================================
sub tmp_file_name
{
    my $name;
    if ( eval { require File::Temp } )
    {
        my ( $base, $ext, $dir ) = tmp_file_defaults( @_ );
        return undef if ! $base;
        $base .= 'XXXXXXXX';      # complete the template

        my @args = ( $base, OPEN => 0, DIR => $dir );
        push @args, ( SUFFIX => $ext ) if $ext;
        {
            no warnings;
            # print STDERR "1\n";
            ( undef, $name ) = File::Temp::tempfile( @args );
            # print STDERR "2\n";
        }
    }

    #  Fall back to my old method if we do not have File::Temp
    else
    {
        $name = classic_file_name( @_ );
    }

    $name;
}


sub open_tmp_file
{
    my ( $fh, $name );
    if ( eval { require File::Temp } )
    {
        my ( $base, $ext, $dir ) = tmp_file_defaults( @_ );
        return () if ! $base;
        $base .= 'XXXXXXXX';

        my @args = ( $base, DIR => $dir );
        push @args, ( SUFFIX => $ext ) if $ext;
        ( $fh, $name ) = File::Temp::tempfile( @args );
    }

    #  Fall back to my old method if we do not have File::Temp
    else
    {
        $name = classic_file_name( @_ ) and open( $fh, '>', $name );
    }

    ( $fh, $name );
}


sub tmp_file_defaults
{
    my ( $base, $ext, $dir ) = @_;

    if ( defined $base && ! ( defined $dir && length $dir ) && $base =~ m#^(.*[/\\])([^/\\]*)$# )
    {
        ( $dir, $base ) = ( $1, $2 );
    }

    $base  =  'temp' if ! ( defined $base && length $base );
    $base  =~ m/_$/ or $base .= '_';  # End base with _

    $ext  = ''     if !   defined $ext;
    $ext  =~ s/^([^.])/.$1/;   # Start ext with .

    $dir  =  location_of_tmp( ) if ! ( defined $dir && length $dir );
    return () if ! defined $dir;
    $dir  =~ m/\/$/ || ( $dir .= '/' );       # End dir with /

    ( $base, $ext, $dir );
}


sub classic_file_name
{
    my ( $base, $ext, $dir ) = tmp_file_defaults( @_ );
    return undef if ! $base;

    my $name;
    while ( 1 )
    {
        my $r  = rand( 1e6 );
        my $n1 = int( $r );
        my $n2 = int( 1e6 * ($r - $n1) );
        my $dig = sprintf "%06d%06d", $n1, $n2;
        $name  = $dir . $base . $dig . $ext;
        last if ! -e $name;
    }

    $name;
}


1;
