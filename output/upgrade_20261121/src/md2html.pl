use strict; use warnings; use utf8; binmode STDIN,':utf8'; binmode STDOUT,':utf8';
my @l=<STDIN>; my $title=''; my $h='';
sub esc{ my $s=shift; $s=~s/&/&amp;/g; $s=~s/</&lt;/g; $s=~s/>/&gt;/g; return $s; }
sub inl{ my $s=esc(shift); $s=~s/`([^`]+)`/<code>$1<\/code>/g; $s=~s/\[([^\]]+)\]\(([^)]+)\)/<a href="$2" rel="noopener">$1<\/a>/g; return $s; }
my $intable=0;
for(@l){ chomp; s/\r$//;
  if(/^# (.*)/){ $title=$1; $h.="<h1>".esc($1)."</h1>\n"; next; }
  if(/^\|---/){ next; }
  if(/^\|(.*)\|$/){ my @c=split /\s*\|\s*/, $1; shift @c if @c && $c[0] eq ''; my $tag=$intable?'td':'th'; $h.="<table>\n" unless $intable; $intable=1; $h.="<tr>".join('',map{"<$tag>".inl($_)."</$tag>"}@c)."</tr>\n"; next; }
  if($intable){ $h.="</table>\n"; $intable=0; }
  next if /^\s*$/; $h.="<p>".inl($_)."</p>\n";
}
$h.="</table>\n" if $intable;
print "<!doctype html><html lang=\"ko\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>".esc($title)."</title><meta name=\"robots\" content=\"noindex\"><style>body{margin:0;padding:16px;background:#0A1224;color:#E7EDF6;font-family:'Malgun Gothic','Apple SD Gothic Neo',sans-serif;font-size:13px;line-height:1.6}h1{font-size:18px;color:#FFA24D}a{color:#FFA24D;word-break:break-all}table{width:100%;border-collapse:collapse;table-layout:fixed}td,th{border:1px solid #26375F;padding:6px;vertical-align:top;word-break:break-all}th{background:#12203C}code{font-size:11.5px}</style></head><body>\n$h<p><a href=\"../\">← 돌아가기</a></p></body></html>\n";
