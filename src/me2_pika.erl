-module(me2_pika).

-export(
   [file/1, file/2,
    string/1, string/2]).

file(File) ->
    file(File, #{}).

file(File, Opts) ->
    try string(binary_to_list(lift(file:read_file(File))), Opts)
    catch throw:Error -> {error, Error}
    end.

string(String) ->
    string(String, #{}).

string(String, Opts) ->
    try out(lex(String), Opts)
    catch throw:Error -> {error, Error}
    end.

lift({ok, Result}) -> Result;
lift({error, Error}) -> throw(Error).

out(Term, #{out := File}) -> file:write_file(File, format(Term));
out(Term, _) -> Term.

format(Term) ->
    io_lib:format("~p~n", [Term]).

lex(String) ->
    case me2_peg_lex:string(String) of
        {ok, Tokens, _} -> parse(Tokens);
        {error, {_, _, Error}, Line} -> throw({Line, Error})
    end.

parse(Tokens) ->
    case me2_peg_parse:parse(Tokens) of
        {ok, Parse} -> generate(Parse);
        {error, {Line, _, Err}} -> throw({Line, lists:flatten(Err)})
    end.

generate(Parse) ->
    Parse.
