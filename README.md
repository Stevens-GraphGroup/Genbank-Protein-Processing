# Genbank-Protein-Processing

`GenBankParser/` contains a tweaked part from Darrell Ricke's [BioTools](https://github.com/doricke/BioTools/tree/master/GenBankParser).
Thanks Darrell! The tweaks make the parser extract only protein sequences, along with their annotations.
It operates on [Genbank flat files](ftp://ftp.ncbi.nlm.nih.gov/genbank/).

`genbankToFasta.bash` will call the GenBankParser in a loop for all the files in a directory.

`PutHeaderAndSeqInDB.m` ingests annotated protein fasta data into an Accumulo database.
`PutHeaderAndSeqInDB_AllFiles.m` will ingests an entire directory.



### File samples


#### Snippet of `gbbct1.seq`

    LOCUS       AB000111               14024 bp    DNA     linear   BCT 02-DEC-2006
    DEFINITION  Synechococcus elongatus PCC 6301 genes for ribosomal proteins,
                complete cds.
    ACCESSION   AB000111
    VERSION     AB000111.1  GI:2446888
    KEYWORDS    .
    SOURCE      Synechococcus elongatus PCC 6301 (Synechococcus leopoliensis SAG
                1402-1)
      ORGANISM  Synechococcus elongatus PCC 6301
                Bacteria; Cyanobacteria; Oscillatoriophycideae; Chroococcales;
                Synechococcus.
    REFERENCE   1
      AUTHORS   Sugita,M., Sugishita,H., Fujishiro,T., Tsuboi,M., Sugita,C.,
                Endo,T. and Sugiura,M.
      TITLE     Organization of a large gene cluster encoding ribosomal proteins in
                the cyanobacterium Synechococcus sp. strain PCC 6301: comparison of
                gene clusters among cyanobacteria, eubacteria and chloroplast
                genomes
      JOURNAL   Gene 195 (1), 73-79 (1997)
       PUBMED   9300823
    REFERENCE   2  (bases 1 to 14024)
      AUTHORS   Sugita,M.
      TITLE     Direct Submission
      JOURNAL   Submitted (26-DEC-1996) Mamoru Sugita, Nagoya University, Center
                for Gene Research; Furo-cho, Nagoya, Aichi 464-01, Japan
                (E-mail:h44979a@nucc.cc.nagoya-u.ac.jp, Tel:81-52-789-3087,
                Fax:81-52-789-3081)
    FEATURES             Location/Qualifiers
         source          1..14024
                         /organism="Synechococcus elongatus PCC 6301"
                         /mol_type="genomic DNA"
                         /strain="PCC 6301"
                         /db_xref="taxon:269084"
                         /clone="lambda D5"
                         /clone_lib="lambda dash II library"
         CDS             89..406
                         /note="unnamed protein product"
                         /codon_start=1
                         /transl_table=11
                         /protein_id="BAA22448.1"
                         /db_xref="GI:2446889"
                         /translation="MLARISELTKIGTTIFIVAIDQVAEPNSWGSSQLVLLAKIAGAL
                         KAIPPNPVCTSRHRQAASVSPFRSAIVGTLLQLEAIKNLLTVSVDTIQQNGVLFIFVA
                         LLR"

...

#### Snippet of `gbbct1._aas`

    >BAA22448.1 /organism="Synechococcus elongatus PCC 6301" /molecule="DNA" /date="02-DEC-2006" Exons[89-406] /codon_start=1 /db_xref="GI:2446889" /protein_id="BAA22448.1" /note="unnamed protein product" /taxon_id="269084"  /taxonomy="Bacteria; Cyanobacteria; Oscillatoriophycideae; Chroococcales; Synechococcus." /strain="PCC 6301" /def="Synechococcus elongatus PCC 6301 genes for ribosomal proteins, complete cds."
    MLARISELTKIGTTIFIVAIDQVAEPNSWGSSQLVLLAKIAGALKAIPPNPVCTSRHRQA
    ASVSPFRSAIVGTLLQLEAIKNLLTVSVDTIQQNGVLFIFVALLR

...




