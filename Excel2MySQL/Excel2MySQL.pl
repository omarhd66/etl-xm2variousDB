#!/usr/bin/perl  -w
use DBI;
#definition of variables
$db="MYTEST";
$host="localhost";
$user="root";
$password="admin";

#connect to MySQL database
my $databaseh   = DBI->connect ("DBI:mysql:database=$db:host=$host",
				  $user,
				  $password) 
				  or die "Can't connect to database: $DBI::errstr\n";
my %tablesDB;
	#----les fichiers excel
chomp(my @excelfile =`ls R*.csv`);
my @excelnames;
	#----Conversion en CSV
# foreach (@excelfile){
# `Convert_To_CSV.vbs "C:\Users\Omar\Desktop\Stage Nokia\Perl CSV to MySQL\$_"`;
	# my @fixe= split (/\./, $_); push (@excelnames, $fixe[0]);
 # }

#-----lire fichier config----------
  $configfile= "config.csv";
open(my $config, '<', $configfile) or die "Could not open '$configfile' $!\n";
my %hashconfig;
my @config;
while (my $line = <$config>) {
    chomp $line; my @array= split (/;/, $line);
	 $line = join ';', $line, "null";
	$hashconfig{$array[0]} = $line; # %hashconfig contient le fichier config		
}

#--------CREATE TABLE--------------
# @excelfile= "RSBSS888_KPI_2G_NPO_BSC_Daily_1-NOKBSC-BSC-day-PM_10002-2017_08_23-08_36_05__979.csv";
foreach (@excelfile){
	my @fixe= split (/\_100/,$_); 
	# $fixe[0] contient la partie fixE
	
if ($hashconfig{$fixe[0]}){ #if le nom du fichier exist en fichier config 

my @array = split (/\;/, $hashconfig{$fixe[0]}); 
# $array[1] contient le nom de la table destination
# Et @array contient line config
 if (! $tablesDB{$array[1]} ){ #si la table n'exist pas dans la fichier config et la DB 
	$tablesDB{$array[1]} = "new";
	##################
	# #-- create table
	##################
	#-- primarykey  --
	my @createtableconfigpart;  
	for (my $i=5; $i<@array; $i++){ push(@createtableconfigpart, "`$array[$i]`");	} 
	my $primarykey= join ',', @createtableconfigpart;
	$primarykey= join '', " PRIMARY KEY( ", "$primarykey ))";
	#---- create table config part --------
	my @createtable;
		if ( $array[2] eq "D"){ @createtable= "$createtableconfigpart[0] Date";	}
		else { @createtable= "$createtableconfigpart[0] DATETIME"; }
	for (my $i=1; $i<@createtableconfigpart; $i++){ 
		push (@createtable, "$createtableconfigpart[$i] VARCHAR(100)");  }		
	# ---- create table file part -----------
	my @createtablefilepart;
	open(my $dbh, '<', $_) or die "Could not open '$_' $!\n";

		while (my $line1 = <$dbh>) { chomp ($line1); @createtablefilepart= split (/;/, $line1 ); 
			if (($createtablefilepart[0] eq "Period start time") or ($createtablefilepart[0] eq "PERIOD_START_TIME")) {last; };
		}

	for (my $i=@createtableconfigpart ; $i<@createtablefilepart; $i++){
		my $count= length $createtablefilepart[$i];
		my $edited= "";			
		if ($count > 63){
		my @tolong= split (/ /, $createtablefilepart[$i]);
		foreach my $tmp (@tolong){
			$count = (length $edited)+(length $tmp);
			unless ($count > 63){   $edited= join '', $edited, $tmp; }
			}
		$createtablefilepart[$i] = 	$edited
		}
		push (@createtable, "`$createtablefilepart[$i]` float default NULL")	
		}
					
	my $createtable= join ',', @createtable;
	 my $sql= "CREATE TABLE IF NOT EXISTS $array[1] ( ";
	 $sql= join ' ', $sql, "$createtable , $primarykey ; ";
	   # print $sql;
	my $sth = $databaseh->prepare($sql);
	$sth->execute( );
	 }
	#################
	# # insert values
	#################
	open(my $dbh, '<', $_) or die "Could not open '$_' $!\n";
	my $start= 0;
	my @camaatend;
	my $lenforcama;
	my @insertarray;
	while (my $line1 = <$dbh>) { 
		chomp ($line1); @insertarray= split (/;/, $line1 ); 
		if (($insertarray[0] eq "Period start time") or ($insertarray[0] eq "PERIOD_START_TIME")) { 
			@camaatend= split /;/, $line1;
			$lenforcama= @camaatend;
			last; }
		$start++;
	}
	# print "\n==b==$lenforcama ===\n";	
	my $cc=0;
	while (my $line1 = <$dbh>) { 
	if ($cc > $start){
	# print $line1;
	chomp ($line1); @insertarray= split (/;/, $line1 );
	# print @insertarray;
	if ( @insertarray < $lenforcama ){ 
	$lenforcama= @insertarray;print "\n==hell==$lenforcama ===\n"; 
	$line1= join '', $line1, "null";@insertarray= split (/;/, $line1 );
	}
	$lenforcama= @insertarray;
	# print "\n==a==$lenforcama ===\n";
	my @sql;		
	foreach (@insertarray){ push (@sql, "\"$_\""); }
	
	my $sql = join ',', @sql;
	my $insert = "INSERT INTO $array[1] values ( ";
	$sql = join '', $insert, "$sql );";
	 # print $sql;
	my $sth = $databaseh->prepare($sql);
	$sth->execute( );	
		}
	$cc++;
	}	
	} #end if
print "\n======\n";
}

exit;
