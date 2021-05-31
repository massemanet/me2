-module(me2_lx).

-export([trim/1]).

trim(Str) ->
    lists:reverse(tl(lists:reverse(tl(Str)))).
