#
# GridEntry is a composite widget that can be used to display
# an array of widget whose contents can be edited
#
# Author: Raman.P  Jan 2004
#
# The author can be contacted at
# <raamanp@yahoo.co.in>
#
# See end of this file for documentation.
#
# TO DO LIST
#  1. Derived columns - like rate x quantity=amount
#  2. Key column- validate duplicates
#  3. Auto summary for specified columns
#  4. Resizable columns


package GridEntry;

use vars qw($VERSION);

$VERSION = '1.0';

use Tk;
use strict;
use Carp;

require Tk::Frame;

use base qw(Tk::Frame);
Construct Tk::Widget 'GridEntry';


sub Populate {
    my ( $self, $args ) = @_;

	my ( $whash, $j, $key, $key1, $value, $wtype);
	my ( $element, $callback, $extend );

    $self->SUPER::Populate($args);
    $self->{whash} = delete $args->{-structure};

    $self->{rows}      = delete $args->{-rows};
    $self->{data}      = delete $args->{-datahash};
    $self->{extend}    = delete $args->{-extend};
    $self->{browsecmd} = delete $args->{-browsecmd};
    $self->{sumrow}    = delete $args->{-sumrow};
    $self->{scroll}    = delete $args->{-scroll};

    $self->{cols} = keys( %{ $self->{whash} } );

    $self->{pageindex} = 0;
    $self->{extended} = 0;
    $self->{rows}=10 if (!$self->{rows});
    $self->ConfigSpecs(
        -pageindex => [qw/METHOD  undef   undef/],
        -extend    => [ qw/METHOD  undef   undef/ ]
    );

    #Create a top level
	$self->packConfigure( 	-expand => 1, 
				-fill => 'both' );
    $self->{frame} =
      $self->Frame( 	-bd => 2, 
			-relief => 'raised', 
			-takefocus => '0' )
      		->pack( -expand => 1, 
			-fill => 'both' );
    $self->Advertise( 'frame', $self->{frame} );

    #First create title line

    $j     = 0;
    $whash = $self->{whash};

    #create label as first (0th) row
    foreach $key ( @{ $whash->{columns} } ) {
        $whash->{$key}{widget}{0} = $self->{frame}->Label(
            -text   => $whash->{$key}{label},
            -relief => 'groove'
        )->grid( -row => 0, -column => $j );
        $j++;
    }

    #Now let us build cells for each widget
    for ( $j = 1 ; $j <= $self->{rows} ; $j++ ) {


        foreach $key ( @{ $whash->{columns} } ) {
            $wtype = $whash->{$key}{widgettype};
            $whash->{$key}{widget}{$j} = 
		$self->{frame} ->${wtype}()->grid(
                		-row    => $j,
                		-column => "$whash->{$key}{col}",
                		-sticky => 'nsew'
            				);
    #If binds are given bind it now. Row id is passed to the
    # callback as argument.

            my ( @array, $k );
            if ( exists $whash->{$key}{bindings} ) {
                @array = split / /, $whash->{$key}{bindings};
                for ( $k = 0 ; $k < scalar(@array) ; $k++ ) {
                    $element = $array[$k];
                    $k++;
                    $callback = $array[$k];
                    $whash->{$key}{widget}{$j}
                      ->bind( "<$element>", [ \&$callback, $j ] );
                }

            }

            #Let us have standard bindings-PgUp,PgDn,Up,Down arrow keys
	    #Down arrow key
            $whash->{$key}{widget}{$j}->bind( '<Down>',
                [ \&keyArrow, $whash->{$key}{widget}{$j}, $self->{rows}, "1" ]
            );
            #Up arrow key
            $whash->{$key}{widget}{$j}->bind( '<Up>',
                [ \&keyArrow, $whash->{$key}{widget}{$j}, $self->{rows}, "-1" ]
            );
	    #Page Down key
            $whash->{$key}{widget}{$j}
              ->bind( '<Next>', [ \&keyPage, $self, "+1" ] );
	    #Page Up key
            $whash->{$key}{widget}{$j}
              ->bind( '<Prior>', [ \&keyPage, $self, "-1" ] );

	    #Now pass on attributes of individual widget.
	    #If starts with - then configure if with & then callback
            for $key1 ( %{ $whash->{$key} } ) {
                if ( ( $key1 =~ m/^-/i ) )    #if starts with - then configure
                {
                    $value = $whash->{$key}{$key1};
                    if ( ( $value =~ m/\&/ ) )    # if has & then callback
                    {
                        $whash->{$key}{widget}{$j}
                          ->configure( $key1 => [ ${value} ] );
                    }
                    else {
                        condConfigure( $whash->{$key}{widget}{$j},
                            "$key1", $value );

                    }
                }
            }
        }
    }

    #Configure grid column and row width - largest of label or 
    #widget width
    foreach $key ( @{ $whash->{columns} } ) {
        if ( $whash->{$key}{widget}{0}->cget( -width ) <
            $whash->{$key}{widget}{1}->cget( -width ) )
        {
            $self->{frame}->gridColumnconfigure( $whash->{$key}{col},
                -minsize => $whash->{$key}{widget}{1}->cget( -width ) );
        }
        else {
            $self->{frame}->gridColumnconfigure( $whash->{$key}{col},
                -minsize => $whash->{$key}{widget}{0}->cget( -width ) );
        }

        #if summary row is asked create a row
        #The text variable for each column will called value.
        if ( "$self->{sumrow}" eq "1" ) {
            $whash->{$key}{widget}{ $self->{rows} + 1 } = $self->{frame}->Entry(
                -textvariable => \$whash->{$key}{value},
                -width        => $whash->{$key}{widget}{0}->cget( -width ),
                -state        => 'disabled',
                -relief       => 'flat'
              )->grid(
                -row    => $self->{rows} + 1,
                -column => "$whash->{$key}{col}",
                -sticky => 'nsew'
              );
        }
    }

    #If scrollbutton is defined
    if ( $self->{scroll} > 0 ) {
        scrollbutton($self);
        $self->{prior_b}->configure(
            -command => [ \&keyPage, $self->{prior_b}, $self, "-1" ] );
        $self->{next_b}->configure(
            -command => [ \&keyPage, $self->{next_b}, $self, "+1" ] );
    }

}

