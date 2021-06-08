-module(me2_peg).

-export(
   [file/1,
    string/1]).

file(File) ->
    try string(lift(file:read_file(File)))
    catch throw:Error -> {error, Error}
    end.

string(String) ->
    try lex(String)
    catch throw:Error -> {error, Error}
    end.

lift({ok, Result}) -> Result;
lift({error, Error}) -> throw(Error).

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
