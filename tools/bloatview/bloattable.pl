#!/usr/bin/perl -w
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# bloattable [-debug] [-source] [-byte n|-obj n|-ref n] <file1> <file2> ... <filen> > <html-file>
#
# file1, file2, ... filen should be successive BloatView files generated from the same run.
# Summarize them in an HTML table.  Output the HTML to the standard output.
#
# If -debug is set, create a slightly larger html file which is more suitable for debugging this script.
# If -source is set, create an html file that prints the html source as the output
# If -byte n, -obj n, or -ref n is given, make the page default to showing byte, object, or reference statistics,
#    respectively, and sort by the nth column (n is zero-based, so the first column has n==0).
#
# See http://lxr.mozilla.org/mozilla/source/xpcom/doc/MemoryTools.html

use 5.004;
use strict;
use diagnostics;
use File::Basename;
use Getopt::Long;

# The generated HTML is almost entirely generated by a script.  Only the <HTML>, <HEAD>, and <BODY> elements are explicit
# because a <SCRIPT> element cannot officially be a direct descendant of an <HTML> element.
# The script itself is almost all generated by an eval of a large string.  This allows the script to reproduce itself
# when making a new page using document.write's.  Re-sorting the page causes it to regenerate itself in this way.



# Return the file's modification date.
sub fileModDate($) {
	my ($pathName) = @_;
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) =
		stat $pathName or die "Can't stat '$pathName'";
	return $mtime;
}


sub fileCoreName($) {
	my ($pathName) = @_;
	my $fileName = basename($pathName, "");
	$fileName =~ s/\..*//;
	return $fileName;
}


# Convert a raw string into a single-quoted JavaScript string.
sub singleQuoteString($) {
	local ($_) = @_;
	s/\\/\\\\/g;
	s/'/\\'/g;
	s/\n/\\n/g;
	s/<\//<\\\//g;
	return "'$_'";
}


# Convert a raw string into a double-quoted JavaScript string.
sub doubleQuoteString($) {
	local ($_) = @_;
	s/\\/\\\\/g;
	s/"/\\"/g;
	s/\n/\\n/g;
	s/<\//<\\\//g;
	return "\"$_\"";
}


# Quote special HTML characters in the string.
sub quoteHTML($) {
	local ($_) = @_;
	s/\&/&amp;/g;
	s/</&lt;/g;
	s/>/&gt;/g;
	s/ /&nbsp;/g;
	s/\n/<BR>\n/g;
	return $_;
}


# Write the generated page to the standard output.
# The script source code is read from this file past the __END__ marker
# @$scriptData is the JavaScript source for the tables passed to JavaScript.  Each entry is one line of JavaScript.
# @$persistentScriptData is the same as @scriptData, but persists when the page reloads itself.
# If $debug is true, generate the script directly instead of having it eval itself.
# If $source is true, generate a script that displays the page's source instead of the page itself.
sub generate(\@\@$$$$) {
	my ($scriptData, $persistentScriptData, $debug, $source, $showMode, $sortColumn) = @_;

	my @scriptSource = <DATA>;
	chomp @scriptSource;
	print <<'EOS';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
<HTML>
<HEAD>
<SCRIPT type="text/javascript">
EOS

	foreach (@$scriptData) {print "$_\n";}
	print "\n";

	print "var srcArray = [\n";
	my @quotedScriptSource = map {
		my $line = $_;
		$line =~ s/^\s+//g;
		# $line =~ s/^\/\/SOURCE\s+//g if $source;
		$line =~ s/^\/\/.*//g;
		$line =~ s/\s+$//g;
		$line eq "" ? () : $line
	} @$persistentScriptData, @scriptSource;
	my $lastQuotedLine = pop @quotedScriptSource;
	foreach (@quotedScriptSource) {print doubleQuoteString($_), ",\n";}
	print doubleQuoteString($lastQuotedLine), "];\n\n";

	if ($debug) {
		push @quotedScriptSource, $lastQuotedLine;
		foreach (@quotedScriptSource) {
			s/<\//<\\\//g;	# This fails if a regexp ends with a '<'.  Oh well....
			print "$_\n";
		}
		print "\n";
	} else {
		print "eval(srcArray.join(\"\\n\"));\n\n";
	}
	print "showMode = $showMode;\n";
	print "sortColumn = $sortColumn;\n";
	if ($source) {
		print <<'EOS';
function writeQuotedHTML(s) {
	document.write(quoteHTML(s.toString()).replace(/\n/g, '<BR>\n'));
}

var quotingDocument = {
  write: function () {
		for (var i = 0; i < arguments.length; i++)
			writeQuotedHTML(arguments[i]);
	},
  writeln: function () {
		for (var i = 0; i < arguments.length; i++)
			writeQuotedHTML(arguments[i]);
		document.writeln('<BR>');
	}
};
EOS
	} else {
		print "showHead(document);\n";
	}
	print "</SCRIPT>\n";
	print "</HEAD>\n\n";
	print "<BODY>\n";
	if ($source) {
		print "<P><TT>";
		print quoteHTML "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n";
		print quoteHTML "<HTML>\n";
		print quoteHTML "<HEAD>\n";
		print "<SCRIPT type=\"text/javascript\">showHead(quotingDocument);</SCRIPT>\n";
		print quoteHTML "</HEAD>\n\n";
		print quoteHTML "<BODY>\n";
		print "<SCRIPT type=\"text/javascript\">showBody(quotingDocument);</SCRIPT>\n";
		print quoteHTML "</BODY>\n";
		print quoteHTML "</HTML>\n";
		print "</TT></P>\n";
	} else {
		print "<SCRIPT type=\"text/javascript\">showBody(document);</SCRIPT>\n";
	}
	print "</BODY>\n";
	print "</HTML>\n";
}