#PageUp and Down
sub keyPage {
    my ( $widget, $self, $dir ) = @_;
    
      #$self->cget( -pageindex ), $self->{pageindex};
    
    my $pi        = $self->{pageindex};
    my $datahash  = $self->{data};
    #my $extend    = $self->cget( -extend );
    my $extend    = $self->{extend};
    my $extended    = $self->{extended};
    my $rows      = $self->{rows};
    my $browsecmd = $self->{-browsecmd};
    my $newpi     = $pi + $dir;
    my ( $size, $key, $maxpage );
    if ( $newpi < 0 ) { $newpi = 0; }

    #Now let us get maximum pages allowed
    for $key ( keys %$datahash ) {
        $size = scalar( @{ $datahash->{$key} } );
        last;
    }
    $maxpage = sprintf "%d", ( $size + ($extend-$extended) ) / $rows;
    if ( $maxpage == 0 ) { $maxpage = 1; }
    if ( ( $size + ($extend-$extended) ) % $maxpage > 0 ) { $maxpage++; }
    if ( $newpi > $maxpage ) { $newpi = $maxpage; }
    
    if ( $newpi != $pi ) {
        if ( defined $browsecmd ) {
            &$browsecmd();
        }

        $self->{pageindex} = $newpi;
        $self->moverectoscreen;
    }
  #move focus to first row first widget that can take focus

    jumpHome($self);
}

sub jumpHome {
    my ($self)         = @_;
    my $whash       = $self->{whash};
    my ($key,$state,$state1,$cb);

    #First execute currentfields focus out callback
    $cb = $self->focusCurrent()->bind('<FocusOut>');
    if ($cb) {

        &{ $cb->[0] }( $self->focusCurrent(), "$cb->[1]" );

    }
    foreach $key ( @{ $whash->{columns} } ) {

        $state = $whash->{$key}{widget}{1}->cget( -state );
        if ( "$state" ne "disabled" ) {
            $state1 = $whash->{$key}{widget}{1}->cget( -takefocus );
            if ( "$state1" ne "0" ) {
                $whash->{$key}{widget}{1}->focus();
            }
            else {
                $whash->{$key}{widget}{1}->focusNext;
            }
            $cb = $self->focusCurrent()->bind('<FocusIn>');
            if ($cb) {
                &{ $cb->[0] }( $self->focusCurrent(), "1" );
            }
            return;
        }
    }

}

