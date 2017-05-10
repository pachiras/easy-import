#!/usr/bin/perl -w

use strict;
use Cwd 'abs_path';
use File::Basename;

## find the full path to the directory that this script is executing in
our $dirname;
BEGIN {
  $dirname  = dirname(abs_path($0));
}
use lib "$dirname/../modules";
use lib "$dirname/../gff-parser";
use EasyImport::Core;
use EasyImport::Xref;

## load parameters from an INI-style config file
## check that all required parameters have been defined in the config file
die "ERROR: you must specify at least one ini file\n",usage(),"\n" unless $ARGV[0];
my %params;
my $params = \%params;
while (my $ini_file = shift @ARGV){
	load_ini($params,$ini_file);
}

## download/obtain files using methods suggested by file paths and extensions
die "ERROR: a blastp output file must be specified at [FILES] BLASTP\n" unless $params->{'FILES'}{'BLASTP'};
my %infiles;
($infiles{'BLASTP'}{'name'},$infiles{'BLASTP'}{'type'}) = fetch_file($params->{'FILES'}{'BLASTP'});


## check that an BLASTP file has been specified
die "ERROR: a blastp output file must be specified at [FILES] BLASTP\n" unless $infiles{'BLASTP'};
die "ERROR: an xref must be specified at [XREF] BLASTP\n" unless $params->{'XREF'}{'BLASTP'};

## connect to the db
my $dbh = core_db_connect($params);

## load the IPRSCAN file into the database
push @ARGV,$infiles{'BLASTP'}{'name'};
my $hits = read_blastp($dbh,$params);