# Read the bloat file into hash table $h.  The hash table is indexed by class names;
# each entry is a list with the following elements:
#	bytesAlloc		Total number of bytes allocated
#	bytesNet		Total number of bytes allocated but not deallocated
#	objectsAlloc	Total number of objects allocated
#	objectsNet		Total number of objects allocated but not deallocated
#	refsAlloc		Total number of references AddRef'd
#	refsNet			Total number of references AddRef'd but not Released
# Except for TOTAL, all hash table entries refer to mutually exclusive data.
# $sizes is a hash table indexed by class names.  Each entry of that table contains the class's instance size.
sub readBloatFile($\%\%) {
	my ($file, $h, $sizes) = @_;
	local $_;	# Needed for 'while (<FILE>)' below.

	my $readSomething = 0;
	open FILE, $file;
	while (<FILE>) {
		if (my ($name, $size, $bytesNet, $objectsAlloc, $objectsNet, $refsAlloc, $refsNet) =
			   /^\s*(?:\d+)\s+([\w:]+)\s+(\d+)\s+(-?\d+)\s+(\d+)\s+(-?\d+)\s*\([^()]*\)\s*(\d+)\s+(-?\d+)\s*\([^()]*\)\s*$/) {
			my $bytesAlloc;
			if ($name eq "TOTAL") {
				$size = "undefined";
				$bytesAlloc = "undefined";
			} else {
				$bytesAlloc = $objectsAlloc * $size;
				if ($bytesNet != $objectsNet * $size) {
					print STDERR "In '$file', class $name bytesNet != objectsNet * size: $bytesNet != $objectsNet * $size\n";
				}
			}
			print STDERR "Duplicate entry $name in '$file'\n" if $$h{$name};
			$$h{$name} = [$bytesAlloc, $bytesNet, $objectsAlloc, $objectsNet, $refsAlloc, $refsNet];
			
			my $oldSize = $$sizes{$name};
			print STDERR "Mismatch of sizes of class $name: $oldSize and $size\n" if defined($oldSize) && $size ne $oldSize;
			$$sizes{$name} = $size;
			$readSomething = 1;
		} elsif (/^\s*(?:\d+)\s+([\w:]+)\s/) {
			print STDERR "Unable to parse '$file' line: $_";
		}
	}
	close FILE;
	print STDERR "No data in '$file'\n" unless $readSomething;
	return $h;
}


my %sizes;			# <class-name> => <instance-size>
my %tables;			# <file-name> => <bloat-table>; see readBloatFile for format of <bloat-table>

# Generate the JavaScript source code for the row named $c.  $l can contain the initial entries of the row.
sub genTableRowSource($$) {
	my ($l, $c) = @_;
	my $lastE;
	foreach (@ARGV) {
		my $e = $tables{$_}{$c};
		if (defined($lastE) && !defined($e)) {
			$e = [0,0,0,0,0,0];
			print STDERR "Class $c is defined in an earlier file but not in '$_'\n";
		}
		if (defined $e) {
			if (defined $lastE) {
				for (my $i = 0; $i <= $#$e; $i++) {
					my $n = $$e[$i];
					$l .= ($n eq "undefined" ? "undefined" : $n - $$lastE[$i]) . ",";
				}
				$l .= " ";
			} else {
				$l .= join(",", @$e) . ", ";
			}
			$lastE = $e;
		} else {
			$l .= "0,0,0,0,0,0, ";
		}
	}
	$l .= join(",", @$lastE);
	return "[$l]";
}



