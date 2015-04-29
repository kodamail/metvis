#!/usr/bin/perl


use strict;
use CGI;
use File::Basename;
#use Time::Piece ();
my $cgi = new CGI;

&main();
exit;


#
# status: "monthly_mean", "JJA", etc...
# type:   type of status value, such as "mode", "runs", "varid", etc...
#
#

sub main()
{
    ############################################################
    #
    # arguements
    #
    ############################################################
    #
    #--- job file name
    my $file = $cgi->param( 'file' );
    #
    #--- order of job (optional)
    my $target_count = $cgi->param( 'count' );
    if( $target_count eq "" ){ $target_count = 1; }
    #
    #--- target filter
    my %target;
    #
    foreach my $target ( 'type', 'mode', 'run1', 'run2', 'varid' )
    {
	$target{$target} = $cgi->param($target);
	if( $target{$target} eq "" ){ $target{$target} = ".*"; }
    }

    ############################################################
    #
    # read data file
    #
    ############################################################
    my @txt_pre;
    if( open(LINK, "< $file") )
    {
	@txt_pre = <LINK>;
	close(LINK);
    }

    ############################################################
    #
    # pre-process: expand -include.
    #
    ############################################################
    my @txt;
    for( my $i=0; $i<=$#txt_pre; $i++ )
    {
	if( $txt_pre[$i] =~ /^ *include ([^ ]+) *$/g )
	{
	    my $child_file = $1;
	    $child_file = dirname( $file ) . "/" . $child_file;
	    
	    my @txt_child;
	    if( open(LINK, "< $child_file") )
	    {
		@txt_child = <LINK>;
		close(LINK);
	    }
	    @txt = ( @txt, @txt_child );
	}
	else
	{
	    push( @txt, $txt_pre[$i] );
	}
    }

    ############################################################
    #
    # parse
    #
    ############################################################
    my @status = ( );  # current status for reading job_list
    my @type = ( );    # current type of status for reading job_list
    my $depth = 0;     # depth of { }
    my @one_depth = ( );  # depth of status in one { } (not necessarily 1)
    my $one_depth_temp = 0;
    my $count = 0;
    my $val = "";
    my $flag_comment = 0;  # =1: comment(/* */), =0: non-comment
    my $flag_blacket = 0;
    my @status_temp = ( );
    my @type_temp = ( );
    my %udef;  # user-defined variables (e.g. define a = 123 456 )
    for( my $i=0; $i<=$#txt; $i++ )  # for all line
    {
#    print $i . ": " . $txt[$i] . "\n";
    
	if( $txt[$i] =~ /^\s*exit\s*$/ ){ exit; }
	
        # comment statement
	if( $flag_comment == 1 )
	{
	    if( $txt[$i] =~ /^\s*\*\// ){ $flag_comment = 0; }
	    next;
	}
	if( $txt[$i] =~ /^\s*\/\*/ ){ $flag_comment = 1; next; }
	if( $txt[$i] =~ /^\s*#/ ){ next; }
	    
        # replace ${} with defined variables
	while ( my ($key, $val) = each (%udef) )
	{
	    #print STDERR "hash: $key : $val\n";
	    # replace ${}
	    $txt[$i] =~ s/\$\{$key\}|\$$key/$val/g;
	} 
	    
        # define variable
        #if( $txt[$i] =~ /^define ([a-zA-Z][^ ]*) *= *(.*)$/ )
        if( $txt[$i] =~ /^ *([a-zA-Z][^ ]*) *= *(.*)$/ )
        {
	    #print STDERR "$i: $txt[$i] : $1 : $2\n";
	    $udef{"$1"} = $2;
	    next;
	}
        elsif( $txt[$i] =~ /^ *([a-zA-Z][^ ]*) *\+= *(.*)$/ )
        {
	    #print STDERR "$i: $txt[$i] : $1 : $2\n";
	    $udef{"$1"} = $udef{"$1"} . " " . $2;
	    next;
	}

        # delete void line and unnecessary space
        $txt[$i] =~ s/^ +//;
        $txt[$i] =~ s/  +/ /g;
        $txt[$i] =~ s/\n$//;
        #print STDERR $i . ": " . $txt[$i] . "\n";

        # )
        if( $txt[$i] =~ /^\s*\)\s*$/ )
        {
            # print and exit if $count == $target?
	    my @status_now = ();  # temporary variable for parse_core.
	    my @type_now   = ();  # temporary variable for parse_core.
	    &parse_core( \@status_now, \@type_now, \$count, \$target_count, \@type, \@status, \%target, \$val );
	    if( $count >= $target_count ){ exit; }

	    $flag_blacket = 0;
	    $val = "";
	    for( my $j=0; $j<=$one_depth[$#one_depth]-1; $j++ )
	    {
		pop( @status );
		pop( @type );
	    }
	    pop( @one_depth );
	    next;
	}
	    
        # within ( )
	if( $flag_blacket == 1 )
	{
	    $val .= $txt[$i] . "\n";
	    next;
	}
	    
	# {
	if( $txt[$i] =~ /^\s*\{\s*$/ )
        {
#	print "status_temp: " . $status_temp . "\n";
	    push( @one_depth, $one_depth_temp );
	    for( my $j=0; $j<=$one_depth_temp-1; $j++ )
	    {
#	    print $j . "\n";
		push( @status, $status_temp[$j] );
		push( @type, $type_temp[$j] );
	    }
	    $one_depth_temp = 0;
	    @status_temp =( );
	    @type_temp = ( );
	    $depth++;
	    next;
	}

        # }
        if( $txt[$i] =~ /^\s*\}\s*$/ )
        {
	    $depth--;
	    for( my $j=0; $j<=$one_depth[$#one_depth]-1; $j++ )
	    {
		pop( @status );
		pop( @type );
	    }
	    pop( @one_depth );
	    next;
	}
	
        # (
        if( $txt[$i] =~ /^\s*\(\s*$/ )
        {
	    push( @one_depth, $one_depth_temp );
	    for( my $j=0; $j<=$one_depth_temp-1; $j++ )
	    {
#	    print $j . "\n";
		push( @status, $status_temp[$j] );
		push( @type, $type_temp[$j] );
	    }
	    $one_depth_temp = 0;
	    @status_temp = ( );
	    @type_temp = ( );
	    $flag_blacket = 1;
	    next;
	}

    # any other -> assumed to be a status
#    if( $txt[$i] ne "" ){ $status_temp .= $txt[$i]; }
	if( $txt[$i] ne "" )
        {
	    push( @status_temp, $txt[$i] );
	    $status_temp[$#status_temp] =~ s/^([^\s]+)\s//;
#	$status_temp[0] .= $txt[$i];
#	$status_temp[0] =~ s/^([^\s]+)\s//;
	    push( @type_temp, $1 );
#	$type_temp .= $1;
	    $one_depth_temp++;
#	print $one_depth_temp . "\n";
	}
    }
    return;
}



############################################################
#
# child subroutines
#
############################################################
#
#
sub parse_core
{
    #my $d            = shift;
    my $status_now   = shift;  # current status (pointer for array)
    my $type_now     = shift;  # current type of status (pointer for array)
    my $count        = shift;  # pointer
    my $target_count = shift;  # pointer
    my $type         = shift;  # pointer, should be read-only
    my $status       = shift;  # pointer, read-only
    my $target       = shift;  # pointer
    my $val          = shift;  # pointer

    my $d = $#$status_now + 1;  # depth
    if( $$count >= $$target_count ){ return; }

    my @status_list = ();

    #
    #--- set @type_now
    push( @$type_now, $$type[$d] );  # basically, @type_now equals @type.
    #print STDERR $$type[$d] . "\n";
    #print STDERR $$type_now[$d] . "\n";
    
    if( $$type[$d] eq "y*" )
    {
	for( my $dd=0; $dd<$d; $dd++ )
	{
	    if( $$type_now[$dd] eq "timeid" )
	    {
		if(    $$status_now[$dd] eq "1dy_mean"           ){ $$type_now[$d] = "ymd"; }
		elsif( $$status_now[$dd] eq "monthly_mean"       ){ $$type_now[$d] = "ym";  }
		elsif( $$status_now[$dd] eq "seasonal_mean"      ){ $$type_now[$d] = "ys";  }
		elsif( $$status_now[$dd] eq "annual_mean"        ){ $$type_now[$d] = "ya";  }
		elsif( $$status_now[$dd] eq "clim_monthly_mean"  ){ $$type_now[$d] = "cym"; }
		elsif( $$status_now[$dd] eq "clim_seasonal_mean" ){ $$type_now[$d] = "cys"; }
		elsif( $$status_now[$dd] eq "clim_annual_mean"   ){ $$type_now[$d] = "cya"; }
		else{ print STDERR "error: status_now[$dd]=$$status_now[$dd]\n"; exit 1; }
	    }
	}
    }
    #
    #--- prepare @status_list for setting @status_now
    if( $$type_now[$d] eq "ym"  || $$type_now[$d] eq "cym" 
     || $$type_now[$d] eq "ymd" 
     || $$type_now[$d] eq "ymdh" 
     || $$type_now[$d] eq "ys"  || $$type_now[$d] eq "cys" 
     || $$type_now[$d] eq "ya"  || $$type_now[$d] eq "cya" 
     || $$type_now[$d] eq "ymd_range" || $$type_now[$d] eq "ymdh_range" )
    {
	if( $$status[$d] eq "*" )  # expand using list/*_list.txt
	{
	    &expand_ast( \@status_list, $d, $status_now, $type_now );
	}
	else
	{
	    my @st = split( /\s+/, $$status[$d] );
	    for( my $s=0; $s<=$#st; $s++ )
	    {
		&expand( \@status_list, $$type_now[$d], $st[$s], $status_now );
	    }
	}
    }
    else
    {
	@status_list = split( / +/, $$status[$d] );
    }

    foreach my $s ( @status_list )
    {
	push( @$status_now, $s );
#	print "s:" . $s . "\n";
#	print "now: " . $#$status_now . " : " . $$status_now[$#$status_now] . "\n";
	if( $d < $#$status )
	{
	    #&parse_core( $d+1, $status_now, $count, $target_count, $type, $status, $target, $val );
	    &parse_core( $status_now, $type_now, $count, $target_count, $type, $status, $target, $val );
	}
	else
	{
	    my $count_flag = 1;
	    #for( my $p=0; $p<=$#$status_now; $p++ )
	    LOOP_P: for( my $p=0; $p<=$#$status_now; $p++ )
	    {
		#if( $$type_now[$p] eq "type"  && $$status_now[$p] !~ /$$target{'type'}/  ){ $count_flag = 0; last; }
		#if( $$type_now[$p] eq "mode"  && $$status_now[$p] !~ /$$target{'mode'}/  ){ $count_flag = 0; last; }
		#if( $$type_now[$p] eq "run1"  && $$status_now[$p] !~ /$$target{'run1'}/  ){ $count_flag = 0; last; }
		#if( $$type_now[$p] eq "run2"  && $$status_now[$p] !~ /$$target{'run2'}/  ){ $count_flag = 0; last; }
		#if( $$type_now[$p] eq "varid" && $$status_now[$p] !~ /$$target{'varid'}/ ){ $count_flag = 0; last; }
		while ( my ($tkey, $tval) = each (%$target) )
		{
		    if( $$type_now[$p] eq "$tkey"  && $$status_now[$p] !~ /$tval/  ){ $count_flag = 0; last LOOP_P; }
		} 

	    }
	    if( $count_flag == 1 ){ $$count++; }

	    if( $$count == $$target_count )
	    {
#		print "type: ";
		for( my $p=0; $p<=$#$status_now; $p++ )
		{
		    if   ( $$type_now[$p] eq "ym"         ){ print "year month "; }
#		    elsif( $$type_now[$p] eq "cym"        ){ print "year_start year_end month "; }
		    elsif( $$type_now[$p] eq "cym"        ){ print "years month "; }
		    elsif( $$type_now[$p] eq "ymd"        ){ print "year month day "; }
		    elsif( $$type_now[$p] eq "ymdh"       ){ print "year month day hour "; }
		    elsif( $$type_now[$p] eq "ys"         ){ print "year season "; }
#		    elsif( $$type_now[$p] eq "cys"        ){ print "year_start year_end season "; }
		    elsif( $$type_now[$p] eq "cys"        ){ print "years season "; }
		    elsif( $$type_now[$p] eq "ya"         ){ print "year "; }
#		    elsif( $$type_now[$p] eq "ya"         ){ print "year month "; }
		    elsif( $$type_now[$p] eq "cya"        ){ print "years "; }
		    elsif( $$type_now[$p] eq "ymd_range"  ){ print "year month day year2 month2 day2 "; }
		    elsif( $$type_now[$p] eq "ymdh_range" ){ print "year month day hour year2 month2 day2 hour2 "; }
		    else{ print "$$type[$p] "; }
		}
		print "\n";

		my $disp = $$val;
		for( my $p=0; $p<=$#$status_now; $p++ )
		{
		    # replace ${}
		    $disp =~ s/\$\{$$type_now[$p]\}|\$$$type_now[$p]/$$status_now[$p]/g;
		    #
		    if( $$type_now[$p] eq "ym" && $$status_now[$p] =~ /^([0-9][0-9][0-9][0-9]) ([01][0-9])$/ )
		    {
			my $year = $1;
			my $month = $2;
			$disp =~ s/\$\{year\}|\$year/$year/g;
			$disp =~ s/\$\{month\}|\$month/$month/g;
		    }
		    elsif( $$type_now[$p] eq "ymd" && $$status_now[$p] =~ /^([0-9][0-9][0-9][0-9]) ([01][0-9]) ([0-3][0-9])$/ )
		    {
			my $year  = $1;
			my $month = $2;
			my $day   = $3;
			$disp =~ s/\$\{year\}|\$year/$year/g;
			$disp =~ s/\$\{month\}|\$month/$month/g;
			$disp =~ s/\$\{day\}|\$day/$day/g;
		    }
		    elsif( $$type_now[$p] eq "ymdh" && $$status_now[$p] =~ /^([0-9][0-9][0-9][0-9]) ([01][0-9]) ([0-3][0-9]) ([0-2][0-9])$/ )
		    {
			my $year  = $1;
			my $month = $2;
			my $day   = $3;
			my $hour  = $4;
			$disp =~ s/\$\{year\}|\$year/$year/g;
			$disp =~ s/\$\{month\}|\$month/$month/g;
			$disp =~ s/\$\{day\}|\$day/$day/g;
			$disp =~ s/\$\{hour\}|\$hour/$hour/g;
		    }
		    elsif( $$type_now[$p] eq "ys" && $$status_now[$p] =~ /^([0-9][0-9][0-9][0-9]) (DJF|MAM|JJA|SON)$/ )
		    {
			my $year = $1;
			my $season = $2;
#			print "succeed\n";
			$disp =~ s/\$\{year\}|\$year/$year/g;
			$disp =~ s/\$\{season\}|\$season/$season/g;
		    }
		    elsif( $$type_now[$p] eq "ya" && $$status_now[$p] =~ /^([0-9][0-9][0-9][0-9])$/ )
#		    elsif( $$type_now[$p] eq "ya" && $$status_now[$p] =~ /^([0-9][0-9][0-9][0-9]) ([01][0-9])$/ )
		    {
			my $year = $1;
			my $month = $2;
#			print "succeed\n";
			$disp =~ s/\$\{year\}|\$year/$year/g;
			$disp =~ s/\$\{month\}|\$month/$month/g;
		    }
#		    else{print "fail\n";}
#		    print "ok: $$type[$p], $$status_now[$p]\n";
#		    print " -> " . $disp;
		    print $$status_now[$p] . " ";
		}
		print "\n";
		print $disp;
		pop( @$status_now );
		last;
	    }
	}
	pop( @$status_now );
    }

    pop( @$type_now );
    return;
}


# todo: two or more ym
# all except ym
#sub parse_list_ym
#{
#    my $key = shift;
#    my $target = shift;
#    my @run_list;
#    if( open(LINK, "< list/" . $key . "_list.txt") )
#    {
#	@run_list = <LINK>;
#	close(LINK);
#    }
#    my $flag = 0;
#    for( my $i=0; $i<=$#run_list-1; $i++ )
#    {
#	if( $run_list[$i] =~ /^$target\s*/ && $run_list[$i+1] =~ /^\{\s*/ ){ $flag = 1; }
#	if( $flag == 1 )
#	{
#	    if( $run_list[$i] =~ /^\s+ym\s+(.*)$/ )
#	    {
#		return $1;
#	    }
#	}
#    }
#}


sub expand_ast
{
    my $status_list = shift;
    my $d           = shift;
    my $status_now  = shift;
    my $type_now    = shift;  # pointer
    
    my @st = ();
    for( my $p=0; $p<=$#$status_now; $p++ )
    {
	#my $temp = &parse_list_type( $type[$p], $$status_now[$p], $type[$d] );

	#print STDERR "$type[$p] value=$$status_now[$p]\n";
	my @run_list;
	if( open(LINK, "< list/" . $$type_now[$p] . "_list.txt") )
	{
	    @run_list = <LINK>;
	    close(LINK);
	}
	#print STDERR @run_list;
	my $flag = 0;
	for( my $i=0; $i<=$#run_list-1; $i++ )
	{
	    if( $run_list[$i] =~ /^$$status_now[$p]\s*$/ && $run_list[$i+1] =~ /^\{\s*/ ){ $flag = 1; }
	    elsif( $run_list[$i] =~ /^\s*\}s*$}/ ){ $flag = 0; }

	    #print STDERR "$i: $flag\n";
	    #print STDERR "$i: $flag $run_list[$i] $$status_now[$p]\n";

	    if( $flag == 1 )
	    {
		if( $run_list[$i] =~ /^\s+$$type_now[$d]\s+(.*)$/ )
		{
		    push( @st, $1 );
		    #print STDERR "  $1\n";
		    #return $1;
		}
	    }
	}
    }
#    if( $st[0] eq "" )
#    {
#	print STDERR "error in parse_list.pl: $$type_now[$d] is not set in list/$$type_now[$d]_list.txt\n";
#	exit 1;
#    }
#    print STDERR "@st\n";
    for( my $s=0; $s<=$#st; $s++ )
    {
	my @status_list_tmp;
#	print STDERR "$s: $st[$s]\n";
	my @st2 = split( /\s+/, $st[$s] );
	for( my $s2=0; $s2<=$#st2; $s2++ )
	{
	    &expand( \@status_list_tmp, $$type_now[$d], $st2[$s2], $status_now );
	}
	#&expand( \@status_list_tmp, $type[$d], $st[$s], $status_now );
#	print STDERR "$st[$s] -> @status_list_tmp\n";
#	print STDERR "$type[$d]\n";

	if( $s == 0 ){ @$status_list = @status_list_tmp; }
	elsif( $$type_now[$d] eq "cym" || $$type_now[$d] eq "cys" )
	{
	    for( my $i=0; $i<=$#$status_list; $i++ )
	    {
#		print STDERR "status_list: " . $$status_list[$i] . "\n";
#		exit 1;
		#my @yym1 = split( " ", $$status_list[$i] );
		my @yym1 = split( /[- ]/, $$status_list[$i] );

		my @tmp2 = grep( / $yym1[2]$/, @status_list_tmp );
		# assume duplicate month does not exist.
#		print STDERR "@yym1\n";
#		print STDERR "@status_list_tmp\n";
#		print STDERR "$tmp2[0]\n";
#		print STDERR "$#tmp2\n";
		#exit 1;

		if( $#tmp2 == 0 )
		{
		    #print STDERR "ok";
		    #my @yym2 = split( " ", $tmp2[0] );
		    #my @yym2 = split( "-", $tmp2[0] );
		    my @yym2 = split( /[- ]/, $tmp2[0] );
		    
		    my $ymin = $yym1[0];
		    if( $yym1[0] < $yym2[0] ){ $ymin = $yym2[0]; }
		    my $ymax = $yym1[1];
		    if( $yym1[1] > $yym2[1] ){ $ymax = $yym2[1]; }
		    if( $ymin > $ymax ){ $$status_list[$i] = ""; }
		    #else{ $$status_list[$i] = "$ymin $ymax $yym1[2]"; }
		    else{ $$status_list[$i] = "$ymin-$ymax $yym1[2]"; }

#		    print STDERR "match:" . $$status_list[$i] . "\n";
		}
		else
		{
		    $$status_list[$i] = "";
		}
		#print STDERR $tmp[0] . "\n";
		
	    }
	    @$status_list = split( "SEP", join( "SEP", @$status_list ) );
	    
	}

	elsif( $$type_now[$d] eq "cya" )
	{
	    for( my $i=0; $i<=$#$status_list; $i++ )
	    {
#		print STDERR "status_list: " . $$status_list[$i] . "\n";
		my @yy1 = split( /-/, $$status_list[$i] );
		my @yy2 = split( /-/, $status_list_tmp[0] );
#		print STDERR "@yy1\n";
#		print STDERR "@yy2\n";
		my $ymin = $yy1[0];
		if( $yy1[0] < $yy2[0] ){ $ymin = $yy2[0]; }
		my $ymax = $yy1[1];
		if( $yy1[1] > $yy2[1] ){ $ymax = $yy2[1]; }
		if( $ymin > $ymax ){ $$status_list[$i] = ""; }
		else{ $$status_list[$i] = "$ymin-$ymax"; }
	    }
	    @$status_list = split( "SEP", join( "SEP", @$status_list ) );
	}

	else
	{
	    # obtain only the duplicated values (i.e. && operation) 
	    # http://oshiete.goo.ne.jp/qa/5155860.html
	    #my @test = grep { !{map{$_,1}@status_list_tmp }-> {$_}}@$status_list;
	    @$status_list = grep { { map {$_,1} @status_list_tmp }->{$_} } @$status_list;
	}
    }
#    print STDERR "ok\n";
#    print STDERR "@$status_list\n";
#    exit 1;
}


=comment
sub parse_list_type
{
    my $key    = shift;
    my $target = shift;
    my $type   = shift;
    my @run_list;
    if( open(LINK, "< list/" . $key . "_list.txt") )
    {
	@run_list = <LINK>;
	close(LINK);
    }
    my $flag = 0;
    my @cand = ();
    for( my $i=0; $i<=$#run_list-1; $i++ )
    {
	if( $run_list[$i] =~ /^$target\s*$/ && $run_list[$i+1] =~ /^\{\s*/ ){ $flag = 1; }
	if( $flag == 1 )
	{
	    if( $run_list[$i] =~ /^\s+$type\s+(.*)$/ )
	    {
		push( @cand, $1 );
		return $1;
	    }
	}
    }
}
=cut


#
# $status_list: resulting status values (added) (e.g. "2004 06" "2004 07" ...)
# $type_now   : type to expand
# $st         : expression to expand (e.g. "2004,06,2005,07")
# $status_now : parent status values
#
sub expand
{
    my $status_list = shift;
    my $type_now    = shift;
    my $st          = shift;
    my $status_now  = shift;

    if( $type_now eq "ym" && $st =~ /^([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-9][0-9][0-9][0-9]),([01]*[0-9])$/ )
    {
	my ( $year_start, $month_start ) = ( $1, $2 );
	my ( $year_end,   $month_end   ) = ( $3, $4 );
	my $ym_start = $year_start * 12 + ($month_start-1);
	my $ym_end   = $year_end   * 12 + ($month_end-1);
	for( my $ym=$ym_start; $ym<=$ym_end; $ym++ )
	{
	    my $year = int( $ym / 12 );
	    my $month = $ym - $year * 12 + 1;
	    if( $month < 10 ){ $month = "0" . $month; }
	    push( @$status_list, "$year $month" );
	}
    }
#    elsif( $type_now eq "cym" && $st =~ /^([0-9][0-9][0-9][0-9]),([0-9][0-9][0-9][0-9]),([01]*[0-9]),([01]*[0-9])$/ )
    elsif( $type_now eq "cym" && $st =~ /^([0-9][0-9][0-9][0-9])-([0-9][0-9][0-9][0-9]),([01]*[0-9]),([01]*[0-9])$/ )
    {
	my ( $year_start, $year_end    ) = ( $1, $2 );
	my ( $month_start, $month_end  ) = ( $3, $4 );
	for( my $m=$month_start; $m<=$month_end; $m++ )
	{
	    my $month = $m + 0;
	    if( $m < 10 ){ $month = "0" . $month; }
#	    push( @$status_list, "$year_start $year_end $month" );
	    push( @$status_list, "$year_start-$year_end $month" );
	}
    }
    elsif( $type_now eq "ymd" && $st =~ /^([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9]),([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9])$/ )
    {
	my ( $year_start, $month_start, $day_start ) = ( $1, $2, $3 );
	my ( $year_end,   $month_end,   $day_end )   = ( $4, $5, $6 );
	my $year  = $year_start;
	my $month = $month_start;
	my $day   = $day_start;
	my $ymd = ( $year * 12 + $month ) * 31 + $day;
	my $ymd_start = ( $year_start * 12 + $month_start ) * 31 + $day_start;
	my $ymd_end = ( $year_end * 12 + $month_end ) * 31 + $day_end;
	my $delta_day = 1;  # ( < 28 )
	for( my $p=0; $p<=$#$status_now; $p++ )
	{
	    if( $type_now eq "timeid" && $$status_now[$p] eq "1dy_mean" ){ $delta_day = 1; last; }
	    if( $type_now eq "timeid" && $$status_now[$p] eq "5dy_mean" ){ $delta_day = 5; last; }
	}
	while( $ymd <= $ymd_end )
	{
	    push( @$status_list, "$year $month $day" );
	    
	    my $maxday = 31;  # end day of month
	    if( $month == 4 || $month == 6 || $month == 9 || $month == 11 ){ $maxday = 30; }
	    elsif( $month == 2 )
	    {
		if(    $year % 400 == 0 ){ $maxday = 29; }
		elsif( $year % 100 == 0 ){ $maxday = 28; }
		elsif( $year % 4   == 0 ){ $maxday = 29; }
		else                     { $maxday = 28; }
	    }
	    $day = $day + $delta_day;
	    if( $day > $maxday )
	    {
		$day = $day - $maxday;
		$month = $month + 1;
		if( $month > 12 )
		{
		    $year = $year + 1;
		    $month = 1;
		    $day = $day - $maxday;
		}
		
	    }
	    if( $month < 10 ){ $month = "0" . ($month+0); }
	    if( $day < 10 ){ $day = "0" . ($day+0); }
	    $ymd = ( $year * 12 + $month ) * 31 + $day;
	    
	}
    }
    elsif( $type_now eq "ymdh" && $st =~ /^([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9]),([0-2]*[0-9]),([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9]),([0-2]*[0-9])$/ )
    {
	my ( $year_start, $month_start, $day_start, $hour_start ) = ( $1, $2, $3, $4 );
	my ( $year_end,   $month_end,   $day_end,   $hour_end )   = ( $5, $6, $7, $8 );
	my $year  = $year_start;
	my $month = $month_start;
	my $day   = $day_start;
	my $hour  = $hour_start;
	my $ymdh = ( ( $year * 12 + $month ) * 31 + $day ) * 24 + $hour;
	my $ymdh_start = ( ( $year_start * 12 + $month_start ) * 31 + $day_start ) * 24 + $hour_start;
	my $ymdh_end = ( ( $year_end * 12 + $month_end ) * 31 + $day_end ) * 24 + $hour_end;
	my $delta_hour = 1;  # ( < 28 )
#	for( my $p=0; $p<=$#$status_now; $p++ )
#	{
#	    if( $type eq "timeid" && $$status_now[$p] eq "1dy_mean" ){ $delta_day = 1; last; }
#	    if( $type eq "timeid" && $$status_now[$p] eq "5dy_mean" ){ $delta_day = 5; last; }
#	}
	while( $ymdh <= $ymdh_end )
	{
	    push( @$status_list, "$year $month $day $hour" );
	    
	    my $maxday = 31;  # end day of month
	    if( $month == 4 || $month == 6 || $month == 9 || $month == 11 ){ $maxday = 30; }
	    elsif( $month == 2 )
	    {
		if(    $year % 400 == 0 ){ $maxday = 29; }
		elsif( $year % 100 == 0 ){ $maxday = 28; }
		elsif( $year % 4   == 0 ){ $maxday = 29; }
		else                     { $maxday = 28; }
	    }
	    $hour = $hour + $delta_hour;
	    if( $hour >= 24 )
	    {
		$hour = $hour - 24;
		$day = $day + 1;
		if( $day > $maxday )
		{
		    $day = $day - $maxday;
		    $month = $month + 1;
		    if( $month > 12 )
		    {
			$year = $year + 1;
			$month = 1;
			$day = $day - $maxday;
		    }
		    
		}
		if( $month < 10 ){ $month = "0" . ($month+0); }
		if( $day < 10 ){ $day = "0" . ($day+0); }
	    }
	    if( $hour < 10 ){ $hour = "0" . ($hour+0); }
	    $ymdh = ( ( $year * 12 + $month ) * 31 + $day ) * 24 + $hour;
	}
    }
    elsif( $type_now eq "ymd_range" && $st =~ /^([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9]),([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9])$/ )
    {
	my ( $year_start, $month_start, $day_start ) = ( $1, $2, $3 );
	my ( $year_end,   $month_end,   $day_end )   = ( $4, $5, $6 );
	push( @$status_list, "$year_start $month_start $day_start $year_end $month_end $day_end" );
    }
    elsif( $type_now eq "ymdh_range" && $st =~ /^([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9]),([0-2]*[0-9]),([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9]),([0-2]*[0-9])$/ )
#	    elsif( $type[$d] eq "ymdh_range")
    {
	my ( $year_start, $month_start, $day_start, $hour_start ) = ( $1, $2, $3, $4 );
	my ( $year_end,   $month_end,   $day_end,   $hour_end   ) = ( $5, $6, $7, $8 );
	push( @$status_list, "$year_start $month_start $day_start $hour_start $year_end $month_end $day_end $hour_end" );
    }
#	    elsif( $type[$d] eq "ymd" && $st[$s] =~ /^([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9]),([0-9][0-9][0-9][0-9]),([01]*[0-9]),([0-3]*[0-9])$/ )
#	    {
#		my ( $year_start, $month_start, $day_start ) = ( $1, $2, $3 );
#		my ( $year_end,   $month_end,   $day_end )   = ( $4, $5, $6 );
#		my $ym_start = $year_start * 12 + ($month_start-1);
#		my $ym_end   = $year_end   * 12 + ($month_end-1);
#		for( my $ym=$ym_start; $ym<=$ym_end; $ym++ )
#		{
##		    print "$ym_start $ym_end\n";
#		    my $year = int( $ym / 12 );
#		    my $month = $ym - $year * 12 + 1;
#		    if( $month < 10 ){ $month = "0" . $month; }
#
#		    my $maxday = 31;  # end day of month
#		    if( $month == 4 || $month == 6 || $month == 9 || $month == 11 ){ $maxday = 30; }
#		    elsif( $month == 2 )
#		    {
#			if(    $year % 400 == 0 ){ $maxday = 29; }
#			elsif( $year % 100 == 0 ){ $maxday = 28; }
#			elsif( $year % 4   == 0 ){ $maxday = 29; }
#			else                     { $maxday = 28; }
#		    }
#
#		    for( my $day=1; $day<=$maxday; $day=$day+1)
#		    {
#			if( $ym == $ym_start && $day < $day_start ){ next; }
#			if( $ym == $ym_end   && $day > $day_end ){ next; }
#			if( $day < 10 ){ $day = "0" . $day; }
#			push( @status_list, "$year $month $day" );
##			print "ok: $day\n";
#		    }
#		}
##		    print "ok";
##		    exit;
#	    }
    elsif( $type_now eq "ys" && $st =~ /^([0-9][0-9][0-9][0-9]),(DJF|MAM|JJA|SON),([0-9][0-9][0-9][0-9]),(DJF|MAM|JJA|SON)$/ )
    {
	my ( $year_start, $season_start ) = ( $1, $2 );
	my ( $year_end,   $season_end   ) = ( $3, $4 );
	my %idx_season = ( "MAM" => 0, "JJA" => 1, "SON" => 2, "DJF" =>3 );
	my @season     = ( "MAM",      "JJA",      "SON",      "DJF" );
	my $ys_start = $year_start * 4 + $idx_season{$season_start};
	my $ys_end   = $year_end   * 4 + $idx_season{$season_end};
	for( my $ys=$ys_start; $ys<=$ys_end; $ys++ )
	{
	    my $year   = int( $ys / 4 );
	    my $season = $season[$ys - $year * 4];
	    push( @$status_list, "$year $season" );
	}
    }
#    elsif( $type_now eq "cys" && $st =~ /^([0-9][0-9][0-9][0-9]),([0-9][0-9][0-9][0-9]),(DJF|MAM|JJA|SON),(DJF|MAM|JJA|SON)$/ )
    elsif( $type_now eq "cys" && $st =~ /^([0-9][0-9][0-9][0-9])-([0-9][0-9][0-9][0-9]),(DJF|MAM|JJA|SON),(DJF|MAM|JJA|SON)$/ )
    {
	my ( $year_start,   $year_end   ) = ( $1, $2 );
	my ( $season_start, $season_end ) = ( $3, $4 );
	my %idx_season = ( "MAM" => 0, "JJA" => 1, "SON" => 2, "DJF" =>3 );
	my @season     = ( "MAM",      "JJA",      "SON",      "DJF" );
	for( my $s=$idx_season{$season_start}; $s<=$idx_season{$season_end}; $s++ )
	{
#	    push( @$status_list, "$year_start $year_end $season[$s]" );
	    push( @$status_list, "$year_start-$year_end $season[$s]" );
	    
	}
    }
    elsif( $type_now eq "ya" && $st =~ /^([0-9][0-9][0-9][0-9]),([0-9][0-9][0-9][0-9])$/ )
#    elsif( $type_now eq "ya" && $st =~ /^([0-9][0-9][0-9][0-9]),([0-9][0-9][0-9][0-9])(,([0-1][0-9]))?$/ )
    {
	my ( $year_start,   $year_end   ) = ( $1, $2 );
#	my ( $year_start,   $year_end, $month   ) = ( $1, $2, $4 );
#	if ( $month eq "" ){ $month = "01"; }
	for( my $y=$year_start; $y<=$year_end; $y++ )
	{
	    push( @$status_list, "$y" );
#	    push( @$status_list, "$y $month" );
	}
    }
    elsif( $type_now eq "cya" && $st =~ /^([0-9][0-9][0-9][0-9])-([0-9][0-9][0-9][0-9])$/ )
    {
	my ( $year_start,   $year_end   ) = ( $1, $2 );
	push( @$status_list, "$year_start-$year_end" );
    }
    else
    {
	print STDERR "error in expand(), parse_list.pl\n";
	print STDERR "  type_now = $type_now\n";
	print STDERR "  st       = $st\n";
	exit 1;
    }
}


