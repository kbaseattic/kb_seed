########################################################################################
#
#    This file was generated using Parse::Eyapp version 1.182.
#
# (c) Parse::Yapp Copyright 1998-2001 Francois Desarmenien.
# (c) Parse::Eyapp Copyright 2006-2008 Casiano Rodriguez-Leon. Universidad de La Laguna.
#        Don't edit this file, use source file 'pipeline.yp' instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
########################################################################################
package Bio::KBase::InvocationService::PipelineGrammar;
use strict;

push @Bio::KBase::InvocationService::PipelineGrammar::ISA, 'Parse::Eyapp::Driver';




BEGIN {
  # This strange way to load the modules is to guarantee compatibility when
  # using several standalone and non-standalone Eyapp parsers

  require Parse::Eyapp::Driver unless Parse::Eyapp::Driver->can('YYParse');
  require Parse::Eyapp::Node unless Parse::Eyapp::Node->can('hnew'); 
}
  

sub unexpendedInput { defined($_) ? substr($_, (defined(pos $_) ? pos $_ : 0)) : '' }

#line 4 "pipeline.yp"




# Default lexical analyzer
our $LEX = sub {
    my $self = shift;
    my $pos;

    for (${$self->input}) {
      

      /\G([ \t]+)/gc and $self->tokenline($1 =~ tr{\n}{});

      m{\G(\>\>|\<|\||\>)}gc and return ($1, $1);

      /\G((?:http|ftp):\/\/\S+)/gc and return ('URL', $1);
      /\G([a-zA-Z0-9-_.]*(?:\/[a-zA-Z0-9-_.]*)+)/gc and return ('PATH', $1);
      /\G([a-zA-Z][a-zA-Z0-9-_.]*)/gc and return ('TERM', $1);
      /\G(-[a-zA-Z][a-zA-Z0-9-_]*)/gc and return ('OPTION', $1);
      /\G([a-zA-Z0-9-_]+)/gc and return ('GENERAL_TERM', $1);
      /\G"((?:[^\\"]|\\.)*)"/gc and return ('DQSTRING', $1);
      /\G'((?:[^\\']|\\.)*)'/gc and return ('SQSTRING', $1);


      return ('', undef) if ($_ eq '') || (defined(pos($_)) && (pos($_) >= length($_)));
      /\G\s*(\S+)/;
      my $near = substr($1,0,10); 

      return($near, $near);

     # die( "Error inside the lexical analyzer near '". $near
     #     ."'. Line: ".$self->line()
     #     .". File: '".$self->YYFilename()."'. No match found.\n");
    }
  }
;


#line 71 Bio/KBase/InvocationService/PipelineGrammar.pm

my $warnmessage =<< "EOFWARN";
Warning!: Did you changed the \@Bio::KBase::InvocationService::PipelineGrammar::ISA variable inside the header section of the eyapp program?
EOFWARN

