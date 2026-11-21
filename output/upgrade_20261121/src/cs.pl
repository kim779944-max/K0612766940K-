#!/usr/bin/perl
# usage: cs.pl "query" [n]  -> prints idx|title|license|artist|w x h|thumburl(800)|descurl
use strict; use warnings; use JSON::PP; use utf8;
binmode STDOUT, ':utf8';
my ($q,$n)=@ARGV; $n||=8;
my $enc = $q; $enc =~ s/([^A-Za-z0-9_.~-])/sprintf("%%%02X",ord($1))/ge;
my $url="https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=$n&gsrsearch=$enc%20filetype:bitmap&prop=imageinfo&iiprop=url|size|extmetadata&iiurlwidth=800&iiextmetadatafilter=LicenseShortName|Artist|LicenseUrl";
my $js=`curl -s -A "KTS-photo-fetch/1.0 (contact via site)" "$url"`;
my $d=eval{decode_json($js)} or die "bad json\n";
my $p=$d->{query}{pages}||{};
for my $k (sort { $p->{$a}{index} <=> $p->{$b}{index} } keys %$p){
  my $pg=$p->{$k}; my $ii=$pg->{imageinfo}[0]||next; my $m=$ii->{extmetadata}||{};
  my $lic=$m->{LicenseShortName}{value}//'?'; my $art=$m->{Artist}{value}//'?'; $art=~s/<[^>]+>//g; $art=~s/\s+/ /g;
  print join('|',$pg->{index},$pg->{title},$lic,substr($art,0,60),"$ii->{width}x$ii->{height}",$ii->{thumburl}//'',$ii->{descriptionurl}),"\n";
}
