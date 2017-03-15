#!/usr/bin/perl -w

use strict;
use EasyImport::Core;
use Bio::EnsEMBL::DBSQL::DBAdaptor;

## load parameters from an INI-style config file
my %sections = (
  'DATABASE_CORE' =>	{ 	'NAME' => 1,
              'HOST' => 1,
              'PORT' => 1,
              'RO_USER' => 1
            },
  'META' => { 'ASSEMBLY.BIOPROJECT' => 1,
              'ASSEMBLY.LOCUS_TAG' => 1,
              'SPECIES.EMBL_DIVISION' => 1
            }
  );
## check that all required parameters have been defined in the config file
die "ERROR: you must specify at least one ini file\n",usage(),"\n" unless $ARGV[0];
my %params;
my $params = \%params;
while (my $ini_file = shift @ARGV){
	load_ini($params,$ini_file,\%sections,scalar(@ARGV));
}



my $dbname = $params->{'DATABASE_CORE'}{'NAME'};

my $dba = Bio::EnsEMBL::DBSQL::DBAdaptor->new(
    -user   => $params->{'DATABASE_CORE'}{'RO_USER'},
    -dbname => $dbname,
    -host   => $params->{'DATABASE_CORE'}{'HOST'},
    -port   => $params->{'DATABASE_CORE'}{'PORT'},
    -driver => 'mysql'
);

my $meta_container = $dba->get_adaptor("MetaContainer");

# Get meta names from db

my $production_name = $meta_container->get_production_name();
my $scientific_name = $meta_container->get_scientific_name();
my $display_name    = $meta_container->get_display_name();
my $assembly_name   = $meta_container->single_value_by_key('ASSEMBLY.NAME');
my $taxid           = $meta_container->single_value_by_key('SPECIES.TAXONOMY_ID');
$display_name .= '_'.$assembly_name;

# convert display name spaces to underscores
$display_name =~ s/ /_/g;

my $outdir = 'exported';
mkdir $outdir;

# Get all scaffolds

my $slice_adaptor = $dba->get_SliceAdaptor();
my @supercontigs  = @{$slice_adaptor->fetch_all('toplevel')};
my $supercontig_count = 0;

open (EMBL, ">", "$outdir/$display_name.embl") or die $!;

