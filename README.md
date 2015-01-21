# Genbank-Protein-Processing

`GenBankParser/` contains a tweaked part from Darrell Ricke's [BioTools](https://github.com/doricke/BioTools/tree/master/GenBankParser).
Thanks Darrell! The tweaks make the parser extract only protein sequences, along with their annotations.
It operates on [Genbank flat files](ftp://ftp.ncbi.nlm.nih.gov/genbank/).

`genbankToFasta.bash` will call the GenBankParser in a loop for all the files in a directory.

`PutHeaderAndSeqInDB.m` ingests annotated protein fasta data into an Accumulo database.
`PutHeaderAndSeqInDB_AllFiles.m` will ingests an entire directory.



### Snippets


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


#### Accumulo DB Table Snippets

    root@instance> tables
    Tseq
    TseqDegT
    TseqFieldT
    TseqInfo
    TseqRaw
    TseqRawNumBases
    TseqT
    root@instance> scan -t Tseq
    BAA22448.1 :Exons|89-406 []    1
    BAA22448.1 :codon_start|1 []    1
    BAA22448.1 :date|2006-12-02 []    1
    BAA22448.1 :db_xref|GI:2446889 []    1
    BAA22448.1 :def|Synechococcus elongatus PCC 6301 genes for ribosomal proteins, complete cds. []    1
    BAA22448.1 :molecule|DNA []    1
    BAA22448.1 :note|unnamed protein product []    1
    BAA22448.1 :organism|Synechococcus elongatus PCC 6301 []    1
    BAA22448.1 :strain|PCC 6301 []    1
    BAA22448.1 :taxon_id|269084 []    1
    BAA22448.1 :taxonomy|Bacteria; Cyanobacteria; Oscillatoriophycideae; Chroococcales; Synechococcus. []    1
    root@instance> scan -t TseqT
    Exons|89-406 :BAA22448.1 []    1
    codon_start|1 :BAA22448.1 []    1
    date|2006-12-02 :BAA22448.1 []    1
    db_xref|GI:2446889 :BAA22448.1 []    1
    def|Synechococcus elongatus PCC 6301 genes for ribosomal proteins, complete cds. :BAA22448.1 []    1
    molecule|DNA :BAA22448.1 []    1
    note|unnamed protein product :BAA22448.1 []    1
    organism|Synechococcus elongatus PCC 6301 :BAA22448.1 []    1
    strain|PCC 6301 :BAA22448.1 []    1
    taxon_id|269084 :BAA22448.1 []    1
    taxonomy|Bacteria; Cyanobacteria; Oscillatoriophycideae; Chroococcales; Synechococcus. :BAA22448.1 []    1
    root@instance> scan -t TseqDegT
    Exons|89-406 :deg []    1
    codon_start|1 :deg []    1
    date|2006-12-02 :deg []    1
    db_xref|GI:2446889 :deg []    1
    def|Synechococcus elongatus PCC 6301 genes for ribosomal proteins, complete cds. :deg []    1
    molecule|DNA :deg []    1
    note|unnamed protein product :deg []    1
    organism|Synechococcus elongatus PCC 6301 :deg []    1
    strain|PCC 6301 :deg []    1
    taxon_id|269084 :deg []    1
    taxonomy|Bacteria; Cyanobacteria; Oscillatoriophycideae; Chroococcales; Synechococcus. :deg []    1
    root@instance> scan -t TseqFieldT
    Exons :deg [] 5
    codon_start :deg []    5
    date :deg []    5
    db_xref :deg []    5
    def :deg []    5
    ec_number :deg []    1
    gene :deg []    3
    molecule :deg []    5
    note :deg []    2
    organism :deg []    5
    product :deg []    3
    strain :deg []    5
    taxon_id :deg []    5
    taxonomy :deg []    5
    root@instance> scan -t TseqRaw
    BAA22448.1 :seq []    MLARISELTKIGTTIFIVAIDQVAEPNSWGSSQLVLLAKIAGALKAIPPNPVCTSRHRQAASVSPFRSAIVGTLLQLEAIKNLLTVSVDTIQQNGVLFIFVALLR
    root@instance> scan -t TseqRawNumBases
    BAA22448.1 :num []    105
    root@instance> scan -t TseqInfo
    gbbct1._aas :statNumBasePut|000000105 []    1
    gbbct1._aas :statNumMetaPut|000000011 []    1
    gbbct1._aas :statNumSeqPut|000000001 []    1
    gbbct1._aas :statTimePut|0000001.7 []    1