#Call back for up or down arrow keys
sub keyArrow {
    my ( $widget, $self, $rows, $dir ) = @_;
    my %gI     = $self->gridInfo();
    my $newrow = $gI{-row} + $dir;

    if    ( $newrow < 1 )     { $newrow = $rows; }
    elsif ( $newrow > $rows ) { $newrow = 1; }
    $gI{-in}->gridSlaves( -row => $newrow,
			 -column => $gI{-column} )->focus();
}

#Call back to update widget with data 
sub moverectoscreen {
    my ($self) = @_;

    my $datahash = $self->{data};
    my $whash    = $self->{whash};
    my $rows     = $self->{rows};
    #my $extend   = $self->cget( -extend );
    my $extend   = $self->{extend};

    my $pi = $self->{pageindex};
    
    my $size     = 0;
    #my $extended = 0;
    my $extended = $self->{extended};
    my ($index,$dummy,$state,$key);

    $dummy = "";
    if ( !$pi ) { $pi = 0; }

    for $key ( keys %$datahash ) {
        $size = scalar( @{ $datahash->{$key} } );
        last;
    }
    for $key ( keys %$datahash ) {
        for ( my $i = 1 ; $i <= $rows ; $i++ ) {
            $index = ( $pi * $rows ) + $i - 1;
            if ( $index >= ( $size + ($extend-$extended) ) ) {
                #$extended++;  should we extend??

                $whash->{$key}{widget}{$i}->configure(
                    -textvariable => \$dummy,
                    -state        => 'disabled'
                );
            }
            else {

                if ( $index > $size ) { $extended++; }

                #put back -state
                if ( defined $whash->{$key}{-state} ) {
                    $state = $whash->{$key}{-state};
                }
                else { $state = "normal"; }
                
                $whash->{$key}{widget}{$i}
                  ->configure( -textvariable => \$datahash->{$key}[$index] );

                condConfigure( $whash->{$key}{widget}{$i}, "-state", $state );

            }
        }
    }
    	#if ( ( $extend - $extended ) < 0 ) { 
		#$self->configure( -extend => 0 ); 
	#}
    	#else { 
		#$self->configure( -extend => ( $extend - $extended ) ); 
	#}
	$self->{extended}=$extended;
#update the widget display
	$self->update();
}

#This callback clears the contents by setting textvariable to dummy var.
sub movenulltoscreen {
    my ($self)   = @_;
    my $datahash = $self->{data};
    my $whash    = $self->{whash};
    my $rows     = $self->{rows};
    my $key;
    my $dummy;

    for $key ( keys %$datahash ) {
        for ( my $i = 1 ; $i <= $rows ; $i++ ) {
            $whash->{$key}{widget}{$i}->configure( -textvariable => \$dummy );
        }
    }
    $dummy="";

}

#set/return extend
sub extend{
my ($self,$extend)=@_;
	return $self->{extend} if (! $extend);
	if ("$extend" eq "reset"){
		$self->{extended}=0;
		}
    if ($extend=~ /\D/) {carp "Extend should be a number ";return;}
	$self->{extend}=$extend;
	return $self->{extend};
}

#Set/returns page index. After setting moverectoscreen should be
#called manually.
sub pageindex {
    my ( $self, $newpi ) = @_;
      
    if ( !$newpi ) {
        return $self->{pageindex};
    }
    if ($newpi=~ /\D/) {carp "Page index should be a number ";return;}
    my ( $size, $key, $maxpage );
    my $pi       = $self->{pageindex};
    my $datahash = $self->{data};
    #my $extend   = $self->cget( -extend );
    my $extend   = $self->{extend};
    my $extended   = $self->{extended};
    my $rows     = $self->{rows};

	$newpi=0 if ("$newpi" eq "begin");
    	$newpi=0 if ( $newpi < 0 ) ;


    #Now let us get maximum pages allowed
    for $key ( keys %$datahash ) {
        $size = scalar( @{ $datahash->{$key} } );
        last;
    }
    $maxpage = sprintf "%d", ( $size + ($extend-$extended) ) / $rows;
    if ( $maxpage == 0 ) { $maxpage = 1; }
    if ( ( $size + ($extend-$extended) ) % $maxpage > 0 ) { $maxpage++; }
    $newpi=$maxpage if ("$newpi" eq "end");
    
    #check if newpi is an integer 
    if ($newpi=~ /\D/){carp "Invalid Index given";
			return;}

    if ( $newpi > $maxpage ) { 
				$newpi = $maxpage; 
				}
   
    $self->{pageindex} = $newpi;
    return $self->{pageindex};

}

