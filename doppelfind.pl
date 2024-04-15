#!/usr/bin/perl
##############################################################################
#
#  DOPPELFIND duplicate files finder
#  2021 (c) Vladi Belperchinov-Shabanski "Cade"
#  http://cade.noxrun.com
#  <cade@noxrun.com> <cade@cpan.org> <shabanski@gmail.com> 
#
#  GPL
#
##############################################################################
use strict;
use Data::Tools;
use POSIX;

$|++;

my %SZ; # size only
my %PH; # partial hash
my %FH; # full hash

my $z;

#my @files = glob_tree( map { "$_/*" } @ARGV );
print STDERR "scanning files...\n";
my $files = fftwalk( { MODE => 'F' }, @ARGV );
my $az = @$files;
print STDERR "found files: $az\n";

print STDERR "scanning sizes...\n";
my $z;
for my $e ( @$files )
  {
  my $sz = -s $e;
  next unless $sz > 1; # FIXME: TODO: OPTION minsize
  my $rep = !( $z++ % 100 ) ? int( $z / 100 ) % 2 ? '*  ' : '  *' : undef;
  print STDERR "  $rep           \r" if $rep;
  push @{ $SZ{ $sz } }, $e;
  }
$az = $z;

print STDERR "scanning partial hashes...\n";
$az = filter_hash_groups( $az, \%SZ,  \%PH, sub { return sha1_hex( load_file_part( shift ) ) } );
undef %SZ;
print STDERR "scanning full hashes...\n";
$az = filter_hash_groups( $az, \%PH,  \%FH, sub { return sha1_hex_file( shift )              } );
undef %PH;
print STDERR "results...\n";
$az = filter_hash_groups( $az, \%FH, undef, sub { print( shift() . "\n" ); return undef;     }, 1 );


sub filter_hash_groups
{
  my $cc = shift;
  my $fh = shift;
  my $th = shift;
  my $su = shift;
  my $sp = shift;

  my $az;
  my $z;
  while( my ( $p, $ea ) = each %$fh )
    {
    if( @$ea < 2 )
      {
      $z++;
      next;
      }
    for my $e ( @$ea )
      {
      $z++;
      $az++;
      my $prc = sprintf "  %4.1f%%", 100*$z/$cc;
      print STDERR "  $prc $z              \r";
      my $h = $su->( $e );
      push @{ $th->{ $h } }, $e if $th;
      }
    print "---\n" if $sp;
    }
  
  return $az;  
}


sub load_file_part
{
   my $data;
   my $f;
   sysopen $f, shift(), O_RDONLY;
   sysread $f, $data, 73*1024;
   return $data;
}
