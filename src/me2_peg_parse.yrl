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
rules -> rule ';' rules : ['$1'|'$2'].

rule -> 'id' '<-' clauses : {rule, element(3, '$1'), '$3'}.

clauses -> seq : ['$1'].
clauses -> seq '/' clauses : ['$1'|'$3'].

seq -> exp : ['$1'].
seq -> exp seq : ['$1'|'$2'].

exp -> rexp '+' : {'one_or_more', '$1'}.
exp -> rexp '*' : {'zero_or_more', '$1'}.
exp -> rexp '?' : {'optional', '$1'}.
exp -> '!' rexp : {'not_followed_by', '$2'}.
exp -> '&' rexp : {'followed_by', '$2'}.
exp -> rexp     : '$1'.

rexp -> '(' clauses ')' : '$1'.
rexp -> term : '$1'.

term -> '(' ')' : '()'.
term -> 'id'    : '$1'.
term -> 'range' : '$1'.
term -> 'string' : '$1'.