#Returns the column total
sub sum {
    my ( $self, $col ) = @_;

    my $datahash = $self->cget( -datahash );
    my $i;
    my $result;
    return if ( ref( $datahash->{$col} ) ne "ARRAY" );
    for ( $i = 0 ; $i < scalar( @{ $datahash->{$col} } ) ; $i++ ) {
        $result += $datahash->{$col}[$i];
    }
    return $result;
}


#Returns current Row
sub curRow {
    my ($self) = @_;
    my %gI = $self->focusCurrent();
    return if ( !%gI );
    %gI = $self->focusCurrent()->gridInfo();
    return $gI{-row};
}

#Returns current Row
sub curCol {
    my ($self) = @_;
    my %gI = $self->focusCurrent();
    return if ( !%gI );
    %gI = $self->focusCurrent()->gridInfo();
    return $gI{-column};
}

#Some widget many not have some options we assume it has.Do a cond.configure
sub condConfigure {
    my ( $self, $option, $value ) = @_;
    my @config = $self->configure();
    my $key;

    for $key (@config) {
        if ( "$option" eq "@$key[0]" ) {
            $self->configure( $option => $value );
            return;
        }
    }
    carp "invalid option requested for Widget:$self Option:$option\n";
}

#This callback sets button for scrolling. The images are embbed in
#the widget itself for easy portability. 
sub scrollbutton {
    my ($self) = @_;
    my $icon = $self->{frame}->Pixmap( -data => <<INLINEDATA1);
/* XPM */
static char * prev_xpm[] = {
"20 20 62 1",
" 	c None",
".	c #CCD6D6",
"+	c #A0B4B4",
"@	c #708585",
"#	c #5F7A7A",
"\$	c #537373",
"%	c #607B7B",
"&	c #6F8484",
"*	c #D3D9D9",
"=	c #A3B5B5",
"-	c #546464",
";	c #404646",
">	c #5E5E5E",
",	c #818181",
"'	c #979797",
")	c #5D5D5D",
"!	c #404545",
"~	c #D4DADA",
"{	c #7C8F8F",
"]	c #373A3A",
"^	c #747474",
"/	c #AFAFAF",
"(	c #CCCCCC",
"_	c #454949",
":	c #8C8C8C",
"<	c #C7C7C7",
"[	c #949494",
"}	c #444747",
"|	c #A3B6B6",
"1	c #959595",
"2	c #C9C9C9",
"3	c #C8C8C8",
"4	c #CDD6D6",
"5	c #546363",
"6	c #727272",
"7	c #B1B1B1",
"8	c #838383",
"9	c #3E4343",
"0	c #9DB2B2",
"a	c #7B7B7B",
"b	c #222222",
"c	c #242424",
"d	c #1A1A1A",
"e	c #7F7F7F",
"f	c #5F7B7B",
"g	c #848484",
"h	c #517272",
"i	c #547373",
"j	c #212121",
"k	c #767676",
"l	c #A1A1A1",
"m	c #444444",
"n	c #3D3D3D",
"o	c #3C3C3C",
"p	c #424242",
"q	c #3A3A3A",
"r	c #A3A3A3",
"s	c #3E4444",
"t	c #373B3B",
"u	c #9DB1B1",
"v	c #9FB4B4",
"w	c #CBD6D6",
"     .+@#\$\$%&+.     ",
"   *=-;>,'',)!-=*   ",
"  ~{]^/((((((/^]{~  ",
" *{_:<((((((((<[}{* ",
" |]12((((((((((3[]| ",
"456<((((((((((((<654",
"+!7(((((<88<(((((/90",
"&)((((((abba(((((()@",
"%,((((<acddca<((((ef",
"\$'((((gbddddbg(((('h",
"i'(((^jddddddjk((('h",
"f,((lmnopppppqpr((e#",
"@)((((((((((((((((>&",
"+!/((((((((((((((/s0",
"456<((((((((((((<654",
" |t12((((((((((21]| ",
" *{}[<((((((((<[}{* ",
"  ~{]6/((((((76]{~  ",
"   *=-s>,'',);5=*   ",
"     .u@#\$\$%&vw     "};
INLINEDATA1

    $self->{prior_b} = $self->{frame}->Button(
        -text      => 'Up',
        -image     => $icon,
        -takefocus => '0'
      )->grid(
        -row    => $self->{rows} - 1,
        -column => $self->{cols},
        -sticky => 's'
      );

    $icon = $self->{frame}->Pixmap( -data => <<INLINEDATA1);
/* XPM */
static char * next_xpm[] = {
"20 20 62 1",
" 	c None",
".	c #CBD6D6",
"+	c #9FB4B4",
"@	c #6F8484",
"#	c #607B7B",
"\$	c #537373",
"%	c #5F7A7A",
"&	c #708585",
"*	c #9DB1B1",
"=	c #CCD6D6",
"-	c #D3D9D9",
";	c #A3B5B5",
">	c #546363",
",	c #404646",
"'	c #5D5D5D",
")	c #818181",
"!	c #979797",
"~	c #5E5E5E",
"{	c #3E4444",
"]	c #546464",
"^	c #D4DADA",
"/	c #7C8F8F",
"(	c #373A3A",
"_	c #727272",
":	c #B1B1B1",
"<	c #CCCCCC",
"[	c #AFAFAF",
"}	c #444747",
"|	c #949494",
"1	c #C7C7C7",
"2	c #A3B6B6",
"3	c #959595",
"4	c #C9C9C9",
"5	c #373B3B",
"6	c #CDD6D6",
"7	c #9DB2B2",
"8	c #404545",
"9	c #A0B4B4",
"0	c #7F7F7F",
"a	c #A3A3A3",
"b	c #424242",
"c	c #3A3A3A",
"d	c #3C3C3C",
"e	c #3D3D3D",
"f	c #444444",
"g	c #A1A1A1",
"h	c #5F7B7B",
"i	c #517272",
"j	c #767676",
"k	c #212121",
"l	c #1A1A1A",
"m	c #747474",
"n	c #547373",
"o	c #848484",
"p	c #222222",
"q	c #7B7B7B",
"r	c #242424",
"s	c #3E4343",
"t	c #838383",
"u	c #C8C8C8",
"v	c #8C8C8C",
"w	c #454949",
"     .+@#\$\$%&*=     ",
"   -;>,')!!)~{];-   ",
"  ^/(_:<<<<<<[_(/^  ",
" -/}|1<<<<<<<<1|}/- ",
" 2(34<<<<<<<<<<4352 ",
"6>_1<<<<<<<<<<<<1_>6",
"7{[<<<<<<<<<<<<<<[89",
"@~<<<<<<<<<<<<<<<<'&",
"%0<<abcbbbbbdefg<<)h",
"i!<<<jkllllllkm<<<!n",
"i!<<<<opllllpo<<<<!\$",
"h0<<<<1qrllrq1<<<<)#",
"&'<<<<<<qppq<<<<<<'@",
"7s[<<<<<1tt1<<<<<:89",
"6>_1<<<<<<<<<<<<1_>6",
" 2(|u<<<<<<<<<<43(2 ",
" -/}|1<<<<<<<<1vw/- ",
"  ^/(m[<<<<<<[m(/^  ",
"   -;]8')!!)~,];-   ",
"     =9@#\$\$%&9=     "};
INLINEDATA1

    $self->{next_b} = $self->{frame}->Button(
        -text  => 'Next',
        -image => $icon,
        -takefocus => '0'

      )->grid(
        -row    => $self->{rows},
        -column => $self->{cols},
        -sticky => 'n'
      );
}

1;
