module AskKB
{

typedef list<string> head;
typedef list<string> row;
typedef list<row> rows;
typedef structure {
	head header;
	rows data;
	string fasta;
	string error;
} answer;

    typedef string query;
    typedef string session_id;
    typedef string cwd;
    typedef string type;

    funcdef askKB (session_id, cwd, query) returns(type, answer);
    funcdef save (session_id, cwd, string filename) returns();
};
