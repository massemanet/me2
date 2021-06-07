Header "%% @hidden".

Nonterminals
 rules rule
 subclauses subclause
 term.

Terminals
  '<-' '(' ')'
  '/' '*' '+' '?' '!' '&'
 'id'.

Rootsymbol rules.

rules -> rule rules : ['$1'|'$2'].

rule -> 'id' '<-' subclauses : {'$1', '$3'}.

subclauses -> subclause : ['$1'].
subclauses -> subclause '/' subclauses : ['$1'|'$2'].
subclauses -> '(' subclauses ')' : '$2'.

subclause -> term : ['$1'].
subclause -> term subclause : ['$1'|'$2'].

term -> '(' ')' : empty.
term -> 'id' : '$1'.
term -> term '+' : {'plus', '$1'}.
term -> term '*' : {'star', '$1'}.
term -> term '?' : {'q', '$1'}.
term -> '!' term : {'not', '$2'}.
term -> '&' term : {'and', '$2'}.
