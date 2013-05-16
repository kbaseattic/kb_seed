module KmerEval {

typedef string comment;
typedef string sequence;
typedef string id;
typedef string function;
typedef string strand;
typedef string contig;
typedef int strand;
typedef int length;


typedef tuple<id,comment,sequence> seq_triple;
typedef list<seq_triple> seq_set;
typedef tuple<string genus,string species> genus_species;
typedef tuple<genus_species,int genetic_code,string estimated_taxonomy,seq_set> genome_tuple;
typedef list<genome_tuple> genome_tuples;
typedef list<genus_species> otu_set;
typedef tuple<int count,otu_set> otu_set_counts;
typedef list<otu_set_counts> otu_data;
typedef tuple<int start_of_first_hit,int end_of_last_hit,int number_hits,function> call;
typedef list<call> calls;
typedef tuple<strand,int offset_of_frame,calls> frame;
typedef list<frame> frames;
typedef tuple<length,frames,otu_data> contig_data;

funcdef call_dna_with_kmers(seq_set) returns (mapping<contig,contig_data>);
funcdef call_prot_with_kmers(seq_set) returns (mapping<id,tuple<calls,otu_data>>);
funcdef check_contig_set(seq_set) returns (tuple<int estimate,comment,genome_tuples placed,seq_set unplaced>);
};

