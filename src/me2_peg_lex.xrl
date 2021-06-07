Definitions.

WS = ([\s\t\n\r]+)

COMMENT = (//.*)

OP = /|\*|\+|\&|\!|\?

SEP = <-|\(|\)

CHAR = [a-zA_Z0-9_]

ID = {CHAR}+

RANGE = \[{CHAR}-{CHAR}\]

Rules.

{WS}|{COMMENT} :
  skip_token.

{OP} :
  {token, {'op', TokenLine, TokenChars}}.

{SEP} :
  {token, {'sep', TokenLine, TokenChars}}.

{RANGE} :
  {token, {'range', TokenLine, TokenChars}}.

{ID} :
  {token, {'id', TokenLine, TokenChars}}.

Erlang code.
