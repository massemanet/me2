Header "%% @hidden".

Nonterminals
  unit
  namespaces namespace
  scope
  expressions expression
  literal
  clause clauses
  lambda application applicand
  definition definitions
  dict member members key value
  list element elements
  function function_name params param qparam uparam
  pipe
.

Terminals
  'ws'
  'true' 'false' 'null'
  'number' 'stamp' 'delta' 'string' 'bits'
  'identifier' 'pattern_name' 'equation_name' 'type'
  '(' ')' '[' ']' '{' '}' '#{' '0x'
  ':' '::' ';' ','
  '=' '?' '|'
  'unary_op' 'binary_op'
  '_' '@'
.

Rootsymbol unit.

Nonassoc 100 '('.
Nonassoc 100 ')'.
Left      50 binary_op.
Right     30 unary_op.

%% compilation unit, aka a file

unit -> namespaces : '$1'.

%% namespaces

namespaces -> namespace               : ['$1'].
namespaces -> namespaces ws namespace : '$1' ++ ['$3'].

namespace -> identifier ws '{' ws '}' : {'$1', []}.
namespace -> identifier ws '{' definitions '}' : {'$1', '$2'}.

%% definitions

definitions -> definition                : ['$1'].
definitions -> definitions ws definition : ['$1' ++ ['$3']].

definition -> function : '$1'.

%% function definitions

function -> function_name lambda : {'$1', '$2'}.

function_name -> identifier    : '$1'.
function_name -> equation_name : '$1'.
function_name -> pattern_name  : '$1'.

%% Literals

literal -> 'true':   '$1'.
literal -> 'false':  '$1'.
literal -> 'null':   '$1'.
literal -> 'number': '$1'.
literal -> 'stamp':  '$1'.
literal -> 'delta':  '$1'.
literal -> 'bits':   '$1'.
literal -> 'string': '$1'.

%% expressions

expressions -> expression                       : ['$1'].
expressions -> expressions ws ';' ws expression : '$1' ++ ['$5'].

expression -> literal                                    : '$1'.
expression -> expression ws '=' ws expression            : {'match', '$1', '$3'}.
expression -> unary_op ws expression                     : {'$1', '$2'}.
expression -> expression ws binary_op ws expression      : {'$3', {'$1', '$5'}}.
expression -> '?' ws expression ws '{' ws clauses ws '}' : {'?', '$3', '$5'}.
expression -> application                                : '$1'.
expression -> lambda                                     : '$1'.
expression -> list                                       : '$1'.
expression -> dict                                       : '$1'.
expression -> pipe                                       : '$1'.
expression -> '_'                                        : '$1'.

%% clauses : pattern: scope

clauses -> clause            : ['$1'].
clauses -> clauses ws clause : ['$1' ++ ['$3']].

clause -> expression ws ':' ws scope : {'$1', '$5'}.

scope -> '{' ws '}'                : [].
scope -> '{' ws expressions ws '}' : '$3'.

%% lambda literals

lambda -> '(' ws ')' scope                : {'lambda', [], '$4'}.
lambda -> '(' ws params ws ')' scope : {'lambda', '$3', '$6'}.

%% Formal parameters. can be unqualified (`a') or qualified (`a::A')

params -> param : ['$1'].
params -> params ws ',' ws param : '$1' ++ ['$5'].

param -> uparam : '$1'.
param -> qparam : '$1'.
param -> '@'    : '$1'.

qparam -> identifier '::' type : {'$1', '$3'}.
uparam -> identifier           : {'$1', 'any'}.

%% application

application -> applicand '(' ws ')'             : {'$1', []}.
application -> applicand '(' ws elements ws ')' : {'$1', '$4'}.

applicand -> lambda     : '$1'.
applicand -> identifier : '$1'.
applicand -> '0x'       : '$1'.

%% ordered sets, aka list, aka array

list -> '[' ws']'              : {'list', []}.
list -> '[' ws elements ws ']' : {'list', '$2'}.

elements -> element                    : ['$1'].
elements -> elements ws ',' ws element : ['$1' ++ ['$5']].

element -> expression : '$1'.

%% dicts, aka alist, aka map

dict -> '#{' ws '}'      : {'dict', []}.
dict -> '#{' members '}' : {'dict', '$2'}.

members -> member                   : ['$1'].
members -> members ws ',' ws member : '$1' ++ ['$5'].

member -> key ws ':' ws value : {'$1', '$5'}.

key -> expression : '$1'.

value -> expression : '$1'.

%% pipe; f() | g(@) | h(x, @) | ...

pipe -> application '|' application : ['$1', '$3'].
pipe -> pipe '|' application        : '$1' ++ ['$3'].