__DATA__
nBa.0.1-t10350-RA	sp|Q9GPH3|ATFC_BOMMO	68.87	212	52	3	121	322	29	236	2e-79	  248	322	236	sp|Q9GPH3|ATFC_BOMMO Activating transcription factor of chaperone OS=Bombyx mori GN=ATFC PE=2 SV=1	4VE6ST28AQ4ETPA3APIAQP1VA1LPSQ1PADWWQTI3-V-P-V-N-Q-L-P-E-G-YDEYC1SLQD1LV8AS6PH1RS1ASSAPNSAPSQPSR1PSRPSPSPP-P-1SPPRRS4DE2CSIASPGS1PL1P-Y-ST1NP26IV4SK3ST2KQ3DE2DE13GA13
nBa.0.1-t10350-RA	sp|P18848|ATF4_HUMAN	40.62	128	54	3	204	319	229	346	2e-13	73.9	322	351	sp|P18848|ATF4_HUMAN Cyclic AMP-dependent transcription factor ATF-4 OS=Homo sapiens GN=ATF4 PE=1 SV=3	1AG3P-S-R-S-AH3PTQRSG2RNSR1PL2SPPGRVS-S-T-D-D-D-WL1IG1GA5SDRPNPVGDE-K-M-V-A-A-K-V-K-G-E-K-L1RKRKSLRK1KM4NT9KR2IQ1VA1LTSG1ECQKSE1RE1RKHNTEDA1GKDEKRCASDDS1QARK2RQ3GD1MIREDELVFR2KR1
nBa.0.1-t10350-RA	sp|Q9ES19|ATF4_RAT	42.19	128	50	4	204	319	227	342	3e-13	73.2	322	347	sp|Q9ES19|ATF4_RAT Cyclic AMP-dependent transcription factor ATF-4 OS=Rattus norvegicus GN=Atf4 PE=1 SV=1	1AG3PH1RP1AT1PRSA1Q-S-S-1RD1SL1-S1SGSV2SG1T-D-D-D-W-C-I-S-G-5SD-P-P-G-V-S-V-T-A-K-V-KRTNEVKDL1RKRKSLRK1KM4NT9KR2IQ1VA1LTSG1ECQKSE1RE1RKHNTEDA1GKDE1CASDDS1QARK2RQ3GD1MIREDELVFR2KR1
nBa.0.1-t10350-RA	sp|Q06507|ATF4_MOUSE	42.50	120	48	4	216	319	230	344	5e-12	69.3	322	349	sp|Q06507|ATF4_MOUSE Cyclic AMP-dependent transcription factor ATF-4 OS=Mus musculus GN=Atf4 PE=1 SV=2	3SH2RSST1-R-A2SD-N-L-P2RGSG1TRDGD-D-W-C-I-1GP5SD-P-P-G-V-S-L-T-A-K-V-KRTNEVKDL1RKRKSLRK1KM4NT9KR2IQ1VA1LTSG1ECQKSE1RE1RKHNTEDA1GKDE1CASDDS1QARK2RQ3GD1MIREDELVFR2KR1
nBa.0.1-t10350-RA	sp|Q6P788|ATF5_RAT	42.50	80	43	1	242	318	195	274	2e-11	66.6	322	281	sp|Q6P788|ATF5_RAT Cyclic AMP-dependent transcription factor ATF-5 OS=Rattus norvegicus GN=Atf5 PE=1 SV=1	2KA2-P-S-PSARSNTVRDG2RKSQRK1KRED3NS2TL4KR1KR2IG1VA1LESG1EC1SG1REKA1HNTRDE1GRDEKRCASEDSLVQE3RQ1LV1GD1MLRIDELVFY2KR
nBa.0.1-t10350-RA	sp|O70191|ATF5_MOUSE	42.50	80	43	1	242	318	197	276	3e-11	66.6	322	283	sp|O70191|ATF5_MOUSE Cyclic AMP-dependent transcription factor ATF-5 OS=Mus musculus GN=Atf5 PE=1 SV=2	2KA2-P-S-PSARSNTVRDG2RKSQRK1KRED3NS2TL4KR1KR2IG1VA1LESG1EC1SG1REKA1HNTRDE1GRDEKRCASEDSLVQE3RQ1LV1GD1MLRIDELVFY2KR
nBa.0.1-t10350-RA	sp|Q3ZCH6|ATF4_BOVIN	40.50	121	57	3	212	318	223	342	4e-11	66.6	322	348	sp|Q3ZCH6|ATF4_BOVIN Cyclic AMP-dependent transcription factor ATF-4 OS=Bos taurus GN=ATF4 PE=1 SV=1	1ASSLPG3SD2RSST1PRP-SG2RNSK1TLDLDSDPWGCAIL2-S-S5SD-P-P-G-E-K-M-V-A-A-K-V-KRGNEVKDL1RKRKSLRK1KM4NT9KR2IQ1VA1LTSG1ECQKSE1RE1RKHNTEDA1GKDE1CASDDS1QARK2RQ3GDLQMIREDELVFR2KR
nBa.0.1-t10350-RA	sp|Q6NW59|ATF4_DANRE	35.81	148	81	3	171	318	200	333	5e-11	66.6	322	339	sp|Q6NW59|ATF4_DANRE Cyclic AMP-dependent transcription factor ATF-4 OS=Danio rerio GN=atf4 PE=2 SV=1	AVIVQL1VT1LKSE1PQDNWITSVDACPS1YS2QGAILSE-E-L-1RSHGRSAP1QHLQASSDPLQE2RSSR1SK1SYPSQRSPSD1RESA2PASLSKPG1SVSK1DSD-D-W-C-I-2RA2PVY-S-R-N-V-D-DERKRKSLRK1KM4NT9KRAV1IQ1VS1LN2ECQSSE1RE1RKHNTRDE1GSDE1CASDDS1QS3RQ2KRGD1MLREDELMFRKT2
nBa.0.1-t10350-RA	sp|Q9Y2D1|ATF5_HUMAN	44.78	67	37	0	252	318	209	275	1e-10	64.7	322	282	sp|Q9Y2D1|ATF5_HUMAN Cyclic AMP-dependent transcription factor ATF-5 OS=Homo sapiens GN=ATF5 PE=1 SV=4	2RKSQRK1KRED3NS2TL4KR1KR2IG1VA1LESG1EC1SG1REKA1HNTRDE1GKDEKRCASEDSLVQE3RQ1LV1GD1MLRIDELVFY2KR
nBa.0.1-t07619-RA	sp|P0CH87|PA1_VESCR	33.07	257	158	7	54	306	47	293	1e-29	  119	313	301	sp|P0CH87|PA1_VESCR Phospholipase A1 OS=Vespa crabro PE=1 SV=1	1MFFICT4GSISPANTGAPEANVFTVEVIMVATKVAYL1RDQK1ENSYNL1AI1LTND1ERYMLA1-CSTSNQETIPA2AKNLSA1AYNPWY2PS1AT1QLLV2RYVIVADT-V1FKVM1LVSQNKAYGNLVDP1SAKNTIHR10WS1IF2FK1LV1QERL1IL-GLKLY1WE1TI1VL3AGVPGS1EKGSKNSDAC1HQKRLISCAEATSD1IN2DQ4DSP-1KRYL1LTRETRSTAL5WYAM1Y-R-S-V-GNPGVYRN4AGNLKPPITIAGQEF-S-T-Q-D-LT1NS1NT1SAWV1LYLFATDEACVI1YHPEDCTCIL2-VSPYKAS2YPKQTPWVKSHKYC2EN1RCLVACEVTG1PNLAGKKT1NP1NT1NSSFNYNVYPXVNE1EKSA2
