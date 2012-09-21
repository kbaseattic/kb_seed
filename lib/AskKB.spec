module AskKB
{
    typedef string query;
    typedef string answer;
    typedef string session_id;
    typedef string cwd;

    funcdef askKB (session_id, cwd, query) returns(answer);
};
