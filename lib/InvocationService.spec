module InvocationService
{
typedef structure {
	string name;
	string full_path;
	string mod_date;
} directory;

typedef structure {
	string name;
	string full_path;
	string mod_date;
	string size;
} file;

    funcdef start_session(string session_id) returns (string actual_session_id);
    funcdef valid_session(string session_id) returns (int);
    funcdef list_files(string session_id, string cwd, string d) returns (list<directory>, list<file>);
    funcdef remove_files(string session_id, string cwd, string filename) returns ();
    funcdef rename_file(string session_id, string cwd, string from, string to) returns ();
    funcdef copy(string session_id, string cwd, string from, string to) returns ();
    funcdef make_directory(string session_id, string cwd, string directory) returns ();
    funcdef remove_directory(string session_id, string cwd, string directory) returns ();
    funcdef change_directory(string session_id, string cwd, string directory) returns ();
    funcdef put_file(string session_id, string filename, string contents, string cwd) returns ();
    funcdef get_file(string session_id, string filename, string cwd) returns (string contents);
    funcdef run_pipeline(string session_id, string pipeline, list<string> input, int max_output_size, string cwd)
	returns (list<string> output, list<string> errors);
    funcdef exit_session(string session_id) returns ();

    typedef structure {
	string cmd;
	string link;
    } command_desc;

    typedef structure {
	string name;
	string title;
	list<command_desc> items;
    } command_group_desc;

    funcdef valid_commands() returns (list<command_group_desc>);

    funcdef get_tutorial_text(int step) returns(string text, int prev, int next);
};
