#!/usr/bin/perl
# 사용: perl verify_static.pl in/x.html out/x_design.html  → JSON 한 줄
use strict; use warnings; use Digest::SHA qw(sha256_hex);
sub slurp { local $/; open my $f, '<:raw', $_[0] or die "$_[0]: $!"; my $s = <$f>; close $f; $s }
my ($A, $B) = map { slurp($_) } @ARGV[0,1];
sub scripts { my @s = ($_[0] =~ m{<script\b[^>]*>(.*?)</script>}gsi); @s }
my @sa = scripts($A); my @sb = scripts($B);
my $ha = sha256_hex(join("\x00", @sa)); my $hb = sha256_hex(join("\x00", @sb));
my $same = (@sa == @sb) ? 1 : 0; if ($same) { for my $i (0..$#sa) { $same = 0 if $sa[$i] ne $sb[$i] } }
my (%id, %cl); while ($A =~ /\bid\s*=\s*["']([^"'<>+]+)["']/g) { $id{$1} = 1 }
while ($A =~ /\bclass\s*=\s*["']([^"'<>+]*)["']/g) { $cl{$_} = 1 for grep { length } split /\s+/, $1 }
my @mid = grep { $B !~ /\bid\s*=\s*["']\Q$_\E["']/ } sort keys %id;
my @mcl = grep { my $t = $_; $B !~ /\bclass\s*=\s*["'][^"']*(?<![\w-])\Q$t\E(?![\w-])[^"']*["']/ } sort keys %cl;
sub txt { my $s = shift; $s =~ s{<script\b.*?</script>}{ }gsi; $s =~ s{<style\b.*?</style>}{ }gsi; $s =~ s{<!--.*?-->}{ }gs; $s =~ s{<[^>]+>}{ }g; $s =~ s/\s+/ /g; $s =~ s/^ | $//g; $s }
my ($ta, $tb) = (txt($A), txt($B));
sub urls { my %u; $u{$1} = 1 while $_[0] =~ m{((?:https?:)?//[A-Za-z0-9.-]+\.[a-z]{2,}[^\s"'<>)]*)}g; %u }
my %ua = urls($A); my %ub = urls($B); my @new = grep { !$ua{$_} } sort keys %ub;
my $j = sub { my @a = @_; '[' . join(',', map { my $x = $_; $x =~ s/(["\\])/\\$1/g; "\"$x\"" } @a) . ']' };
printf '{"scripts_in":%d,"scripts_out":%d,"script_sha256_in":"%s","script_sha256_out":"%s","script_identical":%s,"ids":%d,"ids_missing":%s,"class_tokens":%d,"class_missing":%s,"text_identical":%s,"text_len":[%d,%d],"new_external_refs":%s}'."\n",
  scalar(@sa), scalar(@sb), $ha, $hb, $same ? 'true' : 'false', scalar(keys %id), $j->(@mid), scalar(keys %cl), $j->(@mcl), ($ta eq $tb) ? 'true' : 'false', length($ta), length($tb), $j->(@new);
