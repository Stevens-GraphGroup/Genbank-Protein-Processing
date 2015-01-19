#!/bin/bash
# Convert Genbank flat files to fasta protein files.
# Use a temporary directory for processing.
# ./genbankToFasta.bash "/data/NCBI-GENBANK-ORIG/ftp.ncbi.nlm.nih.gov/genbank" "/tmp/GenBankParsing" "/Data/dhutchis/processGenBank/dirStore" "/Data/dhutchis/BioTools/GenBankParser/GenBankParser.jar"
set -u
set -e
USAGE="""$0 DirSource DirProcess DirStore GenBankParserJar"""
if [[ $# -ne 4 ]]; then
    echo "Usage: $USAGE"
    exit 1;
fi

DirSource="$1"
DirProcess="$2"
DirStore="$3"
GenBankParserJar="$4"
FileNoProteins="$DirStore/NoProteinsFile.txt"
IgnoreFile="$DirStore/IgnoreFile.txt"
IgnoreFileTemp="$DirProcess/IgnoreFileTemp.txt"
echo "DirSource : $DirSource" 
echo "DirProcess: $DirProcess" 
echo "DirStore  : $DirStore" 
echo "GenBankParserJar : $GenBankParserJar"
echo "FileNoProteins   : $FileNoProteins"
echo "IgnoreFile       : $IgnoreFile"
if [ ! -d "$DirSource" ] || [ ! -r "$GenBankParserJar" ]; then
    echo "Usage: $USAGE"
    exit 1;
fi

if [ ! -d "$DirProcess" ]; then
    mkdir -p "$DirProcess"
else
    ls -1 "$DirProcess" | while read file; do
	rm "$DirProcess/$file"
    done
fi
if [ ! -d "$DirStore" ]; then
    mkdir -p "$DirStore"
fi
touch "$FileNoProteins"
touch "$IgnoreFile"
echo "BEGIN $(date '+%Y-%m-%d_%H:%M.%S')"

NumFilesTotal=$(ls -1 "$DirSource" | grep -E "^gb[[:lower:]]{3}[[:digit:]]+\.seq" | wc -l)
NumFilesCount=0
ls -1 "$DirSource" | grep -E "^gb[[:lower:]]{3}[[:digit:]]+\.seq" | while read file; do
    filenogz="${file%.gz}" # removes /gz if present, otherwise same as $file
    fileoutput="${filenogz%seq}_aas"
    printf "[$(date '+%d_%H:%M.%S') %04d/%04d] %-15s: " "$((++NumFilesCount))" "$NumFilesTotal" "$file"
    if [ -a "$DirStore/$fileoutput" ] || grep -q "$filenogz" "$FileNoProteins"; then
	if [ -a "$DirStore/$fileoutput" ]; then
	    echo "Skipping (already exists)"
	else
	    echo "Skipping (known no-proteins)"
	fi
	continue
    fi
    if [ "$file" != "$filenogz" ]; then
	gunzip -d -c "$DirSource/$file" > "$DirProcess/$filenogz"
    else
	ln -s "$DirSource/$file" "$DirProcess/$filenogz"
    fi
    java -jar "$GenBankParserJar" "$DirProcess/$filenogz" | cut -d \' -f 2 | sort | uniq > "$IgnoreFileTemp" # stores output ._aas in $DirProcess
    comm -23 "$IgnoreFileTemp" "$IgnoreFile" | sort -m "$IgnoreFile" - > "$IgnoreFileTemp.2"
    mv "$IgnoreFileTemp.2" "$IgnoreFile"
    
    if [ -a "$DirProcess/$fileoutput" ]; then
	mv "$DirProcess/$fileoutput" "$DirStore"
	echo "OK"
    else
	echo "$filenogz" >> "$FileNoProteins"
	echo "No Proteins"
    fi
    rm "$DirProcess/$filenogz"
done
