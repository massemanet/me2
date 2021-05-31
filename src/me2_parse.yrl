Header "%% @hidden".

Nonterminals
  unit
  namespaces namespace
  scope
  expressions expression
  literal
  unary_op binary_op
  clause clauses
  name lambda application
  .

Terminals
  'aname'
  '(' ')' '[' ']' '{' '}'
  '->' 'when' ':' ';' '#' ',' '=' ':=' '=>' '#{' '/' '|' '++'
  'pid' 'ref' 'port'
  'variable' 'bin' 'int' 'atom' 'string'
  'comparison_op' 'arithmetic_op' 'boolean_op1' 'boolean_op2'
  'type_test1' 'type_isrec' 'bif0' 'bif1' 'bif2'.

Rootsymbol unit.

Nonassoc 100 '('.
Nonassoc 100 ')'.
Left      50 arithmetic_op.
Left      40 comparison_op.
Right     30 boolean_op1.
Left      20 boolean_op2.
Left      10 '++'.

unit -> namespaces : '$1'.

namespaces -> namespace               : ['$1'].
namespaces -> namespaces ws namespace : '$1' ++ ['$3'].

namespace -> name ws '{' ws '}' : {'$1', []}.
namespace -> name ws '{' definitions '}' : {'$1', '$2'}.

definitions -> definition                : ['$1'].
definitions -> definitions ws definition : ['$1' ++ ['$3']].

definition -> function : '$1'.
definition -> equation : '$1'.
definition -> pattern  : '$1'.

function -> fname lambda : {'$1', '$2'}.

equation -> ename '(' ws ')' ws ebody : {'$1', [], '$6'}.
equation -> ename '(' ws uparams ws ')' ws ebody : {'$1', '$4', '$8'}.

pattern -> pname '(' ws ')' ws pbody : {'$1', [], '$6'}.
pattern -> pname '(' ws params ws ')' ws pbody : {'$1', '$4', '$8'}.
pattern -> pbody : '$1'.

pbody -> pelem : '$1'.
pbody -> '[' ws ']' : [].
pbody -> '[' ws pelems ws ']' : '$3'.
pbody -> '#{' ws '}' : [].
pbody -> '#{' ws pmembers ws '}' : '$3'.

pelems -> pelem : ['$1'].
pelems -> pelems ws ',' ws  pelem : '$1' ++ ['$5'].

pmembers -> pmember : ['$1'].
pmembers -> pmembers ws ',' ws  pmember : '$1' ++ ['$5'].

pmember -> pelem ws ':' ws pelem : {'$1', '$5'}.

pelem -> '_'     : '_'.
pelem -> name    : '$1'.
pelem -> literal : '$1'.

params -> param : ['$1'].
params -> params ws ',' ws param : '$1' ++ ['$5'].

uparams -> uparam : ['$1'].
uparams -> uparams ws ',' ws uparam : '$1' ++ ['$5'].

param -> uparam : '$1'.
param -> qparam : '$1'.

qparam -> aname '::' type : {'$1', '$3'}.
uparam -> aname           : {'$1', 'any'}.

literal -> 'true':   '$1'.
literal -> 'false':  '$1'.
literal -> 'null':   '$1'.
literal -> 'number': '$1'.
literal -> 'stamp':  '$1'.
literal -> 'delta':  '$1'.
literal -> 'bits':   '$1'.
literal -> 'string': '$1'.

clauses -> clause            : ['$1'].
clauses -> clauses ws clause : ['$1' ++ ['$3']].

clause -> pattern ws ':' ws scope : {'$1', '$5'}.

lambda -> '(' ws ')' scope             : {'lambda', [], '$4'}.
lambda -> '(' ws patterns ws ')' scope : {'lambda', '$3', '$6'}.

scope -> '{' ws '}'                : [].
scope -> '{' ws expressions ws '}' : '$3'.

expressions -> expression                       : ['$1'].
expressions -> espressions ws ';' ws expression : '$1' ++ ['$5'].

expression -> literal                                    : '$1'.
expression -> pattern ws '=' ws expression               :             : {'match', '$1', '$3'}.
expression -> unary_op ws expression                     : {'$1', '$2'}.
expression -> expression ws binary_op ws expression      : {'$3', {'$1', '$5'}}.
expression -> '?' ws expression ws '{' ws clauses ws '}' : {'?', '$3', '$5'}.
expression -> application                                : '$1'.
expression -> lambda                                     : '$1'.
expression -> list                                       : '$1'.
expression -> dict                                       : '$1'.

application -> applicand '(' ws ')'             : {'$1', []}.
application -> applicand '(' ws elements ws ')' : {'$1', '$4'}.

applicand -> lambda : '$1'.
applicand -> fname  : '$1'.
applicand -> name   : '$1'.

list -> '[' ws']'              : {'list', []}.
list -> '[' ws elements ws ']' : {'list', '$2'}.

elements -> element                    : ['$1'].
elements -> elements ws ',' ws element : ['$1' ++ ['$5']].

element -> expression : '$1'.

dict -> '#{' ws '}'      : {'dict', []},
dict -> '#{' members '}' : {'dict', '$2'},

members -> member                   : ['$1'].
members -> members ws ',' ws member : '$1' ++ ['$5'].

member -> key ws ':' ws value : {'$1', '$5'}.

key -> expression : '$1'.

value -> expression : '$1'.
