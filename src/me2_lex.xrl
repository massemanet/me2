Definitions.

% delimiters
DEL = (\[|\]|#{|{|}|0x\(|\(|\))

% separators
SEP = (::|:|,)

% wildcards
WILD = (@|_)

% whitespace
WS = [\n\r\t\s]

% number
DIGIT = [0-9]
SIGN = [+-]
INT = {SIGN}?({DIGIT}|[1-9]{DIGIT}+)
FLOAT = {INT}\.{DIGIT}+
EXP = E{INT}

% chars
HEX = [0-9A-Fa-f]
CHR = [^"\\]
ESC = \\[bfnrt"/\\]
HEXESC = \\u{HEX}{HEX}{HEX}{HEX}
CHAR = ({CHR}|{ESC}|{HEXESC})

% time
YEAR = [0-9][0-9][0-9][0-9]
MONTH = (0[1-9]|1[0-2])
DAY = (0[1-9]|[12][0-9]|3[0-1])
HOUR = ([01][0-9]|2[0-4])
MIN = [0-5][0-9]
SEC = ([0-5][0-9]|60)
FRAC = (\.[0-9]+)
TZ = (Z|[+-]{HOUR}:{MIN})
TUNITS = (Y|D|h|m|s|ms|us|ns|ps)

% reserved words
WORD = (true|false|null)

% comparison operators, binary
C2 = (<<|=<|==|!=)

% arithmetic operators, binary
A2 = (\+|\-|\*|\/|\%)

% boolean operators, unary/binary
B1 = !
B2 = (&&|\|\|)

% name
NAME = ([a-z][a-zA-Z0-9_]*)

% type
TYPE = ([A-Z][a-zA-Z0-9_]*)

% pattern name
PNAME = !{NAME}

% equation name
ENAME = #{NAME}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Rules.

% whitespace
{WS} :
  {token, {'ws', TokenLine, TokenChars}}.

% number
{INT} :
  {token, {'number', TokenLine, me2_lx:num_int(TokenChars)}}.

{FLOAT} :
  {token, {'number', TokenLine, me2_lx:num_float(TokenChars)}}.

{INT}{EXP} :
  {token, {'number', TokenLine, me2_lx:num_intexp(TokenChars)}}.

{FLOAT}{EXP} :
  {token, {'number', TokenLine, me2_lx:num_floatexp(TokenChars)}}.

% timestamp
{YEAR}-{MONTH}-{DAY}T{HOUR}:{MIN}:{SEC}{FRAC}?{TZ}? :
  {token, {'stamp', TokenLine, me2_lx:ts(TokenChars)}}.

% delta time
{INT} :
  {token, {'delta', TokenLine, me2_lx:delta_int(TokenChars)}}.

{FLOAT} :
  {token, {'delta', TokenLine, me2_lx:delta_float(TokenChars)}}.

{INT}{EXP} :
  {token, {'delta', TokenLine, me2_lx:delta_intexp(TokenChars)}}.

{FLOAT}{EXP} :
  {token, {'delta', TokenLine, me2_lx:delta_floatexp(TokenChars)}}.

% bitstring
0x{HEX}+(:[123])? :
  {token, {'bits', TokenLine, TokenChars}}.

% string
"{CHAR}*" :
  {token, {'string', TokenLine, me2_lx:trim(TokenChars)}}.


{NAME} :
  {token, {'aname', TokenLine, TokenChars}}.

{PNAME} :
  {token, {'pname', TokenLine, TokenChars}}.

{ENAME} :
  {token, {'ename', TokenLine, TokenChars}}.

{TYPE} :
  {token, {'type', TokenLine, TokenChars}}.

% as themselves
{WORD}|{SEP}|{DEL}|{WILD}|{A2}|{B1}|{B2}|{C2} :
  {token, {list_to_atom(TokenChars), TokenLine}}.

Erlang code.