my $prefix = $params->{META}{'ASSEMBLY.LOCUS_TAG'}.'_';
my $division = $params->{META}{'SPECIES.EMBL_DIVISION'};
my $project = $params->{META}{'ASSEMBLY.BIOPROJECT'};
my $date = '14-Mar-2017';
my $locus = 10;
my $features;
while (my $slice = shift @supercontigs) {
    my $topology = $slice->is_circular() ? 'circular' : 'linear';
    my $seq_name = $slice->seq_region_name();
    my $coding_table = $slice->get_all_Attributes('coding_table')->[0];
    my $seq = $slice->seq();
    print EMBL 'ID   XXX; XXX; '.$topology.'; genomic DNA; STD; '.$division.'; '.length($seq),' BP.',"\n";
    print EMBL 'XX',"\n";
    print EMBL 'AC   XXX',";\n";
    print EMBL 'XX',"\n";
    print EMBL 'AC * '.$seq_name,";\n";
    print EMBL 'XX',"\n";
    print EMBL 'PR   Project:'.$project,";\n";
    print EMBL 'XX',"\n";
    print EMBL 'DE   '.$scientific_name.' genome assembly, scaffold: '.$seq_name,"\n";
    print EMBL 'XX',"\n";
    print EMBL 'RN   [1]',"\n";
    print EMBL 'RA   GenomeHubs',"\n";
    print EMBL 'RT   "Draft assembly"',"\n";
    print EMBL 'RL   Submitted ('.$date.') to the INSDC.',"\n";
    print EMBL 'XX',"\n";

    print EMBL to_fixed_width('FT','source','1..'.length($seq)),"\n";
    print EMBL to_fixed_width('FT','','/organism="'.$scientific_name.'"'),"\n";
    print EMBL to_fixed_width('FT','','/mol_type="genomic DNA"'),"\n";
    print EMBL to_fixed_width('FT','','/db_xref="taxon:'.$taxid.'"'),"\n";
    print EMBL to_fixed_width('FT','','/note="contig: '.$seq_name.'"'),"\n";

    while ($seq =~ /[^n](n+)/ig) {
      print EMBL to_fixed_width('FT','assembly_gap',($-[0]+2).'..'.$+[0]),"\n";
      print EMBL to_fixed_width('FT','','/estimated_length='.($+[0]-$-[0]-1)),"\n";
      print EMBL to_fixed_width('FT','','/gap_type="unknown"'),"\n";
    }
    my $genes = $slice->get_all_Genes();
    while (my $gene = shift @{$genes}){
      my $locus_tag = $prefix.sprintf("%08d", $locus);
      my @gene_coords = ([$gene->seq_region_start(),$gene->seq_region_end()]);
      print EMBL to_fixed_width('FT','gene',format_location(\@gene_coords,$gene->strand())),"\n";
      print EMBL to_fixed_width('FT','','/locus_tag="'.$locus_tag.'"'),"\n";
      my $transcripts = $gene->get_all_Transcripts();
      my @exon_coords;
      my @cds_coords;
      while (my $transcript = shift @{$transcripts} ) {
        my $exons = $transcript->get_all_Exons();
        while (my $exon = shift @{$exons} ) {
           push @exon_coords,[$exon->seq_region_start(),$exon->seq_region_end()];
        }
        if ($gene->biotype() eq 'protein_coding'){
          print EMBL to_fixed_width('FT','mRNA',format_location(\@exon_coords,$gene->strand())),"\n";
          print EMBL to_fixed_width('FT','','/locus_tag="'.$locus_tag.'"'),"\n";
          my $CDSs = $transcript->get_all_CDS();
          my $frame = $CDSs->[0]->phase() + 1;
          while (my $CDS = shift @{$CDSs} ) {
             push @cds_coords,[$CDS->seq_region_start(),$CDS->seq_region_end()];
          }
          print EMBL to_fixed_width('FT','CDS',format_location(\@cds_coords,$gene->strand())),"\n";
          print EMBL to_fixed_width('FT','','/locus_tag="'.$locus_tag.'"'),"\n";
          print EMBL to_fixed_width('FT','','/codon_start='.$frame),"\n";
	}
        else {
          print EMBL to_fixed_width('FT',$gene->biotype(),format_location(\@exon_coords,$gene->strand())),"\n";
          print EMBL to_fixed_width('FT','','/locus_tag="'.$locus_tag.'"'),"\n";
        }
      }
      $locus += 10;
    }
    print EMBL 'SQ',"\n";
    print EMBL seq_to_block($seq);
    print EMBL '//',"\n";
}
close EMBL;

sub seq_to_block {
  my $seq = shift;
  my $seq_len = length $seq;
  #my @chunks = split /(\w{10})/,$seq;
  my @chunks = $seq =~ m[.{1,10}]g;
  my $block = '';
  for (my $i = 0; $i < @chunks; $i+=6){
    my $line = '     ';
    for (my $j = $i; $j < @chunks && $j < $i + 6; $j++){
      $line .= $chunks[$j].' ';
    }
    my $position = ($i + 6) * 10;
    $position = $seq_len if $position > $seq_len;
    $block .= sprintf "%-71s%+9s\n",$line,$position;
  }
  return $block;
}

sub to_fixed_width {
  my ($type,$name,$label) = @_;
  return sprintf "%-5s%-16s%s",$type,$name,$label;
}

sub format_location {
  my $coords = shift;
  my $strand = shift;
  my $location;
  if (@{$coords} > 1){
    my @arr = map { $_->[0].'..'.$_->[1] } @{$coords};
    @arr = reverse @arr if $strand < 1;
    $location = 'join('.join(',',@arr).')';
  }
  else {
    $location = $coords->[0][0].'..'.$coords->[0][1];
  }
  $location = 'complement('.$location.')' if $strand < 1;
  return $location;
}

sub usage {
	return "USAGE: perl /path/to/export_embl.pl /path/to/config_file.ini";
}

__END__

docker run --rm            --name easy-import-operophtera_brumata_v1_core_32_85_1            --link genomehubs-mysql            -v ~/demo/genomehubs-import/import/conf:/import/conf            -v ~/demo/genomehubs-import/import/data:/import/data            -v ~/demo/genomehubs-import/download/data:/import/download            -v ~/demo/genomehubs-import/blast/data:/import/blast            -e DATABASE=operophtera_brumata_v1_core_32_85_1            -e FLAGS="-E"  easy-import