my $debug;
my $source;
my $showMode;
my $sortColumn;
my @modeOptions;

GetOptions("debug" => \$debug, "source" => \$source, "byte=i" => \$modeOptions[0], "obj=i" => \$modeOptions[1], "ref=i" => \$modeOptions[2]);
for (my $i = 0; $i != 3; $i++) {
	my $modeOption = $modeOptions[$i];
	if ($modeOption) {
		die "Only one of -byte, -obj, or -ref may be given" if defined $showMode;
		my $nFileColumns = scalar(@ARGV) + 1;
		die "-byte, -obj, or -ref column number out of range" if $modeOption < 0 || $modeOption >= 2 + 2*$nFileColumns;
		$showMode = $i;
		if ($modeOption >= 2) {
			$modeOption -= 2;
			$sortColumn = 2 + $showMode*2;
			if ($modeOption >= $nFileColumns) {
				$sortColumn++;
				$modeOption -= $nFileColumns;
			}
			$sortColumn += $modeOption*6;
		} else {
			$sortColumn = $modeOption;
		}
	}
}
unless (defined $showMode) {
	$showMode = 0;
	$sortColumn = 0;
}

# Read all of the bloat files.
foreach (@ARGV) {
	unless ($tables{$_}) {
		my $f = $_;
		my %table;
		
		readBloatFile $_, %table, %sizes;
		$tables{$_} = \%table;
	}
}
die "No input" unless %sizes;

my @scriptData;	# JavaScript source for the tables passed to JavaScript.  Each entry is one line of JavaScript.
my @persistentScriptData;	# Same as @scriptData, but persists the page reloads itself.

# Print a list of bloat file names.
push @persistentScriptData, "var nFiles = " . scalar(@ARGV) . ";";
push @persistentScriptData, "var fileTags = [" . join(", ", map {singleQuoteString substr(fileCoreName($_), -10)} @ARGV) . "];";
push @persistentScriptData, "var fileNames = [" . join(", ", map {singleQuoteString $_} @ARGV) . "];";
push @persistentScriptData, "var fileDates = [" . join(", ", map {singleQuoteString localtime fileModDate $_} @ARGV) . "];";

