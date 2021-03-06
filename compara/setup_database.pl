#!/usr/bin/perl -w

use strict;
use strict;
use Cwd 'abs_path';
use File::Basename;
use Module::Load;

## find the full path to the directory that this script is executing in
our $dirname;
BEGIN {
  $dirname  = dirname(abs_path($0));
}
use lib "$dirname/../modules";
use lib "$dirname/../gff-parser";
use EasyImport::Core;
use EasyImport::Compara;

## load parameters from an INI-style config file
my %sections = (
  'ENSEMBL' =>	{ 	'LOCAL' => 1
          },
  'DATABASE_COMPARA' =>	{ 	'NAME' => 1,
              'HOST' => 1,
              'PORT' => 1,
              'RW_USER' => 1,
              'RW_PASS' => 1,
              'RO_USER' => 1
            },
  'DATABASE_TEMPLATE' =>	{ 	'NAME' => 1,
              'URL' => 1
            },
  'SPECIES_SET' =>	{ 	'TREE_FILE' => 1
            }
  );
## check that all required parameters have been defined in the config file
die "ERROR: you must specify at least one ini file\n",usage(),"\n" unless $ARGV[0];
my %params;
my $params = \%params;
while (my $ini_file = shift @ARGV){
        load_ini($params,$ini_file,\%sections,scalar(@ARGV));
}

my $lib = $params->{'ENSEMBL'}{'LOCAL'}.'/ensembl/modules';
my $comparalib = $params->{'ENSEMBL'}{'LOCAL'}.'/ensembl-compara/modules';
push @INC, $lib;
push @INC, $comparalib;
load Bio::EnsEMBL::Compara::DBSQL::DBAdaptor;
load Bio::EnsEMBL::Compara::Graph::NewickParser;
load Bio::EnsEMBL::Compara::SpeciesTreeNode;
load Bio::EnsEMBL::Compara::SpeciesTree;

# create the compara database from a template
# populate ncbi_taxa_node and ncbi_taxa_tree tables

setup_compara_db($params);

add_species_tree($params);

sub usage {
	return "USAGE: perl setup_database.pl ini_file";
}
