use strict; use warnings; use JSON::PP; binmode STDOUT,':utf8';
my ($q,$n)=@ARGV; $n||=9;
my $enc=$q; $enc=~s/([^A-Za-z0-9_.~-])/sprintf("%%%02X",ord($1))/ge;
my $url="https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrlimit=30&gsrsearch=$enc&prop=imageinfo&iiprop=url|size|mime|extmetadata&iiurlwidth=960&iiextmetadatafilter=LicenseShortName|Artist";
my $js=`curl -s -A "KTS-photo-fetch/1.0 (https://autooneclick.com)" "$url"`;
my $d=eval{decode_json($js)} or die "bad json\n";
my $p=$d->{query}{pages}||{}; my $i=0;
for my $k (sort { $p->{$a}{index} <=> $p->{$b}{index} } keys %$p){
  my $pg=$p->{$k}; my $ii=$pg->{imageinfo}[0]||next; my $m=$ii->{extmetadata}||{};
  next unless ($ii->{mime}//'') =~ /jpeg|png|webp/;
  next if $ii->{width}<800 || $ii->{height}<500;
  my $lic=$m->{LicenseShortName}{value}//'?';
  next unless $lic =~ /^(CC0|CC BY(-SA)? [0-9.]+( [a-z]+)?|Public domain|PD.*|No restrictions)/i; next if $lic=~/NC|ND/;
  my $art=$m->{Artist}{value}//'?'; $art=~s/<[^>]+>//g; $art=~s/\s+/ /g; $art=substr($art,0,80);
  (my $t=$pg->{title})=~s/[\t\n]/ /g;
  print join("\t",$t,$art,$lic,$ii->{descriptionurl},$ii->{thumburl},$ii->{thumburl},'commons'),"\n";
  last if ++$i>=$n;
}