# Print the bloat tables.
push @persistentScriptData, "var totals = " . genTableRowSource('"TOTAL", undefined, ', "TOTAL") . ";";
push @scriptData, "var classTables = [";
delete $sizes{"TOTAL"};
my @classes = sort(keys %sizes);
for (my $i = 0; $i <= $#classes; $i++) {
	my $c = $classes[$i];
	push @scriptData, genTableRowSource(doubleQuoteString($c).", ".$sizes{$c}.", ", $c) . ($i == $#classes ? "];" : ",");
}

generate(@scriptData, @persistentScriptData, $debug, $source, $showMode, $sortColumn);
1;


# The source of the eval'd JavaScript follows.
# Comments starting with // that are alone on a line are stripped by the Perl script.
__END__

// showMode: 0=bytes, 1=objects, 2=references
var showMode;
var modeName;
var modeNameUpper;

var sortColumn;

// Sort according to the sortColumn.  Column 0 is sorted alphabetically in ascending order.
// All other columns are sorted numerically in descending order, with column 0 used for a secondary sort.
// Undefined is always listed last.
function sortCompare(x, y) {
	if (sortColumn) {
		var xc = x[sortColumn];
		var yc = y[sortColumn];
		if (xc < yc || xc === undefined && yc !== undefined) return 1;
		if (yc < xc || yc === undefined && xc !== undefined) return -1;
	}
	
	var x0 = x[0];
	var y0 = y[0];
	if (x0 > y0 || x0 === undefined && y0 !== undefined) return 1;
	if (y0 > x0 || y0 === undefined && x0 !== undefined) return -1;
	return 0;
}


// Quote special HTML characters in the string.
function quoteHTML(s) {
	s = s.replace(/&/g, '&amp;');
	// Can't use /</g because HTML interprets '</g' as ending the script!
	s = s.replace(/\x3C/g, '&lt;');
	s = s.replace(/>/g, '&gt;');
	s = s.replace(/ /g, '&nbsp;');
	return s;
}


function writeFileTable(d) {
	d.writeln('<TABLE border=1 cellspacing=1 cellpadding=0>');
	d.writeln('<TR>\n<TH>Name</TH>\n<TH>File</TH>\n<TH>Date</TH>\n</TR>');
	for (var i = 0; i < nFiles; i++)
		d.writeln('<TR>\n<TD>'+quoteHTML(fileTags[i])+'</TD>\n<TD><TT>'+quoteHTML(fileNames[i])+'</TT></TD>\n<TD>'+quoteHTML(fileDates[i])+'</TD>\n</TR>');
	d.writeln('</TABLE>');
}


function writeReloadLink(d, column, s, rowspan) {
	d.write(rowspan == 1 ? '<TH>' : '<TH rowspan='+rowspan+'>');
	if (column != sortColumn)
		d.write('<A href="javascript:reloadSelf('+column+','+showMode+')">');
	d.write(s);
	if (column != sortColumn)
		d.write('</A>');
	d.writeln('</TH>');
}

function writeClassTableRow(d, row, base, modeName) {
	if (modeName) {
		d.writeln('<TR>\n<TH>'+modeName+'</TH>');
	} else {
		d.writeln('<TR>\n<TD><A href="javascript:showRowDetail(\''+row[0]+'\')">'+quoteHTML(row[0])+'</A></TD>');
		var v = row[1];
		d.writeln('<TD class=num>'+(v === undefined ? '' : v)+'</TD>');
	}
	for (var i = 0; i != 2; i++) {
		var c = base + i;
		for (var j = 0; j <= nFiles; j++) {
			v = row[c];
			var style = 'num';
			if (j != nFiles)
				if (v > 0) {
					style = 'pos';
					v = '+'+v;
				} else
					style = 'neg';
			d.writeln('<TD class='+style+'>'+(v === undefined ? '' : v)+'</TD>');
			c += 6;
		}
	}
	d.writeln('</TR>');
}

function writeClassTable(d) {
	var base = 2 + showMode*2;

	// Make a copy because a sort is destructive.
	var table = classTables.concat();
	table.sort(sortCompare);

	d.writeln('<TABLE border=1 cellspacing=1 cellpadding=0>');

	d.writeln('<TR>');
	writeReloadLink(d, 0, 'Class Name', 2);
	writeReloadLink(d, 1, 'Instance<BR>Size', 2);
	d.writeln('<TH colspan='+(nFiles+1)+'>'+modeNameUpper+'s allocated</TH>');
	d.writeln('<TH colspan='+(nFiles+1)+'>'+modeNameUpper+'s allocated but not freed</TH>\n</TR>');
	d.writeln('<TR>');
	for (var i = 0; i != 2; i++) {
		var c = base + i;
		for (var j = 0; j <= nFiles; j++) {
			writeReloadLink(d, c, j == nFiles ? 'Total' : quoteHTML(fileTags[j]), 1);
			c += 6;
		}
	}
	d.writeln('</TR>');

	writeClassTableRow(d, totals, base, 0);
	for (var r = 0; r < table.length; r++)
		writeClassTableRow(d, table[r], base, 0);

	d.writeln('</TABLE>');
}


var modeNames = ["byte", "object", "reference"];
var modeNamesUpper = ["Byte", "Object", "Reference"];
var styleSheet = '<STYLE type="TEXT/CSS">\n'+
	'BODY {background-color: #FFFFFF; color: #000000}\n'+
	'.num {text-align: right}\n'+
	'.pos {text-align: right; color: #CC0000}\n'+
	'.neg {text-align: right; color: #009900}\n'+
	'</STYLE>';


function showHead(d) {
	modeName = modeNames[showMode];
	modeNameUpper = modeNamesUpper[showMode];
	d.writeln('<TITLE>'+modeNameUpper+' Bloats</TITLE>');
	d.writeln(styleSheet);
}

function showBody(d) {
	d.writeln('<H1>'+modeNameUpper+' Bloats</H1>');
	writeFileTable(d);
	d.write('<FORM>');
	for (var i = 0; i != 3; i++)
		if (i != showMode) {
			var newSortColumn = sortColumn;
			if (sortColumn >= 2)
				newSortColumn = sortColumn + (i-showMode)*2;
			d.write('<INPUT type="button" value="Show '+modeNamesUpper[i]+'s" onClick="reloadSelf('+newSortColumn+','+i+')">');
		}
	d.writeln('</FORM>');
	d.writeln('<P>The numbers do not include <CODE>malloc</CODE>\'d data such as string contents.</P>');
	d.writeln('<P>Click on a column heading to sort by that column. Click on a class name to see details for that class.</P>');
	writeClassTable(d);
}


function showRowDetail(rowName) {
	var row;
	var i;

	if (rowName == "TOTAL")
		row = totals;
	else {
		for (i = 0; i < classTables.length; i++)
			if (rowName == classTables[i][0]) {
				row = classTables[i];
				break;
			}
	}
	if (row) {
		var w = window.open("", "ClassTableRowDetails");
		var d = w.document;
		d.open();
		d.writeln('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">');
		d.writeln('<HTML>\n<HEAD>\n<TITLE>'+quoteHTML(rowName)+' bloat details</TITLE>');
		d.writeln(styleSheet);
		d.writeln('</HEAD>\n\n<BODY>');
		d.writeln('<H2>'+quoteHTML(rowName)+'</H2>');
		if (row[1] !== undefined)
			d.writeln('<P>Each instance has '+row[1]+' bytes.</P>');

		d.writeln('<TABLE border=1 cellspacing=1 cellpadding=0>');
		d.writeln('<TR>\n<TH></TH>\n<TH colspan='+(nFiles+1)+'>Allocated</TH>');
		d.writeln('<TH colspan='+(nFiles+1)+'>Allocated but not freed</TH>\n</TR>');
		d.writeln('<TR>\n<TH></TH>');
		for (i = 0; i != 2; i++)
			for (var j = 0; j <= nFiles; j++)
				d.writeln('<TH>'+(j == nFiles ? 'Total' : quoteHTML(fileTags[j]))+'</TH>');
		d.writeln('</TR>');

		for (i = 0; i != 3; i++)
			writeClassTableRow(d, row, 2+i*2, modeNamesUpper[i]+'s');

		d.writeln('</TABLE>\n</BODY>\n</HTML>');
		d.close();
	}
	return undefined;
}


function stringSource(s) {
	s = s.replace(/\\/g, '\\\\');
	s = s.replace(/"/g, '\\"');
	s = s.replace(/<\//g, '<\\/');
	return '"'+s+'"';
}

function reloadSelf(n,m) {
	// Need to cache these because globals go away on document.open().
	var sa = srcArray;
	var ss = stringSource;
	var ct = classTables;
	var i;

	document.open();
	// Uncomment this and comment the document.open() line above to see the reloaded page's source.
	//var w = window.open("", "NewDoc");
	//var d = w.document;
	//var document = new Object;
	//document.write = function () {
	//	for (var i = 0; i < arguments.length; i++) {
	//		var s = arguments[i].toString();
	//		s = s.replace(/&/g, '&amp;');
	//		s = s.replace(/\x3C/g, '&lt;');
	//		s = s.replace(/>/g, '&gt;');
	//		s = s.replace(/ /g, '&nbsp;');
	//		d.write(s);
	//	}
	//};
	//document.writeln = function () {
	//	for (var i = 0; i < arguments.length; i++) {
	//		var s = arguments[i].toString();
	//		s = s.replace(/&/g, '&amp;');
	//		s = s.replace(/\x3C/g, '&lt;');
	//		s = s.replace(/>/g, '&gt;');
	//		s = s.replace(/ /g, '&nbsp;');
	//		d.write(s);
	//	}
	//	d.writeln('<BR>');
	//};

	document.writeln('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">');
	document.writeln('<HTML>\n<HEAD>\n<SCRIPT type="text/javascript">');

	// Manually copy non-persistent script data
	if (!ct.length)
		document.writeln('var classTables = [];');
	else {
		document.writeln('var classTables = [');
		for (i = 0; i < ct.length; i++) {
			var row = ct[i];
			document.write('[' + ss(row[0]));
			for (var j = 1; j < row.length; j++)
				document.write(',' + row[j]);
			document.writeln(']' + (i == ct.length-1 ? '];' : ','));
		}
	}

	document.writeln('var srcArray = [');
	for (i = 0; i < sa.length; i++) {
		document.write(ss(sa[i]));
		if (i != sa.length-1)
			document.writeln(',');
	}
	document.writeln('];');
	document.writeln('eval(srcArray.join("\\n"));');
	document.writeln('showMode = '+m+';');
	document.writeln('sortColumn = '+n+';');
	document.writeln('showHead(document);');
	document.writeln('</SCRIPT>\n</HEAD>\n\n<BODY>\n<SCRIPT type="text/javascript">showBody(document);</SCRIPT>\n</BODY>\n</HTML>');
	document.close();
	return undefined;
}