sub new {
  my($class)=shift;
  ref($class) and $class=ref($class);

  warn $warnmessage unless __PACKAGE__->isa('Parse::Eyapp::Driver'); 
  my($self)=$class->SUPER::new( 
    yyversion => '1.182',
    yyGRAMMAR  =>
[#[productionNameAndLabel => lhs, [ rhs], bypass]]
  [ '_SUPERSTART' => '$start', [ 'start', '$end' ], 0 ],
  [ 'start_1' => 'start', [ 'pipeline' ], 0 ],
  [ 'pipeline_2' => 'pipeline', [ 'pipe_item' ], 0 ],
  [ 'pipeline_3' => 'pipeline', [ 'pipeline', '|', 'pipe_item' ], 0 ],
  [ 'pipe_item_4' => 'pipe_item', [ 'command', 'args', 'redirections' ], 0 ],
  [ 'command_5' => 'command', [ 'TERM' ], 0 ],
  [ 'args_6' => 'args', [  ], 0 ],
  [ 'args_7' => 'args', [ 'arg' ], 0 ],
  [ 'args_8' => 'args', [ 'args', 'arg' ], 0 ],
  [ 'arg_9' => 'arg', [ 'TERM' ], 0 ],
  [ 'arg_10' => 'arg', [ 'SQSTRING' ], 0 ],
  [ 'arg_11' => 'arg', [ 'DQSTRING' ], 0 ],
  [ 'arg_12' => 'arg', [ 'OPTION' ], 0 ],
  [ 'arg_13' => 'arg', [ 'GENERAL_TERM' ], 0 ],
  [ 'redirections_14' => 'redirections', [  ], 0 ],
  [ 'redirections_15' => 'redirections', [ 'redirection' ], 0 ],
  [ 'redirections_16' => 'redirections', [ 'redirections', 'redirection' ], 0 ],
  [ 'redirection_17' => 'redirection', [ '<', 'path' ], 0 ],
  [ 'redirection_18' => 'redirection', [ '>', 'path' ], 0 ],
  [ 'redirection_19' => 'redirection', [ '>>', 'path' ], 0 ],
  [ 'path_20' => 'path', [ 'PATH' ], 0 ],
  [ 'path_21' => 'path', [ 'TERM' ], 0 ],
  [ 'path_22' => 'path', [ 'URL' ], 0 ],
],
    yyLABELS  =>
{
  '_SUPERSTART' => 0,
  'start_1' => 1,
  'pipeline_2' => 2,
  'pipeline_3' => 3,
  'pipe_item_4' => 4,
  'command_5' => 5,
  'args_6' => 6,
  'args_7' => 7,
  'args_8' => 8,
  'arg_9' => 9,
  'arg_10' => 10,
  'arg_11' => 11,
  'arg_12' => 12,
  'arg_13' => 13,
  'redirections_14' => 14,
  'redirections_15' => 15,
  'redirections_16' => 16,
  'redirection_17' => 17,
  'redirection_18' => 18,
  'redirection_19' => 19,
  'path_20' => 20,
  'path_21' => 21,
  'path_22' => 22,
},
    yyTERMS  =>
{ '' => { ISSEMANTIC => 0 },
	'<' => { ISSEMANTIC => 0 },
	'>' => { ISSEMANTIC => 0 },
	'>>' => { ISSEMANTIC => 0 },
	'|' => { ISSEMANTIC => 0 },
	DQSTRING => { ISSEMANTIC => 1 },
	GENERAL_TERM => { ISSEMANTIC => 1 },
	OPTION => { ISSEMANTIC => 1 },
	PATH => { ISSEMANTIC => 1 },
	SQSTRING => { ISSEMANTIC => 1 },
	TERM => { ISSEMANTIC => 1 },
	URL => { ISSEMANTIC => 1 },
	error => { ISSEMANTIC => 0 },
},
    yyFILENAME  => 'pipeline.yp',
    yystates =>
[
	{#State 0
		ACTIONS => {
			'TERM' => 2
		},
		GOTOS => {
			'pipe_item' => 1,
			'pipeline' => 3,
			'start' => 5,
			'command' => 4
		}
	},
	{#State 1
		DEFAULT => -2
	},
	{#State 2
		DEFAULT => -5
	},
	{#State 3
		ACTIONS => {
			"|" => 6
		},
		DEFAULT => -1
	},
	{#State 4
		ACTIONS => {
			'OPTION' => 7,
			'DQSTRING' => 12,
			'SQSTRING' => 13,
			'GENERAL_TERM' => 8,
			'TERM' => 10
		},
		DEFAULT => -6,
		GOTOS => {
			'arg' => 9,
			'args' => 11
		}
	},
	{#State 5
		ACTIONS => {
			'' => 14
		}
	},
	{#State 6
		ACTIONS => {
			'TERM' => 2
		},
		GOTOS => {
			'pipe_item' => 15,
			'command' => 4
		}
	},
	{#State 7
		DEFAULT => -12
	},
	{#State 8
		DEFAULT => -13
	},
	{#State 9
		DEFAULT => -7
	},
	{#State 10
		DEFAULT => -9
	},
	{#State 11
		ACTIONS => {
			'OPTION' => 7,
			"<" => 16,
			'DQSTRING' => 12,
			'SQSTRING' => 13,
			'GENERAL_TERM' => 8,
			'TERM' => 10,
			">>" => 20,
			">" => 21
		},
		DEFAULT => -14,
		GOTOS => {
			'arg' => 17,
			'redirections' => 18,
			'redirection' => 19
		}
	},
	{#State 12
		DEFAULT => -11
	},
	{#State 13
		DEFAULT => -10
	},
	{#State 14
		DEFAULT => 0
	},
	{#State 15
		DEFAULT => -3
	},
	{#State 16
		ACTIONS => {
			'URL' => 22,
			'TERM' => 25,
			'PATH' => 24
		},
		GOTOS => {
			'path' => 23
		}
	},
	{#State 17
		DEFAULT => -8
	},
	{#State 18
		ACTIONS => {
			"<" => 16,
			">" => 21,
			">>" => 20
		},
		DEFAULT => -4,
		GOTOS => {
			'redirection' => 26
		}
	},
	{#State 19
		DEFAULT => -15
	},
	{#State 20
		ACTIONS => {
			'URL' => 22,
			'TERM' => 25,
			'PATH' => 24
		},
		GOTOS => {
			'path' => 27
		}
	},
	{#State 21
		ACTIONS => {
			'URL' => 22,
			'TERM' => 25,
			'PATH' => 24
		},
		GOTOS => {
			'path' => 28
		}
	},
	{#State 22
		DEFAULT => -22
	},
	{#State 23
		DEFAULT => -17
	},
	{#State 24
		DEFAULT => -20
	},
	{#State 25
		DEFAULT => -21
	},
	{#State 26
		DEFAULT => -16
	},
	{#State 27
		DEFAULT => -19
	},
	{#State 28
		DEFAULT => -18
	}
],
    yyrules  =>
[
	[#Rule _SUPERSTART
		 '$start', 2, undef
#line 320 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule start_1
		 'start', 1, undef
#line 324 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule pipeline_2
		 'pipeline', 1,
sub {
#line 25 "pipeline.yp"
my $item = $_[1];  [ $item ] }
#line 331 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule pipeline_3
		 'pipeline', 3,
sub {
#line 26 "pipeline.yp"
my $item = $_[3]; my $pipeline = $_[1];  [ @$pipeline, $item ] }
#line 338 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule pipe_item_4
		 'pipe_item', 3,
sub {
#line 29 "pipeline.yp"
my $redir = $_[3]; my $cmd = $_[1]; my $args = $_[2];  { cmd => $cmd, args => $args, redir => $redir } }
#line 345 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule command_5
		 'command', 1, undef
#line 349 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule args_6
		 'args', 0,
sub {
#line 35 "pipeline.yp"
 [] }
#line 356 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule args_7
		 'args', 1,
sub {
#line 36 "pipeline.yp"
my $arg = $_[1];  [ $arg ] }
#line 363 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule args_8
		 'args', 2,
sub {
#line 37 "pipeline.yp"
my $arg = $_[2]; my $args = $_[1];  [ @$args, $arg ] }
#line 370 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule arg_9
		 'arg', 1, undef
#line 374 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule arg_10
		 'arg', 1, undef
#line 378 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule arg_11
		 'arg', 1, undef
#line 382 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule arg_12
		 'arg', 1, undef
#line 386 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule arg_13
		 'arg', 1, undef
#line 390 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirections_14
		 'redirections', 0,
sub {
#line 47 "pipeline.yp"
 [] }
#line 397 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirections_15
		 'redirections', 1,
sub {
#line 48 "pipeline.yp"
my $item = $_[1];  [ $item ] }
#line 404 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirections_16
		 'redirections', 2,
sub {
#line 49 "pipeline.yp"
my $item = $_[2]; my $list = $_[1];  [ @$list, $item ] }
#line 411 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirection_17
		 'redirection', 2,
sub {
#line 52 "pipeline.yp"
my $path = $_[2];  [ '<', $path ] }
#line 418 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirection_18
		 'redirection', 2,
sub {
#line 53 "pipeline.yp"
my $path = $_[2];  [ '>', $path ] }
#line 425 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule redirection_19
		 'redirection', 2,
sub {
#line 54 "pipeline.yp"
my $path = $_[2];  [ '>>', $path ] }
#line 432 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule path_20
		 'path', 1, undef
#line 436 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule path_21
		 'path', 1, undef
#line 440 Bio/KBase/InvocationService/PipelineGrammar.pm
	],
	[#Rule path_22
		 'path', 1, undef
#line 444 Bio/KBase/InvocationService/PipelineGrammar.pm
	]
],
#line 447 Bio/KBase/InvocationService/PipelineGrammar.pm
    yybypass       => 0,
    yybuildingtree => 0,
    yyprefix       => '',
    yyaccessors    => {
   },
    yyconflicthandlers => {}
,
    yystateconflict => {  },
    @_,
  );
  bless($self,$class);

  $self->make_node_classes('TERMINAL', '_OPTIONAL', '_STAR_LIST', '_PLUS_LIST', 
         '_SUPERSTART', 
         'start_1', 
         'pipeline_2', 
         'pipeline_3', 
         'pipe_item_4', 
         'command_5', 
         'args_6', 
         'args_7', 
         'args_8', 
         'arg_9', 
         'arg_10', 
         'arg_11', 
         'arg_12', 
         'arg_13', 
         'redirections_14', 
         'redirections_15', 
         'redirections_16', 
         'redirection_17', 
         'redirection_18', 
         'redirection_19', 
         'path_20', 
         'path_21', 
         'path_22', );
  $self;
}



=for None

=cut


#line 494 Bio/KBase/InvocationService/PipelineGrammar.pm



1;
