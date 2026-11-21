use strict; use warnings; use JSON::PP; binmode STDOUT,':utf8';
my ($q,$n,$extra)=@ARGV; $n||=9; $extra||='';
my $enc=$q; $enc=~s/([^A-Za-z0-9_.~-])/sprintf("%%%02X",ord($1))/ge;
my $js=`curl -s -A "KTS-photo-fetch/1.0" "https://api.openverse.org/v1/images/?q=$enc&license=by,by-sa,cc0,pdm&page_size=20&mature=false$extra"`;
my $d=eval{decode_json($js)} or die "bad json: ".substr($js,0,200)."\n";
my $i=0;
for my $r (@{$d->{results}}){
  next if $r->{unstable__sensitivity} && @{$r->{unstable__sensitivity}};
  next if ($r->{width}||0) && $r->{width} < 500 && $r->{source} ne 'flickr';
  my $u=$r->{url}; if($r->{source} eq 'flickr'){ $u=~s/_[mstqnzc]\.jpg$/_b.jpg/; $u=~s/(\/\d+_[0-9a-f]+)\.jpg$/$1_b.jpg/; }
  my $t=$r->{title}//''; $t=~s/[|\t\n]/ /g; my $c=$r->{creator}//'?'; $c=~s/[|\t\n]/ /g;
  print join("\t",$t,$c,$r->{license}.' '.$r->{license_version},$r->{foreign_landing_url},$u,$r->{thumbnail},$r->{source}),"\n";
  last if ++$i>=$n;
}
