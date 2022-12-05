#!/usr/bin/perl
#use 5.010;
use strict;
use warnings;
use XML::LibXML;
use DBI;

my $i=0;
chomp (my $filename =`ls BSC-*.xml`);
my @dossier= split(/\./, $filename);
`mkdir $dossier[0]`;
#print "$filename"; 
my $dom = XML::LibXML->load_xml(location => $filename);
my $val;
my $valnam;
#Extraire classes et les mettre en matrice @allcasses
my @allcasses;
my %allcasses;
map {  $allcasses{$_->to_literal()} +=1 } $dom->findnodes('//managedObject/@class');
foreach my $key (keys %allcasses){
				push (@allcasses, $key);
				}
#######################
#CONNECT to DB
#######################

my $dbfile = join "_.", $dossier[0],"db";

my $dsn      = "dbi:SQLite:dbname=$dbfile";
my $user     = "";
my $password = "";
my $dbh = DBI->connect($dsn, $user, $password, {
   PrintError       => 0,
   RaiseError       => 1,
   AutoCommit       => 1,
   FetchHashKeyName => 'NAME_lc',
});			
				
# @allcasses= ("BSC", "ADJL");
#################################
#Pour chaque classe 
#################################
foreach my $class (@allcasses) {
	#recupiration des blocs de cette classe.
	my $sclass  = join '', ('//managedObject[@class="', $class,'"]');
	my $AllBlocks  = join '', ("<formxml> \n", $dom->findnodes($sclass),"\n</formxml>");
	my $xmlAllBlocks = XML::LibXML->load_xml(string => $AllBlocks);

	#recherche exhaustive des attributs de chaque tag de cette classe.
	my $orde=0;
	my @ExhausTable;	
		
	{   # remarque; tu peux simplifier par l'élimination de ce recherche. 
		# on est sûr qu'il y'a que 4 attrs à l'interieur..
	my %attributes; #de tag managedObject
	map { $val = $_->getName;  $valnam= $_-> to_literal();
			
		if (! exists ($attributes{$val})) {
			$attributes{$val} = 0;
			if ($val eq 'distName'){
				my @dist= 	split (/\//, $valnam);
				foreach my $dist (@dist){
					my @valname= split (/-/, $dist);
					push (@ExhausTable, $valname[0]);
					$orde++;
				}
			  }
			else {
				push (@ExhausTable, $val);
				$orde++;
			  }
			
		} ;
		} $xmlAllBlocks->findnodes('//managedObject/@*');
	}
	##########################
	#Ecrire l'en tête, les ids
	###########CSV############			
	########### BD ##############
	#my $sql ="CREATE TABLE people (classId VARCHAR(100) , versionid VARCHAR(100), distNameid VARCHAR(100),BSCid VARCHAR(100), PRIMARY KEY ('calssid', 'version', 'distName', 'BSCid') )";
	my $createtable= join ' ', "CREATE TABLE", "$class ("; 
	my $primarykey= "PRIMARY KEY (";
	my $len= @ExhausTable;
	for (my $i++; $i< $len-1; $i++){
		$primarykey= join '', $primarykey, "'$ExhausTable[$i]',";
	}
	$primarykey= join '', $primarykey, "'$ExhausTable[$len-1]' ) )";

	{
	my %hash;
	my $i=0;

	foreach my $value ( $xmlAllBlocks->findnodes("//managedObject/p/@*" )) {  #[\@class='$class']
		my $key = $value->to_literal();
		
		if (! exists $hash{$key}){
			my $ind = $value->findvalue("count(./../preceding-sibling::p)");
			$ind= $ind +$orde;
			$hash{$key}=0;

			splice @ExhausTable, $ind, 0, $key;
		}
	}	
	}
	#####################################
	#Ajouter les autres attributs en tête
	################## BD ##################
	$len = @ExhausTable;
	foreach (@ExhausTable){
	$createtable= join '', $createtable, "$_ VARCHAR(100),";
	}
	my $sql = join ' ', $createtable, $primarykey;
	#print $sql;
	$dbh->do($sql);

#####################################
# Pour chaque bloc 
#####################################
foreach my $OneBlock ($xmlAllBlocks-> findnodes('//managedObject')) {

	my $xmlOneBlock  = join ('', ("<formxml>\n", $OneBlock,"\n</formxml>"));
	$xmlOneBlock = XML::LibXML->load_xml(string => $xmlOneBlock);

	my %hash;
	#obtenir les valeurs des Ids et split distName
	map { $val= $_-> getName; $valnam= $_-> to_literal(); 
		  if ($val eq 'distName'){
			my @dist= 	split (/\//, $valnam);
			foreach my $dist (@dist){
				my @valname= split (/-/, $dist);
				$hash{$valname[0]}= $valname[1];
				}
			}
		  else {
			$hash{$_-> getName}= $_-> to_literal(); 
		  }
		}$xmlOneBlock->findnodes('//managedObject/@*');

	map { $hash{$_->{name}} = $_->to_literal();} $xmlOneBlock->findnodes("//managedObject/p");
		############################
		#Ecrire le contenu
		##########  BD  ############
	#$sql = "INSERT INTO people (fna4me, lname, email)  VALUES ('$fname', '$lname', '$email')";
	my $insertheader= join ' ', "INSERT INTO", "$class (";
	my $insertcontenu= "VALUES (";
	$len= @ExhausTable;
	for (my $i=0; $i<$len-1; $i++){
			$insertheader= join '', $insertheader, "$ExhausTable[$i],";
			if (exists ($hash{$ExhausTable[$i]})) {
				$insertcontenu= join '', $insertcontenu, "'$hash{$ExhausTable[$i]}',";
			}
			else {
				$insertcontenu= join '', $insertcontenu, "' ',";
			}
		}

	$insertheader= join '', $insertheader, "$ExhausTable[$len-1])";

	if (exists ($hash{$ExhausTable[$len-1]})) {
		$insertcontenu= join '', $insertcontenu, "'$hash{$ExhausTable[$len-1]}')";
		}
	else {
		$insertcontenu= join '', $insertcontenu, "' ')";
		}
	my $sql = join '', $insertheader, $insertcontenu;
	#print $sql;
	$dbh->do($sql);
	}
}
print "\nEXEC_ENDED \n\n";
print "\nthere are ".@allcasses.' classes';
print "\nthere are $i lists\n";
$i= $i + @allcasses;
print "There are $i tables";


__END__
