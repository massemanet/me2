-module(me2).

-export(
   [file/1,
    string/1]).

file(File) ->
    try string(lift(file:read_file(File)))
    catch throw:Error -> {error, Error}
    end.

string(String) ->
    try compile(String)
    catch throw:Error -> {error, Error}
    end.

lift({ok, Result}) -> Result;
lift({error, Error}) -> throw(Error).

compile(String) ->
    me2_pika:parse(String).
