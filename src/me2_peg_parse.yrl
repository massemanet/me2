Header "%% @hidden".

Nonterminals
 rules rule
 clauses
 seq exp rexp
 term.

Terminals
  '<-' '(' ')' ';'
 '/'
  '*' '+' '?' '!' '&'
 'id' 'string' 'range'.

Rootsymbol rules.

rules -> rule ';' : ['$1'].
rules -> rule ';' rules : ['$1'|'$3'].

rule -> 'id' '<-' clauses : {rule, val('$1'), '$3'}.

clauses -> seq             : {clauses, ['$1']}.
clauses -> seq '/' clauses : {clauses, prepend('$1', '$3')}.

seq -> exp     : {seq, ['$1']}.
seq -> exp seq : {seq, prepend('$1', '$2')}.

exp -> rexp '+' : {'one_or_more', '$1'}.
exp -> rexp '*' : {'zero_or_more', '$1'}.
exp -> rexp '?' : {'optional', '$1'}.
exp -> '!' rexp : {'not_followed_by', '$2'}.
exp -> '&' rexp : {'followed_by', '$2'}.
exp -> rexp     : '$1'.

rexp -> '(' clauses ')' : '$2'.
rexp -> term            : '$1'.

term -> '(' ')'  : '()'.
term -> 'id'     : '$1'.
term -> 'range'  : '$1'.
term -> 'string' : '$1'.

Erlang code.

val({_, _, E}) -> E.

prepend(E, {_, Es}) -> [E|Es].
