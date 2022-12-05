#!/usr/bin/perl
use strict;
use warnings;
use XML::LibXML;

my $i=0;
# récupération des nomes des fichiers XML à traiter 
chomp (my $filenames =`dir BSC*.xml`);
my @filenames= split (/\s/, $filenames);
#####################
# pour chaque fichier XML faire les traitements suivants 
#####################
foreach my $filename (@filenames) {
	my @dossier= split(/\./, $filename);
	`mkdir $dossier[0]`;
	# préparation de perseur de fichier XML en question
	my $dom = XML::LibXML->load_xml(location => $filename);
	my $val;
	my $valnam;
	#Extraire les classes et les mettre en matrice @allcasses
	my @allcasses;
	my %allcasses;
	map {  $allcasses{$_->to_literal()} +=1 } $dom->findnodes('//managedObject/@class');
	foreach my $key (keys %allcasses){
					push (@allcasses, $key);
					}

####################
# Pour chaque classe
####################
foreach my $class (@allcasses) {
# récupérer des blocs de cette classe.
# c-à-d c'est on construit un fichier XML qui ne contient que les blocs 
# de cette classe en question pour faciliter le perçage, en ajoutant <formxml></formxml>
# pour conserver son format. pour utiliser findnodes() il doit y'avoir 
	my $sclass  = join '', ('//managedObject[@class="', $class,'"]');
	my $AllBlocks  = join '', ("<formxml> \n", $dom->findnodes($sclass),"\n</formxml>");
	my $xmlAllBlocks = XML::LibXML->load_xml(string => $AllBlocks);

# recherche exhaustive des attributs de chaque tag de cette classe.
	my $orde=0;
	my @ExhausTable;
	# ouvrir le fichier dans lequel on écrira les tableau
	my $FichierResulat = join '',"./$dossier[0]/", "$class.csv"; #'$dossier[0]',
	open( my $FhResultat, '>', $FichierResulat )
	  or die("Impossible d'ouvrir le fichier $FichierResulat\n$!");
	{   # remarque; tu peux simplifier par l'élimination de ce recherche. 
		# on est sûr qu'il y'a que 4 attrs à l'interieur.. de tag managedObject
		# @ExhausTable contenir les champs de l'en tête
		my %attributes; 
		map { $val = $_->getName;  $valnam= $_-> to_literal();	
			if (! exists ($attributes{$val})) {
				$attributes{$val} = 0;
				# en cas de tag distName, séparer les champs et l'ajouter à l'en tête 
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
		foreach (@ExhausTable){
		   print {$FhResultat} $_."Id,";
		}
	}
	
	{ 		# @ExhausTable contenir managedObject tags pour qu'on puisse ajouter __Id__
			# En ajoutant maintenant les <p> tag names
			my %hash;
			my $i=0;

			foreach my $value ( $xmlAllBlocks->findnodes("//managedObject/p/@*" )) {
				my $key = $value->to_literal();
				
				if (! exists $hash{$key}){
					my $ind = $value->findvalue("count(./../preceding-sibling::p)");
					$ind= $ind +$orde;
					$hash{$key}=0;

					splice @ExhausTable, $ind, 0, $key;
				}

			}

	
	}
	my $len = @ExhausTable;
	for (my $i = $orde; $i < $len; $i++) {
		print {$FhResultat} "$ExhausTable[$i],";
	 } 
	print {$FhResultat} "\n";

#########################
# pour chaque bloc 
#########################
foreach my $OneBlock ($xmlAllBlocks-> findnodes('//managedObject')) {
		# pour utiliser findnodes() on transforme ce bloque sous format d'un fichier xml
		my $xmlOneBlock  = join ('', ("<formxml>\n", $OneBlock,"\n</formxml>"));
		$xmlOneBlock = XML::LibXML->load_xml(string => $xmlOneBlock);

		my %hash;
		
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

		foreach my $attr (@ExhausTable){
				if (exists ($hash{$attr})) {
					print {$FhResultat} "$hash{$attr},";
				}
				else {
					print {$FhResultat} ",";
				}
			}
		print {$FhResultat} "\n";
		}

close($FhResultat);

			 
	####################			
	# chercher les lists de cette classe
	###################
{
		my %lists;
		my @lists;
		map { my $list = $_-> {name};
				if (! exists $lists{$list}){
				$lists{$list}=0;
				push (@lists, $list);
				#print "==>$list\n"; 
				$i++;
				}
			} $xmlAllBlocks->findnodes("//managedObject/list");

		# pour chaque list returner leurs attributs, avec un recherche exhaustive 
		# @lists= "bscOptions";
	##################
	# pour chaque list
	##################
	foreach my $list (@lists){
	# si la list exist avec des item ,i'il n'y a pas des tag <p> directment après une list
	if (! $xmlAllBlocks->findvalue("//list[\@name='$list'][position()=1]/p"))
	{
		#print $xmlAllBlocks->findvalue("//list[\@name='$list']/item");
		my @distName;
		my @ExhauListAttrs;
		my %hash;
		my %hashdist;
		# chrecher exhaustive des attributs de cette list:
		map {	
			my $val= $_->to_literal();
			if (! exists $hash{$val}){
					my $ind= $_->findvalue("count(./../preceding-sibling::p)");
					#print $ind;
					$hash{$val}= 0; 
					splice @ExhauListAttrs, $ind, 0, $val;
					#print $val."\n";
					}
			# en cas de distName séparer les champs 
			my @dist= 	split (/\//,$_->findvalue("./../../../../\@distName"));
			foreach (@dist){
				my @val= split (/-/, $_);
				if (! exists $hashdist{$val[0]}){
					$hashdist{$val[0]}=$val[1] ;
					push (@distName, $val[0]);
					}
			}
			} $xmlAllBlocks-> findnodes("//list[\@name= '$list']/item/p/\@name");

		# l'ecriture de l'en tête de cette table liste
		if (@ExhauListAttrs > 0){
			my $FichierResulat = join "$class\_$list","./$dossier[0]/", ".csv"; #\_LIST
			open( my $FhResultat, '>', $FichierResulat )
				or die("Impossible d'ouvrir le fichier $FichierResulat\n$!");
			foreach (@distName){
				print {$FhResultat} $_."Id,";
				}
			foreach (@ExhauListAttrs){
				print {$FhResultat} "$_,";
				}
			print {$FhResultat} "\n";
		@ExhauListAttrs= (@distName, @ExhauListAttrs);
		
		map {
			my %hash;
			my @dist= 	split (/\//,$_->findvalue("./../../\@distName"));
			foreach (@dist){
				my @val= split(/-/, $_);
				$hash{$val[0]}= $val[1];
				}

			 foreach ($_->findnodes("./p")){
				$hash{$_->{name}}= $_->to_literal();
				}
			foreach (@ExhauListAttrs){
				if (exists $hash{$_}){
					print {$FhResultat} "$hash{$_},";
				}
				else{
					print {$FhResultat} ",";
				}
			}
			print {$FhResultat} "\n";
			
			}$xmlAllBlocks-> findnodes("//list[\@name= '$list']/item");
		}
	} #if
	
	# sinon, la list est sans item, les tags sont ecrits directement apres la list
	else{

			my @distName;
			my @ExhauListAttrs;
			my %hash;
			my %hashdist;
		 #rechrche exhau
		 map {
				my @dist= 	split (/\//,$_->findvalue("./../\@distName"));
				foreach (@dist){
					my @val= split (/-/, $_);
					if (! exists $hashdist{$val[0]}){
						$hashdist{$val[0]}=$val[1] ;
						push (@distName, $val[0]);
						}
				}
				#last();
			} $xmlAllBlocks-> findnodes("//list[\@name='$list']");
		# en tête
		my $FichierResulat = join "$class\_$list","./$dossier[0]/", ".csv"; #\_P
		open( my $FhResultat, '>', $FichierResulat )
			or die("Impossible d'ouvrir le fichier $FichierResulat\n$!");
		foreach (@distName){
		print {$FhResultat} $_."Id,";
		}
		print {$FhResultat} "ListId,";
		print {$FhResultat} $list;
		print {$FhResultat} "\n";
		push (@distName, "ListId");
		push (@distName, $list);

		map{
			my %hash;
			my @dist= 	split (/\//,$_->findvalue("./../../\@distName"));
			foreach (@dist){
				my @val= split(/-/, $_);
				$hash{$val[0]}= $val[1];
				}
			$hash{'ListId'}= $_->findvalue("count(./preceding-sibling::p)");
			$hash{$list}= $_->to_literal();
			foreach my $val (@distName){
				if (exists $hash{$val}){
					print {$FhResultat} "$hash{$val},";
				}
				else{
					print {$FhResultat} ",";
				}
			 }
			print {$FhResultat} "\n";
			} $xmlAllBlocks-> findnodes("//list[\@name='$list']/p");


		}#esle 
	}
} # list



			#print "\nEXEC_ENDED : $FichierResulat\n";

} # end classes

	print "\n==== $filename statistics ====\n";
	print "there are ".@allcasses.' classes';
	print "\nthere are $i lists\n";
	$i= $i + @allcasses;
	print "There are $i tables\n";

} # end filenames

__END__

==== BSC_beginning.xml statistics ====
there are 43 classes
there are 23 lists
There are 66 tables


==== BSC_beginning.xml statistics ====

there are 3 classes
there are 68 lists
There are 71 tables

real	0m54.324s
user	0m53.700s
sys	0m0.568s
