#!/usr/bin/perl 
#Programme to test GridEntry widget
use Tk;
use GridEntry;
#my $datahash={};
my $datahash={ };
my $whash={
	'columns'=>["id","name","age","city"],
	'id'=>{
		'widgettype'=>'Entry',
		'label'=>'ID',
		'col'=>'0',
		-width=>10,
		-state=>'normal'
		},
	'name'=>{
		'widgettype'=>'Entry',
		'label'=>'NAME',
		'col'=>'1',
		-width=>30,
		-state=>'normal'
		},
	'age'=>{
		'widgettype'=>'Entry',
		'label'=>'Age',
		'col'=>'2',
		-width=>3,
		-state=>'normal'
		},
	'city'=>{
		'widgettype'=>'BrowseEntry',
		'label'=>'City',
		'col'=>'3',
		-width=>15,
		-choices=>["Chennai","Bangalore","Hyderabad","New Delhi"],
		-state=>'normal'
		}
	};
my $mw=MainWindow->new();
my $frame=$mw->Frame()->pack();
my $t=$frame->GridEntry( -datahash=>$datahash,
			-structure=>$whash,
			-rows=>5,
			-extend=>5,
			-scroll=>'1'
			)->pack();
my $b1=$frame->Button(-text=>'Put Data',
			-command=>\&putdata
			)->pack();
my $b2=$frame->Button(-text=>'Print Data',
			-command=>\&printdata
			)->pack();
$t->moverectoscreen();
MainLoop;

sub putdata{
for (my $i=0;$i<10;$i++){
	$datahash->{'id'}[$i]=$i;
	$datahash->{'name'}[$i]=sprintf "Name.%d",$i;
	$datahash->{'age'}[$i]=$i*5;
	$datahash->{'city'}[$i]=sprintf "city.%d",$i;

	}

$t->moverectoscreen();
$t->update();
}

sub printdata{
print join "\t",keys(%$datahash);
for (my $i=0;$i<scalar(@{$datahash->{id}});$i++){
	printf "Row=$i id=%s Name=%s age=%s city=%s\n",$datahash->{id}[$i],$datahash->{name}[$i],$datahash->{age}[$i],$datahash->{city}[$i];
	}
}
