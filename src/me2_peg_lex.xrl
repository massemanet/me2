Definitions.

WS = ([\s\t\n\r]+)

COMMENT = (//.*)

OP = /|\*|\+|\&|\!|\?

SEP = <-|\(|\)|;

CHAR = [a-zA-Z0-9_]

ID = {CHAR}+

RANGE = \[{CHAR}-{CHAR}\]

Rules.

{WS}|{COMMENT} :
  skip_token.

{OP}|{SEP} :
  {token, {list_to_atom(TokenChars), TokenLine}}.

'{CHAR}+' :
  {token, {'string', TokenLine, trim(TokenChars)}}.

{RANGE} :
  {token, {'range', TokenLine, TokenChars}}.

{ID} :
  {token, {'id', TokenLine, TokenChars}}.

Erlang code.

trim(S) ->
    lists:reverse(tl(lists:reverse(tl(S)))).
