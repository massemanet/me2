-module(me2_peg).
-export([parse/1,file/1]).
-define(p_anything,true).
-define(p_charclass,true).
-define(p_choose,true).
-define(p_not,true).
-define(p_one_or_more,true).
-define(p_optional,true).
-define(p_scan,true).
-define(p_seq,true).
-define(p_string,true).
-define(p_zero_or_more,true).



-spec file(file:name()) -> any().
file(Filename) -> case file:read_file(Filename) of {ok,Bin} -> parse(Bin); Err -> Err end.

-spec parse(binary() | list()) -> any().
parse(List) when is_list(List) -> parse(unicode:characters_to_binary(List));
parse(Input) when is_binary(Input) ->
  _ = setup_memo(),
  Result = case 'unit'(Input,{{line,1},{column,1}}) of
             {AST, <<>>, _Index} -> AST;
             Any -> Any
           end,
  release_memo(), Result.

-spec 'unit'(input(), index()) -> parse_result().
'unit'(Input, Index) ->
  p(Input, Index, 'unit', fun(I,D) -> (p_one_or_more(fun 'namespace'/2))(I,D) end, fun(Node, _Idx) ->me2_parse:unit(Node) end).

-spec 'namespace'(input(), index()) -> parse_result().
'namespace'(Input, Index) ->
  p(Input, Index, 'namespace', fun(I,D) -> (p_seq([fun 'identifier'/2, p_optional(fun 'ws'/2), fun 'scope'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:namespace(Node) end).

-spec 'scope'(input(), index()) -> parse_result().
'scope'(Input, Index) ->
  p(Input, Index, 'scope', fun(I,D) -> (p_seq([p_string(<<"{">>), p_optional(fun 'ws'/2), fun 'definitions'/2, p_string(<<"}">>)]))(I,D) end, fun(Node, _Idx) ->me2_parse:scope(Node) end).

-spec 'definitions'(input(), index()) -> parse_result().
'definitions'(Input, Index) ->
  p(Input, Index, 'definitions', fun(I,D) -> (p_one_or_more(p_seq([p_choose([fun 'pattern_def'/2, fun 'equation_def'/2, fun 'function_def'/2]), p_optional(fun 'ws'/2)])))(I,D) end, fun(Node, _Idx) ->me2_parse:definitions(Node) end).

-spec 'pattern_def'(input(), index()) -> parse_result().
'pattern_def'(Input, Index) ->
  p(Input, Index, 'pattern_def', fun(I,D) -> (p_seq([fun 'pattern_id'/2, p_string(<<"(">>), p_optional(fun 'ws'/2), fun 'identifiers'/2, p_string(<<")">>), p_optional(fun 'ws'/2), fun 'pattern_body'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_def(Node) end).

-spec 'equation_def'(input(), index()) -> parse_result().
'equation_def'(Input, Index) ->
  p(Input, Index, 'equation_def', fun(I,D) -> (p_seq([p_string(<<"#">>), fun 'identifier'/2, p_string(<<"(">>), p_optional(fun 'ws'/2), fun 'identifiers'/2, p_string(<<")">>), p_optional(fun 'ws'/2), fun 'equation_body'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:equation_def(Node) end).

-spec 'function_def'(input(), index()) -> parse_result().
'function_def'(Input, Index) ->
  p(Input, Index, 'function_def', fun(I,D) -> (p_seq([fun 'identifier'/2, fun 'lambda_def'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:function_def(Node) end).

-spec 'lambda_def'(input(), index()) -> parse_result().
'lambda_def'(Input, Index) ->
  p(Input, Index, 'lambda_def', fun(I,D) -> (p_seq([p_string(<<"(">>), fun 'parameters'/2, p_string(<<")">>), p_optional(fun 'ws'/2), fun 'lambda_body'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:lambda_def(Node) end).

-spec 'lambda_body'(input(), index()) -> parse_result().
'lambda_body'(Input, Index) ->
  p(Input, Index, 'lambda_body', fun(I,D) -> (p_seq([p_string(<<"{">>), p_optional(fun 'ws'/2), fun 'expressions'/2, p_string(<<"}">>)]))(I,D) end, fun(Node, _Idx) ->me2_parse:lambda_body(Node) end).

-spec 'equation_body'(input(), index()) -> parse_result().
'equation_body'(Input, Index) ->
  p(Input, Index, 'equation_body', fun(I,D) -> (p_seq([p_string(<<"{">>), p_optional(fun 'ws'/2), fun 'math_expr'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<";">>), p_optional(fun 'ws'/2), fun 'math_expr'/2])), p_optional(fun 'ws'/2), p_optional(p_seq([p_string(<<";">>), p_optional(fun 'ws'/2)])), p_string(<<"}">>)]))(I,D) end, fun(Node, _Idx) ->me2_parse:equation_body(Node) end).

-spec 'math_expr'(input(), index()) -> parse_result().
'math_expr'(Input, Index) ->
  p(Input, Index, 'math_expr', fun(I,D) -> (p_choose([p_seq([p_string(<<"(">>), fun 'math_expr'/2, p_string(<<")">>)]), p_seq([fun 'math_expr'/2, fun 'math_op'/2, fun 'math_expr'/2]), fun 'identifier'/2, fun 'number'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:math_expr(Node) end).

-spec 'expressions'(input(), index()) -> parse_result().
'expressions'(Input, Index) ->
  p(Input, Index, 'expressions', fun(I,D) -> (p_seq([fun 'expression'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<";">>), p_optional(fun 'ws'/2), fun 'expression'/2])), p_optional(fun 'ws'/2), p_optional(p_seq([p_string(<<";">>), p_optional(fun 'ws'/2)]))]))(I,D) end, fun(Node, _Idx) ->me2_parse:expressions(Node) end).

-spec 'expression'(input(), index()) -> parse_result().
'expression'(Input, Index) ->
  p(Input, Index, 'expression', fun(I,D) -> (p_seq([p_choose([fun 'literal'/2, fun 'match'/2, fun 'unary'/2, fun 'switch'/2, fun 'application'/2, fun 'lambda_def'/2, fun 'list'/2, fun 'dict'/2, fun 'pipe'/2]), fun 'maybe_binary'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:expression(Node) end).

-spec 'match'(input(), index()) -> parse_result().
'match'(Input, Index) ->
  p(Input, Index, 'match', fun(I,D) -> (p_seq([fun 'pattern'/2, p_optional(fun 'ws'/2), p_string(<<"=">>), p_optional(fun 'ws'/2), fun 'expression'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:match(Node) end).

-spec 'unary'(input(), index()) -> parse_result().
'unary'(Input, Index) ->
  p(Input, Index, 'unary', fun(I,D) -> (p_seq([fun 'unary_op'/2, p_optional(fun 'ws'/2), fun 'expression'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:unary(Node) end).

-spec 'maybe_binary'(input(), index()) -> parse_result().
'maybe_binary'(Input, Index) ->
  p(Input, Index, 'maybe_binary', fun(I,D) -> (p_choose([p_seq([p_optional(fun 'ws'/2), fun 'binary_op'/2, p_optional(fun 'ws'/2), fun 'expression'/2]), p_string(<<"">>)]))(I,D) end, fun(Node, _Idx) ->me2_parse:binary(Node) end).

-spec 'switch'(input(), index()) -> parse_result().
'switch'(Input, Index) ->
  p(Input, Index, 'switch', fun(I,D) -> (p_seq([p_string(<<"?">>), p_optional(fun 'ws'/2), fun 'expression'/2, p_optional(fun 'ws'/2), fun 'clauses'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:switch(Node) end).

-spec 'application'(input(), index()) -> parse_result().
'application'(Input, Index) ->
  p(Input, Index, 'application', fun(I,D) -> (p_choose([p_seq([fun 'lambda_def'/2, p_optional(fun 'ws'/2), fun 'arglist'/2]), p_seq([fun 'identifier'/2, p_optional(fun 'ws'/2), fun 'arglist'/2])]))(I,D) end, fun(Node, _Idx) ->me2_parse:application(Node) end).

-spec 'list'(input(), index()) -> parse_result().
'list'(Input, Index) ->
  p(Input, Index, 'list', fun(I,D) -> (p_choose([p_seq([p_string(<<"[">>), fun 'expression_list'/2, p_string(<<"]">>)]), p_seq([p_string(<<"[">>), p_optional(fun 'ws'/2), p_string(<<"]">>)])]))(I,D) end, fun(Node, _Idx) ->me2_parse:list(Node) end).

-spec 'dict'(input(), index()) -> parse_result().
'dict'(Input, Index) ->
  p(Input, Index, 'dict', fun(I,D) -> (p_choose([p_seq([p_string(<<"#{">>), fun 'pairs'/2, p_string(<<"}">>)]), p_seq([p_string(<<"#{">>), p_optional(fun 'ws'/2), p_string(<<"}">>)])]))(I,D) end, fun(Node, _Idx) ->me2_parse:dict(Node) end).

-spec 'pipe'(input(), index()) -> parse_result().
'pipe'(Input, Index) ->
  p(Input, Index, 'pipe', fun(I,D) -> (p_seq([fun 'pipe_elem'/2, p_optional(fun 'ws'/2), p_string(<<"|">>), p_optional(fun 'ws'/2), fun 'pipe_elem'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<"|">>), p_optional(fun 'ws'/2), fun 'pipe_elem'/2]))]))(I,D) end, fun(Node, _Idx) ->me2_parse:pipe(Node) end).

-spec 'pipe_elem'(input(), index()) -> parse_result().
'pipe_elem'(Input, Index) ->
  p(Input, Index, 'pipe_elem', fun(I,D) -> (p_choose([p_seq([fun 'lambda_def'/2, p_optional(fun 'ws'/2), fun 'pipe_arglist'/2]), p_seq([fun 'identifier'/2, p_optional(fun 'ws'/2), fun 'pipe_arglist'/2])]))(I,D) end, fun(Node, _Idx) ->me2_parse:application(Node) end).

-spec 'pipe_arglist'(input(), index()) -> parse_result().
'pipe_arglist'(Input, Index) ->
  p(Input, Index, 'pipe_arglist', fun(I,D) -> (p_choose([p_seq([p_string(<<"(">>), p_optional(fun 'ws'/2), fun 'pipe_expression_list'/2, p_optional(fun 'ws'/2), p_string(<<")">>)]), p_seq([p_string(<<"(">>), p_optional(fun 'ws'/2), p_string(<<")">>)])]))(I,D) end, fun(Node, _Idx) ->me2_parse:pipe_arglist(Node) end).

-spec 'pipe_expression_list'(input(), index()) -> parse_result().
'pipe_expression_list'(Input, Index) ->
  p(Input, Index, 'pipe_expression_list', fun(I,D) -> (p_seq([fun 'atexpr'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<",">>), p_optional(fun 'ws'/2), fun 'atexpr'/2])), p_optional(fun 'ws'/2)]))(I,D) end, fun(Node, _Idx) ->me2_parse:pipe_expression_list(Node) end).

-spec 'arglist'(input(), index()) -> parse_result().
'arglist'(Input, Index) ->
  p(Input, Index, 'arglist', fun(I,D) -> (p_choose([p_seq([p_string(<<"(">>), p_optional(fun 'ws'/2), fun 'expression_list'/2, p_optional(fun 'ws'/2), p_string(<<")">>)]), p_seq([p_string(<<"(">>), p_optional(fun 'ws'/2), p_string(<<")">>)])]))(I,D) end, fun(Node, _Idx) ->me2_parse:arglist(Node) end).

-spec 'expression_list'(input(), index()) -> parse_result().
'expression_list'(Input, Index) ->
  p(Input, Index, 'expression_list', fun(I,D) -> (p_seq([fun 'expression'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<",">>), p_optional(fun 'ws'/2), fun 'expression'/2])), p_optional(fun 'ws'/2)]))(I,D) end, fun(Node, _Idx) ->me2_parse:expression_list(Node) end).

-spec 'clauses'(input(), index()) -> parse_result().
'clauses'(Input, Index) ->
  p(Input, Index, 'clauses', fun(I,D) -> (p_seq([fun 'clause'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), fun 'clause'/2]))]))(I,D) end, fun(Node, _Idx) ->me2_parse:clauses(Node) end).

-spec 'clause'(input(), index()) -> parse_result().
'clause'(Input, Index) ->
  p(Input, Index, 'clause', fun(I,D) -> (p_seq([fun 'pattern'/2, p_optional(fun 'ws'/2), p_string(<<":">>), p_optional(fun 'ws'/2), fun 'scope'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:clause(Node) end).

-spec 'identifiers'(input(), index()) -> parse_result().
'identifiers'(Input, Index) ->
  p(Input, Index, 'identifiers', fun(I,D) -> (p_zero_or_more(p_seq([fun 'identifier'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<",">>), p_optional(fun 'ws'/2), fun 'identifier'/2])), p_optional(fun 'ws'/2)])))(I,D) end, fun(Node, _Idx) ->me2_parse:identifiers(Node) end).

-spec 'parameters'(input(), index()) -> parse_result().
'parameters'(Input, Index) ->
  p(Input, Index, 'parameters', fun(I,D) -> (p_choose([p_seq([p_optional(fun 'ws'/2), fun 'parameter'/2, p_optional(fun 'ws'/2), p_zero_or_more(p_seq([p_string(<<",">>), p_optional(fun 'ws'/2), fun 'parameter'/2, p_optional(fun 'ws'/2)]))]), p_optional(fun 'ws'/2)]))(I,D) end, fun(Node, _Idx) ->me2_parse:parameters(Node) end).

-spec 'parameter'(input(), index()) -> parse_result().
'parameter'(Input, Index) ->
  p(Input, Index, 'parameter', fun(I,D) -> (p_choose([p_seq([fun 'identifier'/2, p_string(<<"::">>), fun 'class'/2]), fun 'identifier'/2, fun 'pattern'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:parameter(Node) end).

-spec 'pairs'(input(), index()) -> parse_result().
'pairs'(Input, Index) ->
  p(Input, Index, 'pairs', fun(I,D) -> (p_seq([fun 'pair'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<",">>), p_optional(fun 'ws'/2), fun 'pair'/2]))]))(I,D) end, fun(Node, _Idx) ->me2_parse:pairs(Node) end).

-spec 'pair'(input(), index()) -> parse_result().
'pair'(Input, Index) ->
  p(Input, Index, 'pair', fun(I,D) -> (p_seq([fun 'expression'/2, p_optional(fun 'ws'/2), p_string(<<":">>), p_optional(fun 'ws'/2), fun 'expression'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:pair(Node) end).

-spec 'pattern'(input(), index()) -> parse_result().
'pattern'(Input, Index) ->
  p(Input, Index, 'pattern', fun(I,D) -> (p_choose([fun 'pattern_appl'/2, fun 'pattern_body'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern(Node) end).

-spec 'pattern_appl'(input(), index()) -> parse_result().
'pattern_appl'(Input, Index) ->
  p(Input, Index, 'pattern_appl', fun(I,D) -> (p_choose([p_seq([fun 'pattern_id'/2, p_string(<<"(">>), p_optional(fun 'ws'/2), fun 'pattern_args'/2, p_string(<<")">>)]), p_seq([fun 'pattern_id'/2, p_string(<<"(">>), p_optional(fun 'ws'/2), p_string(<<")">>)])]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_appl(Node) end).

-spec 'pattern_id'(input(), index()) -> parse_result().
'pattern_id'(Input, Index) ->
  p(Input, Index, 'pattern_id', fun(I,D) -> (p_seq([p_string(<<"!">>), fun 'identifier'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_id(Node) end).

-spec 'pattern_args'(input(), index()) -> parse_result().
'pattern_args'(Input, Index) ->
  p(Input, Index, 'pattern_args', fun(I,D) -> (p_seq([fun 'pattern_arg'/2, p_optional(fun 'ws'/2), p_zero_or_more(p_seq([p_string(<<",">>), p_optional(fun 'ws'/2), fun 'pattern_arg'/2, p_optional(fun 'ws'/2)]))]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_args(Node) end).

-spec 'pattern_arg'(input(), index()) -> parse_result().
'pattern_arg'(Input, Index) ->
  p(Input, Index, 'pattern_arg', fun(I,D) -> (p_choose([fun 'expression'/2, fun 'pattern'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_arg(Node) end).

-spec 'pattern_body'(input(), index()) -> parse_result().
'pattern_body'(Input, Index) ->
  p(Input, Index, 'pattern_body', fun(I,D) -> (p_choose([fun 'pattern_item'/2, fun 'pattern_list'/2, fun 'pattern_dict'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_body(Node) end).

-spec 'pattern_list'(input(), index()) -> parse_result().
'pattern_list'(Input, Index) ->
  p(Input, Index, 'pattern_list', fun(I,D) -> (p_choose([p_seq([p_string(<<"[">>), p_optional(fun 'ws'/2), fun 'pattern_item'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<",">>), p_optional(fun 'ws'/2), fun 'pattern_item'/2])), p_optional(fun 'ws'/2), p_string(<<"]">>)]), p_seq([p_string(<<"[">>), p_optional(fun 'ws'/2), p_string(<<"]">>)])]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_list(Node) end).

-spec 'pattern_dict'(input(), index()) -> parse_result().
'pattern_dict'(Input, Index) ->
  p(Input, Index, 'pattern_dict', fun(I,D) -> (p_choose([p_seq([p_string(<<"#{">>), p_optional(fun 'ws'/2), fun 'pattern_pair'/2, p_zero_or_more(p_seq([p_optional(fun 'ws'/2), p_string(<<",">>), p_optional(fun 'ws'/2), fun 'pattern_pair'/2])), p_optional(fun 'ws'/2), p_string(<<"}">>)]), p_seq([p_string(<<"#{">>), p_optional(fun 'ws'/2), p_string(<<"}">>)])]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_dict(Node) end).

-spec 'pattern_pair'(input(), index()) -> parse_result().
'pattern_pair'(Input, Index) ->
  p(Input, Index, 'pattern_pair', fun(I,D) -> (p_seq([fun 'pattern_item'/2, p_optional(fun 'ws'/2), p_string(<<":">>), p_optional(fun 'ws'/2), fun 'pattern_item'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_pair(Node) end).

-spec 'pattern_item'(input(), index()) -> parse_result().
'pattern_item'(Input, Index) ->
  p(Input, Index, 'pattern_item', fun(I,D) -> (p_choose([p_string(<<"_">>), fun 'literal'/2, fun 'identifier'/2, fun 'pattern'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:pattern_item(Node) end).

-spec 'literal'(input(), index()) -> parse_result().
'literal'(Input, Index) ->
  p(Input, Index, 'literal', fun(I,D) -> (p_choose([fun 'boolean'/2, fun 'null'/2, fun 'number'/2, fun 'stamp'/2, fun 'delta'/2, fun 'bits'/2, fun 'string'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:literal(Node) end).

-spec 'stamp'(input(), index()) -> parse_result().
'stamp'(Input, Index) ->
  p(Input, Index, 'stamp', fun(I,D) -> (p_seq([fun 'year'/2, p_string(<<"-">>), fun 'month'/2, p_string(<<"-">>), fun 'day'/2, p_string(<<"T">>), fun 'hour'/2, p_string(<<":">>), fun 'minute'/2, p_string(<<":">>), fun 'second'/2, p_optional(fun 'frac'/2), fun 'tz'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:stamp(Node) end).

-spec 'delta'(input(), index()) -> parse_result().
'delta'(Input, Index) ->
  p(Input, Index, 'delta', fun(I,D) -> (p_seq([fun 'number'/2, fun 'time_unit'/2]))(I,D) end, fun(Node, _Idx) ->me2_parse:delta(Node) end).

-spec 'number'(input(), index()) -> parse_result().
'number'(Input, Index) ->
  p(Input, Index, 'number', fun(I,D) -> (p_seq([p_optional(fun 'sign'/2), fun 'int'/2, p_optional(fun 'frac'/2), p_optional(p_seq([p_string(<<"E">>), p_optional(fun 'sign'/2), fun 'int'/2]))]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'frac'(input(), index()) -> parse_result().
'frac'(Input, Index) ->
  p(Input, Index, 'frac', fun(I,D) -> (p_seq([p_string(<<".">>), p_one_or_more(p_charclass(<<"[0-9]">>))]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'bits'(input(), index()) -> parse_result().
'bits'(Input, Index) ->
  p(Input, Index, 'bits', fun(I,D) -> (p_seq([p_string(<<"0x">>), p_one_or_more(fun 'hexdigit'/2), fun 'bits_trailer'/2]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'string'(input(), index()) -> parse_result().
'string'(Input, Index) ->
  p(Input, Index, 'string', fun(I,D) -> (p_seq([p_string(<<"\"">>), p_zero_or_more(p_choose([p_string(<<"\\\"">>), p_seq([p_not(p_string(<<"\"">>)), p_anything()])])), p_string(<<"\"">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'boolean'(input(), index()) -> parse_result().
'boolean'(Input, Index) ->
  p(Input, Index, 'boolean', fun(I,D) -> (p_choose([p_string(<<"true">>), p_string(<<"false">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'null'(input(), index()) -> parse_result().
'null'(Input, Index) ->
  p(Input, Index, 'null', fun(I,D) -> (p_string(<<"null">>))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'identifier'(input(), index()) -> parse_result().
'identifier'(Input, Index) ->
  p(Input, Index, 'identifier', fun(I,D) -> (p_seq([p_charclass(<<"[a-z]">>), p_zero_or_more(p_charclass(<<"[a-zA-Z0-9_]">>))]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'class'(input(), index()) -> parse_result().
'class'(Input, Index) ->
  p(Input, Index, 'class', fun(I,D) -> (p_seq([p_charclass(<<"[A-Z]">>), p_zero_or_more(p_charclass(<<"[a-zA-Z0-9_]">>))]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'ws'(input(), index()) -> parse_result().
'ws'(Input, Index) ->
  p(Input, Index, 'ws', fun(I,D) -> (p_one_or_more(p_charclass(<<"[\t\n\r\s]">>)))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'sign'(input(), index()) -> parse_result().
'sign'(Input, Index) ->
  p(Input, Index, 'sign', fun(I,D) -> (p_choose([p_string(<<"+">>), p_string(<<"-">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'year'(input(), index()) -> parse_result().
'year'(Input, Index) ->
  p(Input, Index, 'year', fun(I,D) -> (p_seq([p_charclass(<<"[0-9]">>), p_charclass(<<"[0-9]">>), p_charclass(<<"[0-9]">>), p_charclass(<<"[0-9]">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'int'(input(), index()) -> parse_result().
'int'(Input, Index) ->
  p(Input, Index, 'int', fun(I,D) -> (p_choose([p_charclass(<<"[0-9]">>), p_seq([p_charclass(<<"[1-9]">>), p_one_or_more(p_charclass(<<"[0-9]">>))])]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'month'(input(), index()) -> parse_result().
'month'(Input, Index) ->
  p(Input, Index, 'month', fun(I,D) -> (p_choose([p_seq([p_string(<<"0">>), p_charclass(<<"[1-9]">>)]), p_seq([p_string(<<"1">>), p_charclass(<<"[0-2]">>)])]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'day'(input(), index()) -> parse_result().
'day'(Input, Index) ->
  p(Input, Index, 'day', fun(I,D) -> (p_choose([p_seq([p_string(<<"0">>), p_charclass(<<"[1-9]">>)]), p_seq([p_charclass(<<"[12]">>), p_charclass(<<"[0-9]">>)]), p_seq([p_string(<<"3">>), p_charclass(<<"[0-1]">>)])]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'hour'(input(), index()) -> parse_result().
'hour'(Input, Index) ->
  p(Input, Index, 'hour', fun(I,D) -> (p_choose([p_seq([p_charclass(<<"[01]">>), p_charclass(<<"[0-9]">>)]), p_seq([p_string(<<"2">>), p_charclass(<<"[0-4]">>)])]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'minute'(input(), index()) -> parse_result().
'minute'(Input, Index) ->
  p(Input, Index, 'minute', fun(I,D) -> (p_seq([p_charclass(<<"[0-5]">>), p_charclass(<<"[0-9]">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'second'(input(), index()) -> parse_result().
'second'(Input, Index) ->
  p(Input, Index, 'second', fun(I,D) -> (p_choose([p_seq([p_charclass(<<"[0-5]">>), p_charclass(<<"[0-9]">>)]), p_string(<<"60">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'time_unit'(input(), index()) -> parse_result().
'time_unit'(Input, Index) ->
  p(Input, Index, 'time_unit', fun(I,D) -> (p_choose([p_string(<<"Y">>), p_string(<<"D">>), p_string(<<"h">>), p_string(<<"m">>), p_string(<<"s">>), p_string(<<"ms">>), p_string(<<"us">>), p_string(<<"ns">>), p_string(<<"ps">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'tz'(input(), index()) -> parse_result().
'tz'(Input, Index) ->
  p(Input, Index, 'tz', fun(I,D) -> (p_choose([p_string(<<"Z">>), p_seq([fun 'sign'/2, fun 'hour'/2, p_string(<<":">>), fun 'minute'/2])]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'math_op'(input(), index()) -> parse_result().
'math_op'(Input, Index) ->
  p(Input, Index, 'math_op', fun(I,D) -> (p_choose([p_string(<<"+">>), p_string(<<"-">>), p_string(<<"*">>), p_string(<<"\/">>), p_string(<<"^">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'hexdigit'(input(), index()) -> parse_result().
'hexdigit'(Input, Index) ->
  p(Input, Index, 'hexdigit', fun(I,D) -> (p_choose([p_charclass(<<"[0-9]">>), p_charclass(<<"[a-f]">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'bits_trailer'(input(), index()) -> parse_result().
'bits_trailer'(Input, Index) ->
  p(Input, Index, 'bits_trailer', fun(I,D) -> (p_seq([p_string(<<":">>), p_charclass(<<"[1-3]">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'atexpr'(input(), index()) -> parse_result().
'atexpr'(Input, Index) ->
  p(Input, Index, 'atexpr', fun(I,D) -> (p_choose([fun 'expression'/2, p_string(<<"@">>)]))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'unary_op'(input(), index()) -> parse_result().
'unary_op'(Input, Index) ->
  p(Input, Index, 'unary_op', fun(I,D) -> (p_string(<<"!">>))(I,D) end, fun(Node, _Idx) ->Node end).

-spec 'binary_op'(input(), index()) -> parse_result().
'binary_op'(Input, Index) ->
  p(Input, Index, 'binary_op', fun(I,D) -> (p_choose([p_string(<<"<<">>), p_string(<<"=<">>), p_string(<<"==">>), p_string(<<"!=">>)]))(I,D) end, fun(Node, _Idx) ->Node end).



-file("peg_includes.hrl", 1).
-type index() :: {{line, pos_integer()}, {column, pos_integer()}}.
-type input() :: binary().
-type parse_failure() :: {fail, term()}.
-type parse_success() :: {term(), input(), index()}.
-type parse_result() :: parse_failure() | parse_success().
-type parse_fun() :: fun((input(), index()) -> parse_result()).
-type xform_fun() :: fun((input(), index()) -> term()).

-spec p(input(), index(), atom(), parse_fun(), xform_fun()) -> parse_result().
p(Inp, StartIndex, Name, ParseFun, TransformFun) ->
  case get_memo(StartIndex, Name) of      % See if the current reduction is memoized
    {ok, Memo} -> %Memo;                     % If it is, return the stored result
      Memo;
    _ ->                                        % If not, attempt to parse
      Result = case ParseFun(Inp, StartIndex) of
        {fail,_} = Failure ->                       % If it fails, memoize the failure
          Failure;
        {Match, InpRem, NewIndex} ->               % If it passes, transform and memoize the result.
          Transformed = TransformFun(Match, StartIndex),
          {Transformed, InpRem, NewIndex}
      end,
      memoize(StartIndex, Name, Result),
      Result
  end.

-spec setup_memo() -> ets:tid().
setup_memo() ->
  put({parse_memo_table, ?MODULE}, ets:new(?MODULE, [set])).

-spec release_memo() -> true.
release_memo() ->
  ets:delete(memo_table_name()).

-spec memoize(index(), atom(), parse_result()) -> true.
memoize(Index, Name, Result) ->
  Memo = case ets:lookup(memo_table_name(), Index) of
              [] -> [];
              [{Index, Plist}] -> Plist
         end,
  ets:insert(memo_table_name(), {Index, [{Name, Result}|Memo]}).

-spec get_memo(index(), atom()) -> {ok, term()} | {error, not_found}.
get_memo(Index, Name) ->
  case ets:lookup(memo_table_name(), Index) of
    [] -> {error, not_found};
    [{Index, Plist}] ->
      case proplists:lookup(Name, Plist) of
        {Name, Result}  -> {ok, Result};
        _  -> {error, not_found}
      end
    end.

-spec memo_table_name() -> ets:tid().
memo_table_name() ->
    get({parse_memo_table, ?MODULE}).

-ifdef(p_eof).
-spec p_eof() -> parse_fun().
p_eof() ->
  fun(<<>>, Index) -> {eof, [], Index};
     (_, Index) -> {fail, {expected, eof, Index}} end.
-endif.

-ifdef(p_optional).
-spec p_optional(parse_fun()) -> parse_fun().
p_optional(P) ->
  fun(Input, Index) ->
      case P(Input, Index) of
        {fail,_} -> {[], Input, Index};
        {_, _, _} = Success -> Success
      end
  end.
-endif.

-ifdef(p_not).
-spec p_not(parse_fun()) -> parse_fun().
p_not(P) ->
  fun(Input, Index)->
      case P(Input,Index) of
        {fail,_} ->
          {[], Input, Index};
        {Result, _, _} -> {fail, {expected, {no_match, Result},Index}}
      end
  end.
-endif.

-ifdef(p_assert).
-spec p_assert(parse_fun()) -> parse_fun().
p_assert(P) ->
  fun(Input,Index) ->
      case P(Input,Index) of
        {fail,_} = Failure-> Failure;
        _ -> {[], Input, Index}
      end
  end.
-endif.

-ifdef(p_seq).
-spec p_seq([parse_fun()]) -> parse_fun().
p_seq(P) ->
  fun(Input, Index) ->
      p_all(P, Input, Index, [])
  end.

-spec p_all([parse_fun()], input(), index(), [term()]) -> parse_result().
p_all([], Inp, Index, Accum ) -> {lists:reverse( Accum ), Inp, Index};
p_all([P|Parsers], Inp, Index, Accum) ->
  case P(Inp, Index) of
    {fail, _} = Failure -> Failure;
    {Result, InpRem, NewIndex} -> p_all(Parsers, InpRem, NewIndex, [Result|Accum])
  end.
-endif.

-ifdef(p_choose).
-spec p_choose([parse_fun()]) -> parse_fun().
p_choose(Parsers) ->
  fun(Input, Index) ->
      p_attempt(Parsers, Input, Index, none)
  end.

-spec p_attempt([parse_fun()], input(), index(), none | parse_failure()) -> parse_result().
p_attempt([], _Input, _Index, Failure) -> Failure;
p_attempt([P|Parsers], Input, Index, FirstFailure)->
  case P(Input, Index) of
    {fail, _} = Failure ->
      case FirstFailure of
        none -> p_attempt(Parsers, Input, Index, Failure);
        _ -> p_attempt(Parsers, Input, Index, FirstFailure)
      end;
    Result -> Result
  end.
-endif.

-ifdef(p_zero_or_more).
-spec p_zero_or_more(parse_fun()) -> parse_fun().
p_zero_or_more(P) ->
  fun(Input, Index) ->
      p_scan(P, Input, Index, [])
  end.
-endif.

-ifdef(p_one_or_more).
-spec p_one_or_more(parse_fun()) -> parse_fun().
p_one_or_more(P) ->
  fun(Input, Index)->
      Result = p_scan(P, Input, Index, []),
      case Result of
        {[_|_], _, _} ->
          Result;
        _ ->
          {fail, {expected, Failure, _}} = P(Input,Index),
          {fail, {expected, {at_least_one, Failure}, Index}}
      end
  end.
-endif.

-ifdef(p_label).
-spec p_label(atom(), parse_fun()) -> parse_fun().
p_label(Tag, P) ->
  fun(Input, Index) ->
      case P(Input, Index) of
        {fail,_} = Failure ->
           Failure;
        {Result, InpRem, NewIndex} ->
          {{Tag, Result}, InpRem, NewIndex}
      end
  end.
-endif.

-ifdef(p_scan).
-spec p_scan(parse_fun(), input(), index(), [term()]) -> {[term()], input(), index()}.
p_scan(_, <<>>, Index, Accum) -> {lists:reverse(Accum), <<>>, Index};
p_scan(P, Inp, Index, Accum) ->
  case P(Inp, Index) of
    {fail,_} -> {lists:reverse(Accum), Inp, Index};
    {Result, InpRem, NewIndex} -> p_scan(P, InpRem, NewIndex, [Result | Accum])
  end.
-endif.

-ifdef(p_string).
-spec p_string(binary()) -> parse_fun().
p_string(S) ->
    Length = erlang:byte_size(S),
    fun(Input, Index) ->
      try
          <<S:Length/binary, Rest/binary>> = Input,
          {S, Rest, p_advance_index(S, Index)}
      catch
          error:{badmatch,_} -> {fail, {expected, {string, S}, Index}}
      end
    end.
-endif.

-ifdef(p_anything).
-spec p_anything() -> parse_fun().
p_anything() ->
  fun(<<>>, Index) -> {fail, {expected, any_character, Index}};
     (Input, Index) when is_binary(Input) ->
          <<C/utf8, Rest/binary>> = Input,
          {<<C/utf8>>, Rest, p_advance_index(<<C/utf8>>, Index)}
  end.
-endif.

-ifdef(p_charclass).
-spec p_charclass(string() | binary()) -> parse_fun().
p_charclass(Class) ->
    {ok, RE} = re:compile(Class, [unicode, dotall]),
    fun(Inp, Index) ->
            case re:run(Inp, RE, [anchored]) of
                {match, [{0, Length}|_]} ->
                    {Head, Tail} = erlang:split_binary(Inp, Length),
                    {Head, Tail, p_advance_index(Head, Index)};
                _ -> {fail, {expected, {character_class, binary_to_list(Class)}, Index}}
            end
    end.
-endif.

-ifdef(p_regexp).
-spec p_regexp(binary()) -> parse_fun().
p_regexp(Regexp) ->
    {ok, RE} = re:compile(Regexp, [unicode, dotall, anchored]),
    fun(Inp, Index) ->
        case re:run(Inp, RE) of
            {match, [{0, Length}|_]} ->
                {Head, Tail} = erlang:split_binary(Inp, Length),
                {Head, Tail, p_advance_index(Head, Index)};
            _ -> {fail, {expected, {regexp, binary_to_list(Regexp)}, Index}}
        end
    end.
-endif.

-ifdef(line).
-spec line(index() | term()) -> pos_integer() | undefined.
line({{line,L},_}) -> L;
line(_) -> undefined.
-endif.

-ifdef(column).
-spec column(index() | term()) -> pos_integer() | undefined.
column({_,{column,C}}) -> C;
column(_) -> undefined.
-endif.

-spec p_advance_index(input() | unicode:charlist() | pos_integer(), index()) -> index().
p_advance_index(MatchedInput, Index) when is_list(MatchedInput) orelse is_binary(MatchedInput)-> % strings
  lists:foldl(fun p_advance_index/2, Index, unicode:characters_to_list(MatchedInput));
p_advance_index(MatchedInput, Index) when is_integer(MatchedInput) -> % single characters
  {{line, Line}, {column, Col}} = Index,
  case MatchedInput of
    $\n -> {{line, Line+1}, {column, 1}};
    _ -> {{line, Line}, {column, Col+1}}
  end.
