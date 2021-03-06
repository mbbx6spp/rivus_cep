-file("/usr/local/lib/erlang/lib/parsetools-2.0.11/include/leexinc.hrl", 0).
%% The source of this file is part of leex distribution, as such it
%% has the same Copyright as the other files in the leex
%% distribution. The Copyright is defined in the accompanying file
%% COPYRIGHT. However, the resultant scanner generated by leex is the
%% property of the creator of the scanner and is not covered by that
%% Copyright.

-module(rivus_cep_scanner).

-export([string/1,string/2,token/2,token/3,tokens/2,tokens/3]).
-export([format_error/1]).

%% User code. This is placed here to allow extra attributes.
-file("src/rivus_cep_scanner.xrl", 56).

-export([reserved_word/1]).

%% reserved_word(Atom) -> Bool
%%   return 'true' if Atom is an Erlang reserved word, else 'false'.

reserved_word('define') -> true;
reserved_word('as') -> true;
reserved_word('select') -> true;
reserved_word('from') -> true;
reserved_word('where') -> true;
reserved_word('within') -> true;
reserved_word('seconds') -> true;
reserved_word('and') -> true;
reserved_word('or') -> true;
reserved_word('not') -> true;
reserved_word('if') -> true;
reserved_word('foreach') -> true;
reserved_word('index') -> true;
reserved_word('of') -> true;
reserved_word('end') -> true;
reserved_word('sum') -> true;
reserved_word('count') -> true;
reserved_word('avg') -> true;
reserved_word('min') -> true;
reserved_word('max') -> true;
reserved_word('sliding') -> true;
reserved_word('batch') -> true;
reserved_word('tumbling') -> true;
reserved_word(_) -> false.

cc_convert([$$,$\\|Cs]) ->
    hd(string_escape(Cs));
cc_convert([$$,C]) -> C.

string_gen([$\\|Cs]) ->
    string_escape(Cs);
string_gen([C|Cs]) ->
    [C|string_gen(Cs)];
string_gen([]) -> [].

string_escape([O1,O2,O3|S]) when
  O1 >= $0, O1 =< $7, O2 >= $0, O2 =< $7, O3 >= $0, O3 =< $7 ->
    [(O1*8 + O2)*8 + O3 - 73*$0|string_gen(S)];
string_escape([$^,C|Cs]) ->
    [C band 31|string_gen(Cs)];
string_escape([C|Cs]) when C >= $\000, C =< $\s ->
    string_gen(Cs);
string_escape([C|Cs]) ->
    [escape_char(C)|string_gen(Cs)].

escape_char($n) -> $\n;				%\n = LF
escape_char($r) -> $\r;				%\r = CR
escape_char($t) -> $\t;				%\t = TAB
escape_char($v) -> $\v;				%\v = VT
escape_char($b) -> $\b;				%\b = BS
escape_char($f) -> $\f;				%\f = FF
escape_char($e) -> $\e;				%\e = ESC
escape_char($s) -> $\s;				%\s = SPC
escape_char($d) -> $\d;				%\d = DEL
escape_char(C) -> C.

-file("/usr/local/lib/erlang/lib/parsetools-2.0.11/include/leexinc.hrl", 14).

format_error({illegal,S}) -> ["illegal characters ",io_lib:write_string(S)];
format_error({user,S}) -> S.

string(String) -> string(String, 1).

string(String, Line) -> string(String, Line, String, []).

%% string(InChars, Line, TokenChars, Tokens) ->
%% {ok,Tokens,Line} | {error,ErrorInfo,Line}.
%% Note the line number going into yystate, L0, is line of token
%% start while line number returned is line of token end. We want line
%% of token start.

string([], L, [], Ts) ->                     % No partial tokens!
    {ok,yyrev(Ts),L};
string(Ics0, L0, Tcs, Ts) ->
    case yystate(yystate(), Ics0, L0, 0, reject, 0) of
        {A,Alen,Ics1,L1} ->                  % Accepting end state
            string_cont(Ics1, L1, yyaction(A, Alen, Tcs, L0), Ts);
        {A,Alen,Ics1,L1,_S1} ->              % Accepting transistion state
            string_cont(Ics1, L1, yyaction(A, Alen, Tcs, L0), Ts);
        {reject,_Alen,Tlen,_Ics1,L1,_S1} ->  % After a non-accepting state
            {error,{L0,?MODULE,{illegal,yypre(Tcs, Tlen+1)}},L1};
        {A,Alen,_Tlen,_Ics1,L1,_S1} ->
            string_cont(yysuf(Tcs, Alen), L1, yyaction(A, Alen, Tcs, L0), Ts)
    end.

%% string_cont(RestChars, Line, Token, Tokens)
%% Test for and remove the end token wrapper. Push back characters
%% are prepended to RestChars.

string_cont(Rest, Line, {token,T}, Ts) ->
    string(Rest, Line, Rest, [T|Ts]);
string_cont(Rest, Line, {token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, [T|Ts]);
string_cont(Rest, Line, {end_token,T}, Ts) ->
    string(Rest, Line, Rest, [T|Ts]);
string_cont(Rest, Line, {end_token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, [T|Ts]);
string_cont(Rest, Line, skip_token, Ts) ->
    string(Rest, Line, Rest, Ts);
string_cont(Rest, Line, {skip_token,Push}, Ts) ->
    NewRest = Push ++ Rest,
    string(NewRest, Line, NewRest, Ts);
string_cont(_Rest, Line, {error,S}, _Ts) ->
    {error,{Line,?MODULE,{user,S}},Line}.

%% token(Continuation, Chars) ->
%% token(Continuation, Chars, Line) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% Must be careful when re-entering to append the latest characters to the
%% after characters in an accept. The continuation is:
%% {token,State,CurrLine,TokenChars,TokenLen,TokenLine,AccAction,AccLen}

token(Cont, Chars) -> token(Cont, Chars, 1).

token([], Chars, Line) ->
    token(yystate(), Chars, Line, Chars, 0, Line, reject, 0);
token({token,State,Line,Tcs,Tlen,Tline,Action,Alen}, Chars, _) ->
    token(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Action, Alen).

%% token(State, InChars, Line, TokenChars, TokenLen, TokenLine,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% The argument order is chosen to be more efficient.

token(S0, Ics0, L0, Tcs, Tlen0, Tline, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        %% Accepting end state, we have a token.
        {A1,Alen1,Ics1,L1} ->
            token_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline));
        %% Accepting transition state, can take more chars.
        {A1,Alen1,[],L1,S1} ->                  % Need more chars to check
            {more,{token,S1,L1,Tcs,Alen1,Tline,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->               % Take what we got
            token_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline));
        %% After a non-accepting state, maybe reach accept state later.
        {A1,Alen1,Tlen1,[],L1,S1} ->            % Need more chars to check
            {more,{token,S1,L1,Tcs,Tlen1,Tline,A1,Alen1}};
        {reject,_Alen1,Tlen1,eof,L1,_S1} ->     % No token match
            %% Check for partial token which is error.
            Ret = if Tlen1 > 0 -> {error,{Tline,?MODULE,
                                          %% Skip eof tail in Tcs.
                                          {illegal,yypre(Tcs, Tlen1)}},L1};
                     true -> {eof,L1}
                  end,
            {done,Ret,eof};
        {reject,_Alen1,Tlen1,Ics1,L1,_S1} ->    % No token match
            Error = {Tline,?MODULE,{illegal,yypre(Tcs, Tlen1+1)}},
            {done,{error,Error,L1},Ics1};
        {A1,Alen1,_Tlen1,_Ics1,L1,_S1} ->       % Use last accept match
            token_cont(yysuf(Tcs, Alen1), L1, yyaction(A1, Alen1, Tcs, Tline))
    end.

%% token_cont(RestChars, Line, Token)
%% If we have a token or error then return done, else if we have a
%% skip_token then continue.

token_cont(Rest, Line, {token,T}) ->
    {done,{ok,T,Line},Rest};
token_cont(Rest, Line, {token,T,Push}) ->
    NewRest = Push ++ Rest,
    {done,{ok,T,Line},NewRest};
token_cont(Rest, Line, {end_token,T}) ->
    {done,{ok,T,Line},Rest};
token_cont(Rest, Line, {end_token,T,Push}) ->
    NewRest = Push ++ Rest,
    {done,{ok,T,Line},NewRest};
token_cont(Rest, Line, skip_token) ->
    token(yystate(), Rest, Line, Rest, 0, Line, reject, 0);
token_cont(Rest, Line, {skip_token,Push}) ->
    NewRest = Push ++ Rest,
    token(yystate(), NewRest, Line, NewRest, 0, Line, reject, 0);
token_cont(Rest, Line, {error,S}) ->
    {done,{error,{Line,?MODULE,{user,S}},Line},Rest}.

%% tokens(Continuation, Chars, Line) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.
%% Must be careful when re-entering to append the latest characters to the
%% after characters in an accept. The continuation is:
%% {tokens,State,CurrLine,TokenChars,TokenLen,TokenLine,Tokens,AccAction,AccLen}
%% {skip_tokens,State,CurrLine,TokenChars,TokenLen,TokenLine,Error,AccAction,AccLen}

tokens(Cont, Chars) -> tokens(Cont, Chars, 1).

tokens([], Chars, Line) ->
    tokens(yystate(), Chars, Line, Chars, 0, Line, [], reject, 0);
tokens({tokens,State,Line,Tcs,Tlen,Tline,Ts,Action,Alen}, Chars, _) ->
    tokens(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Ts, Action, Alen);
tokens({skip_tokens,State,Line,Tcs,Tlen,Tline,Error,Action,Alen}, Chars, _) ->
    skip_tokens(State, Chars, Line, Tcs ++ Chars, Tlen, Tline, Error, Action, Alen).

%% tokens(State, InChars, Line, TokenChars, TokenLen, TokenLine, Tokens,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.

tokens(S0, Ics0, L0, Tcs, Tlen0, Tline, Ts, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        %% Accepting end state, we have a token.
        {A1,Alen1,Ics1,L1} ->
            tokens_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Ts);
        %% Accepting transition state, can take more chars.
        {A1,Alen1,[],L1,S1} ->                  % Need more chars to check
            {more,{tokens,S1,L1,Tcs,Alen1,Tline,Ts,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->               % Take what we got
            tokens_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Ts);
        %% After a non-accepting state, maybe reach accept state later.
        {A1,Alen1,Tlen1,[],L1,S1} ->            % Need more chars to check
            {more,{tokens,S1,L1,Tcs,Tlen1,Tline,Ts,A1,Alen1}};
        {reject,_Alen1,Tlen1,eof,L1,_S1} ->     % No token match
            %% Check for partial token which is error, no need to skip here.
            Ret = if Tlen1 > 0 -> {error,{Tline,?MODULE,
                                          %% Skip eof tail in Tcs.
                                          {illegal,yypre(Tcs, Tlen1)}},L1};
                     Ts == [] -> {eof,L1};
                     true -> {ok,yyrev(Ts),L1}
                  end,
            {done,Ret,eof};
        {reject,_Alen1,Tlen1,_Ics1,L1,_S1} ->
            %% Skip rest of tokens.
            Error = {L1,?MODULE,{illegal,yypre(Tcs, Tlen1+1)}},
            skip_tokens(yysuf(Tcs, Tlen1+1), L1, Error);
        {A1,Alen1,_Tlen1,_Ics1,L1,_S1} ->
            Token = yyaction(A1, Alen1, Tcs, Tline),
            tokens_cont(yysuf(Tcs, Alen1), L1, Token, Ts)
    end.

%% tokens_cont(RestChars, Line, Token, Tokens)
%% If we have an end_token or error then return done, else if we have
%% a token then save it and continue, else if we have a skip_token
%% just continue.

tokens_cont(Rest, Line, {token,T}, Ts) ->
    tokens(yystate(), Rest, Line, Rest, 0, Line, [T|Ts], reject, 0);
tokens_cont(Rest, Line, {token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    tokens(yystate(), NewRest, Line, NewRest, 0, Line, [T|Ts], reject, 0);
tokens_cont(Rest, Line, {end_token,T}, Ts) ->
    {done,{ok,yyrev(Ts, [T]),Line},Rest};
tokens_cont(Rest, Line, {end_token,T,Push}, Ts) ->
    NewRest = Push ++ Rest,
    {done,{ok,yyrev(Ts, [T]),Line},NewRest};
tokens_cont(Rest, Line, skip_token, Ts) ->
    tokens(yystate(), Rest, Line, Rest, 0, Line, Ts, reject, 0);
tokens_cont(Rest, Line, {skip_token,Push}, Ts) ->
    NewRest = Push ++ Rest,
    tokens(yystate(), NewRest, Line, NewRest, 0, Line, Ts, reject, 0);
tokens_cont(Rest, Line, {error,S}, _Ts) ->
    skip_tokens(Rest, Line, {Line,?MODULE,{user,S}}).

%%skip_tokens(InChars, Line, Error) -> {done,{error,Error,Line},Ics}.
%% Skip tokens until an end token, junk everything and return the error.

skip_tokens(Ics, Line, Error) ->
    skip_tokens(yystate(), Ics, Line, Ics, 0, Line, Error, reject, 0).

%% skip_tokens(State, InChars, Line, TokenChars, TokenLen, TokenLine, Tokens,
%% AcceptAction, AcceptLen) ->
%% {more,Continuation} | {done,ReturnVal,RestChars}.

skip_tokens(S0, Ics0, L0, Tcs, Tlen0, Tline, Error, A0, Alen0) ->
    case yystate(S0, Ics0, L0, Tlen0, A0, Alen0) of
        {A1,Alen1,Ics1,L1} ->                  % Accepting end state
            skip_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Error);
        {A1,Alen1,[],L1,S1} ->                 % After an accepting state
            {more,{skip_tokens,S1,L1,Tcs,Alen1,Tline,Error,A1,Alen1}};
        {A1,Alen1,Ics1,L1,_S1} ->
            skip_cont(Ics1, L1, yyaction(A1, Alen1, Tcs, Tline), Error);
        {A1,Alen1,Tlen1,[],L1,S1} ->           % After a non-accepting state
            {more,{skip_tokens,S1,L1,Tcs,Tlen1,Tline,Error,A1,Alen1}};
        {reject,_Alen1,_Tlen1,eof,L1,_S1} ->
            {done,{error,Error,L1},eof};
        {reject,_Alen1,Tlen1,_Ics1,L1,_S1} ->
            skip_tokens(yysuf(Tcs, Tlen1+1), L1, Error);
        {A1,Alen1,_Tlen1,_Ics1,L1,_S1} ->
            Token = yyaction(A1, Alen1, Tcs, Tline),
            skip_cont(yysuf(Tcs, Alen1), L1, Token, Error)
    end.

%% skip_cont(RestChars, Line, Token, Error)
%% Skip tokens until we have an end_token or error then return done
%% with the original rror.

skip_cont(Rest, Line, {token,_T}, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {token,_T,Push}, Error) ->
    NewRest = Push ++ Rest,
    skip_tokens(yystate(), NewRest, Line, NewRest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {end_token,_T}, Error) ->
    {done,{error,Error,Line},Rest};
skip_cont(Rest, Line, {end_token,_T,Push}, Error) ->
    NewRest = Push ++ Rest,
    {done,{error,Error,Line},NewRest};
skip_cont(Rest, Line, skip_token, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {skip_token,Push}, Error) ->
    NewRest = Push ++ Rest,
    skip_tokens(yystate(), NewRest, Line, NewRest, 0, Line, Error, reject, 0);
skip_cont(Rest, Line, {error,_S}, Error) ->
    skip_tokens(yystate(), Rest, Line, Rest, 0, Line, Error, reject, 0).

yyrev(List) -> lists:reverse(List).
yyrev(List, Tail) -> lists:reverse(List, Tail).
yypre(List, N) -> lists:sublist(List, N).
yysuf(List, N) -> lists:nthtail(N, List).

%% yystate() -> InitialState.
%% yystate(State, InChars, Line, CurrTokLen, AcceptAction, AcceptLen) ->
%% {Action, AcceptLen, RestChars, Line} |
%% {Action, AcceptLen, RestChars, Line, State} |
%% {reject, AcceptLen, CurrTokLen, RestChars, Line, State} |
%% {Action, AcceptLen, CurrTokLen, RestChars, Line, State}.
%% Generated state transition functions. The non-accepting end state
%% return signal either an unrecognised character or end of current
%% input.

-file("src/rivus_cep_scanner.erl", 337).
yystate() -> 38.

yystate(41, [92|Ics], Line, Tlen, _, _) ->
    yystate(37, Ics, Line, Tlen+1, 4, Tlen);
yystate(41, [39|Ics], Line, Tlen, _, _) ->
    yystate(39, Ics, Line, Tlen+1, 4, Tlen);
yystate(41, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(33, Ics, Line, Tlen+1, 4, Tlen);
yystate(41, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 38 ->
    yystate(33, Ics, Line, Tlen+1, 4, Tlen);
yystate(41, [C|Ics], Line, Tlen, _, _) when C >= 40, C =< 91 ->
    yystate(33, Ics, Line, Tlen+1, 4, Tlen);
yystate(41, [C|Ics], Line, Tlen, _, _) when C >= 93 ->
    yystate(33, Ics, Line, Tlen+1, 4, Tlen);
yystate(41, Ics, Line, Tlen, _, _) ->
    {4,Tlen,Ics,Line,41};
yystate(40, [37|Ics], Line, Tlen, _, _) ->
    yystate(35, Ics, Line, Tlen+1, 21, Tlen);
yystate(40, [10|Ics], Line, Tlen, _, _) ->
    yystate(40, Ics, Line+1, Tlen+1, 21, Tlen);
yystate(40, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(40, Ics, Line, Tlen+1, 21, Tlen);
yystate(40, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 32 ->
    yystate(40, Ics, Line, Tlen+1, 21, Tlen);
yystate(40, Ics, Line, Tlen, _, _) ->
    {21,Tlen,Ics,Line,40};
yystate(39, Ics, Line, Tlen, _, _) ->
    {4,Tlen,Ics,Line};
yystate(38, [95|Ics], Line, Tlen, Action, Alen) ->
    yystate(30, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [93|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [91|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [63|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [62|Ics], Line, Tlen, Action, Alen) ->
    yystate(26, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [61|Ics], Line, Tlen, Action, Alen) ->
    yystate(18, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [60|Ics], Line, Tlen, Action, Alen) ->
    yystate(10, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [59|Ics], Line, Tlen, Action, Alen) ->
    yystate(2, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [58|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [47|Ics], Line, Tlen, Action, Alen) ->
    yystate(5, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [46|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [45|Ics], Line, Tlen, Action, Alen) ->
    yystate(9, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [44|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [43|Ics], Line, Tlen, Action, Alen) ->
    yystate(17, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [42|Ics], Line, Tlen, Action, Alen) ->
    yystate(21, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [41|Ics], Line, Tlen, Action, Alen) ->
    yystate(25, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [40|Ics], Line, Tlen, Action, Alen) ->
    yystate(29, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [37|Ics], Line, Tlen, Action, Alen) ->
    yystate(35, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [36|Ics], Line, Tlen, Action, Alen) ->
    yystate(31, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [35|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [34|Ics], Line, Tlen, Action, Alen) ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [33|Ics], Line, Tlen, Action, Alen) ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(40, Ics, Line+1, Tlen+1, Action, Alen);
yystate(38, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(40, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 32 ->
    yystate(40, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [C|Ics], Line, Tlen, Action, Alen) when C >= 48, C =< 57 ->
    yystate(1, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [C|Ics], Line, Tlen, Action, Alen) when C >= 65, C =< 90 ->
    yystate(30, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [C|Ics], Line, Tlen, Action, Alen) when C >= 97, C =< 122 ->
    yystate(34, Ics, Line, Tlen+1, Action, Alen);
yystate(38, [C|Ics], Line, Tlen, Action, Alen) when C >= 123, C =< 125 ->
    yystate(36, Ics, Line, Tlen+1, Action, Alen);
yystate(38, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,38};
yystate(37, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(37, Ics, Line, Tlen+1, Action, Alen);
yystate(37, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(41, Ics, Line, Tlen+1, Action, Alen);
yystate(37, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(33, Ics, Line+1, Tlen+1, Action, Alen);
yystate(37, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(37, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 38 ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(37, [C|Ics], Line, Tlen, Action, Alen) when C >= 40, C =< 91 ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(37, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(37, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,37};
yystate(36, Ics, Line, Tlen, _, _) ->
    {19,Tlen,Ics,Line};
yystate(35, [37|Ics], Line, Tlen, _, _) ->
    yystate(35, Ics, Line, Tlen+1, 21, Tlen);
yystate(35, [10|Ics], Line, Tlen, _, _) ->
    yystate(40, Ics, Line+1, Tlen+1, 21, Tlen);
yystate(35, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(35, Ics, Line, Tlen+1, 21, Tlen);
yystate(35, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 32 ->
    yystate(35, Ics, Line, Tlen+1, 21, Tlen);
yystate(35, [C|Ics], Line, Tlen, _, _) when C >= 33, C =< 36 ->
    yystate(35, Ics, Line, Tlen+1, 21, Tlen);
yystate(35, [C|Ics], Line, Tlen, _, _) when C >= 38 ->
    yystate(35, Ics, Line, Tlen+1, 21, Tlen);
yystate(35, Ics, Line, Tlen, _, _) ->
    {21,Tlen,Ics,Line,35};
yystate(34, [95|Ics], Line, Tlen, _, _) ->
    yystate(34, Ics, Line, Tlen+1, 1, Tlen);
yystate(34, [C|Ics], Line, Tlen, _, _) when C >= 48, C =< 57 ->
    yystate(34, Ics, Line, Tlen+1, 1, Tlen);
yystate(34, [C|Ics], Line, Tlen, _, _) when C >= 65, C =< 90 ->
    yystate(34, Ics, Line, Tlen+1, 1, Tlen);
yystate(34, [C|Ics], Line, Tlen, _, _) when C >= 97, C =< 122 ->
    yystate(34, Ics, Line, Tlen+1, 1, Tlen);
yystate(34, Ics, Line, Tlen, _, _) ->
    {1,Tlen,Ics,Line,34};
yystate(33, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(37, Ics, Line, Tlen+1, Action, Alen);
yystate(33, [39|Ics], Line, Tlen, Action, Alen) ->
    yystate(39, Ics, Line, Tlen+1, Action, Alen);
yystate(33, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(33, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 38 ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(33, [C|Ics], Line, Tlen, Action, Alen) when C >= 40, C =< 91 ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(33, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(33, Ics, Line, Tlen+1, Action, Alen);
yystate(33, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,33};
yystate(32, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(20, Ics, Line, Tlen+1, Action, Alen);
yystate(32, [34|Ics], Line, Tlen, Action, Alen) ->
    yystate(28, Ics, Line, Tlen+1, Action, Alen);
yystate(32, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(32, Ics, Line+1, Tlen+1, Action, Alen);
yystate(32, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(32, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 33 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(32, [C|Ics], Line, Tlen, Action, Alen) when C >= 35, C =< 91 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(32, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(32, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,32};
yystate(31, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(27, Ics, Line, Tlen+1, Action, Alen);
yystate(31, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(31, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 91 ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(31, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(31, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,31};
yystate(30, [95|Ics], Line, Tlen, _, _) ->
    yystate(30, Ics, Line, Tlen+1, 2, Tlen);
yystate(30, [C|Ics], Line, Tlen, _, _) when C >= 48, C =< 57 ->
    yystate(30, Ics, Line, Tlen+1, 2, Tlen);
yystate(30, [C|Ics], Line, Tlen, _, _) when C >= 65, C =< 90 ->
    yystate(30, Ics, Line, Tlen+1, 2, Tlen);
yystate(30, [C|Ics], Line, Tlen, _, _) when C >= 97, C =< 122 ->
    yystate(30, Ics, Line, Tlen+1, 2, Tlen);
yystate(30, Ics, Line, Tlen, _, _) ->
    {2,Tlen,Ics,Line,30};
yystate(29, Ics, Line, Tlen, _, _) ->
    {10,Tlen,Ics,Line};
yystate(28, Ics, Line, Tlen, _, _) ->
    {3,Tlen,Ics,Line};
yystate(27, [123|Ics], Line, Tlen, _, _) ->
    yystate(23, Ics, Line, Tlen+1, 5, Tlen);
yystate(27, [94|Ics], Line, Tlen, _, _) ->
    yystate(8, Ics, Line, Tlen+1, 5, Tlen);
yystate(27, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(12, Ics, Line, Tlen+1, 5, Tlen);
yystate(27, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 93 ->
    yystate(12, Ics, Line, Tlen+1, 5, Tlen);
yystate(27, [C|Ics], Line, Tlen, _, _) when C >= 95, C =< 122 ->
    yystate(12, Ics, Line, Tlen+1, 5, Tlen);
yystate(27, [C|Ics], Line, Tlen, _, _) when C >= 124 ->
    yystate(12, Ics, Line, Tlen+1, 5, Tlen);
yystate(27, Ics, Line, Tlen, _, _) ->
    {5,Tlen,Ics,Line,27};
yystate(26, [61|Ics], Line, Tlen, _, _) ->
    yystate(22, Ics, Line, Tlen+1, 14, Tlen);
yystate(26, Ics, Line, Tlen, _, _) ->
    {14,Tlen,Ics,Line,26};
yystate(25, Ics, Line, Tlen, _, _) ->
    {11,Tlen,Ics,Line};
yystate(24, [92|Ics], Line, Tlen, _, _) ->
    yystate(20, Ics, Line, Tlen+1, 3, Tlen);
yystate(24, [34|Ics], Line, Tlen, _, _) ->
    yystate(28, Ics, Line, Tlen+1, 3, Tlen);
yystate(24, [10|Ics], Line, Tlen, _, _) ->
    yystate(32, Ics, Line+1, Tlen+1, 3, Tlen);
yystate(24, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(32, Ics, Line, Tlen+1, 3, Tlen);
yystate(24, [C|Ics], Line, Tlen, _, _) when C >= 11, C =< 33 ->
    yystate(32, Ics, Line, Tlen+1, 3, Tlen);
yystate(24, [C|Ics], Line, Tlen, _, _) when C >= 35, C =< 91 ->
    yystate(32, Ics, Line, Tlen+1, 3, Tlen);
yystate(24, [C|Ics], Line, Tlen, _, _) when C >= 93 ->
    yystate(32, Ics, Line, Tlen+1, 3, Tlen);
yystate(24, Ics, Line, Tlen, _, _) ->
    {3,Tlen,Ics,Line,24};
yystate(23, [79|Ics], Line, Tlen, _, _) ->
    yystate(19, Ics, Line, Tlen+1, 5, Tlen);
yystate(23, Ics, Line, Tlen, _, _) ->
    {5,Tlen,Ics,Line,23};
yystate(22, Ics, Line, Tlen, _, _) ->
    {15,Tlen,Ics,Line};
yystate(21, Ics, Line, Tlen, _, _) ->
    {8,Tlen,Ics,Line};
yystate(20, [94|Ics], Line, Tlen, Action, Alen) ->
    yystate(16, Ics, Line, Tlen+1, Action, Alen);
yystate(20, [93|Ics], Line, Tlen, Action, Alen) ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(20, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(20, Ics, Line, Tlen+1, Action, Alen);
yystate(20, [34|Ics], Line, Tlen, Action, Alen) ->
    yystate(24, Ics, Line, Tlen+1, Action, Alen);
yystate(20, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(32, Ics, Line+1, Tlen+1, Action, Alen);
yystate(20, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(20, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 33 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(20, [C|Ics], Line, Tlen, Action, Alen) when C >= 35, C =< 91 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(20, [C|Ics], Line, Tlen, Action, Alen) when C >= 95 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(20, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,20};
yystate(19, [125|Ics], Line, Tlen, Action, Alen) ->
    yystate(15, Ics, Line, Tlen+1, Action, Alen);
yystate(19, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,19};
yystate(18, [60|Ics], Line, Tlen, _, _) ->
    yystate(14, Ics, Line, Tlen+1, 12, Tlen);
yystate(18, Ics, Line, Tlen, _, _) ->
    {12,Tlen,Ics,Line,18};
yystate(17, Ics, Line, Tlen, _, _) ->
    {6,Tlen,Ics,Line};
yystate(16, [92|Ics], Line, Tlen, Action, Alen) ->
    yystate(20, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [34|Ics], Line, Tlen, Action, Alen) ->
    yystate(24, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [10|Ics], Line, Tlen, Action, Alen) ->
    yystate(32, Ics, Line+1, Tlen+1, Action, Alen);
yystate(16, [C|Ics], Line, Tlen, Action, Alen) when C >= 0, C =< 9 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [C|Ics], Line, Tlen, Action, Alen) when C >= 11, C =< 33 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [C|Ics], Line, Tlen, Action, Alen) when C >= 35, C =< 91 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(16, [C|Ics], Line, Tlen, Action, Alen) when C >= 93 ->
    yystate(32, Ics, Line, Tlen+1, Action, Alen);
yystate(16, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,16};
yystate(15, [123|Ics], Line, Tlen, Action, Alen) ->
    yystate(11, Ics, Line, Tlen+1, Action, Alen);
yystate(15, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,15};
yystate(14, Ics, Line, Tlen, _, _) ->
    {16,Tlen,Ics,Line};
yystate(13, Ics, Line, Tlen, _, _) ->
    {18,Tlen,Ics,Line};
yystate(12, Ics, Line, Tlen, _, _) ->
    {5,Tlen,Ics,Line};
yystate(11, [79|Ics], Line, Tlen, Action, Alen) ->
    yystate(7, Ics, Line, Tlen+1, Action, Alen);
yystate(11, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,11};
yystate(10, [62|Ics], Line, Tlen, _, _) ->
    yystate(6, Ics, Line, Tlen+1, 13, Tlen);
yystate(10, Ics, Line, Tlen, _, _) ->
    {13,Tlen,Ics,Line,10};
yystate(9, [62|Ics], Line, Tlen, _, _) ->
    yystate(13, Ics, Line, Tlen+1, 7, Tlen);
yystate(9, Ics, Line, Tlen, _, _) ->
    {7,Tlen,Ics,Line,9};
yystate(8, [C|Ics], Line, Tlen, _, _) when C >= 0, C =< 9 ->
    yystate(12, Ics, Line, Tlen+1, 5, Tlen);
yystate(8, [C|Ics], Line, Tlen, _, _) when C >= 11 ->
    yystate(12, Ics, Line, Tlen+1, 5, Tlen);
yystate(8, Ics, Line, Tlen, _, _) ->
    {5,Tlen,Ics,Line,8};
yystate(7, [125|Ics], Line, Tlen, Action, Alen) ->
    yystate(3, Ics, Line, Tlen+1, Action, Alen);
yystate(7, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,7};
yystate(6, Ics, Line, Tlen, _, _) ->
    {17,Tlen,Ics,Line};
yystate(5, Ics, Line, Tlen, _, _) ->
    {9,Tlen,Ics,Line};
yystate(4, [125|Ics], Line, Tlen, Action, Alen) ->
    yystate(12, Ics, Line, Tlen+1, Action, Alen);
yystate(4, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,4};
yystate(3, [123|Ics], Line, Tlen, Action, Alen) ->
    yystate(0, Ics, Line, Tlen+1, Action, Alen);
yystate(3, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,3};
yystate(2, Ics, Line, Tlen, _, _) ->
    {20,Tlen,Ics,Line};
yystate(1, [C|Ics], Line, Tlen, _, _) when C >= 48, C =< 57 ->
    yystate(1, Ics, Line, Tlen+1, 0, Tlen);
yystate(1, Ics, Line, Tlen, _, _) ->
    {0,Tlen,Ics,Line,1};
yystate(0, [79|Ics], Line, Tlen, Action, Alen) ->
    yystate(4, Ics, Line, Tlen+1, Action, Alen);
yystate(0, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,0};
yystate(S, Ics, Line, Tlen, Action, Alen) ->
    {Action,Alen,Tlen,Ics,Line,S}.

%% yyaction(Action, TokenLength, TokenChars, TokenLine) ->
%% {token,Token} | {end_token, Token} | skip_token | {error,String}.
%% Generated action function.

yyaction(0, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_0(TokenChars, TokenLine);
yyaction(1, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_1(TokenChars, TokenLine);
yyaction(2, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_2(TokenChars, TokenLine);
yyaction(3, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_3(TokenChars, TokenLen, TokenLine);
yyaction(4, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_4(TokenChars, TokenLen, TokenLine);
yyaction(5, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_5(TokenChars, TokenLine);
yyaction(6, _, _, TokenLine) ->
    yyaction_6(TokenLine);
yyaction(7, _, _, TokenLine) ->
    yyaction_7(TokenLine);
yyaction(8, _, _, TokenLine) ->
    yyaction_8(TokenLine);
yyaction(9, _, _, TokenLine) ->
    yyaction_9(TokenLine);
yyaction(10, _, _, TokenLine) ->
    yyaction_10(TokenLine);
yyaction(11, _, _, TokenLine) ->
    yyaction_11(TokenLine);
yyaction(12, _, _, TokenLine) ->
    yyaction_12(TokenLine);
yyaction(13, _, _, TokenLine) ->
    yyaction_13(TokenLine);
yyaction(14, _, _, TokenLine) ->
    yyaction_14(TokenLine);
yyaction(15, _, _, TokenLine) ->
    yyaction_15(TokenLine);
yyaction(16, _, _, TokenLine) ->
    yyaction_16(TokenLine);
yyaction(17, _, _, TokenLine) ->
    yyaction_17(TokenLine);
yyaction(18, _, _, TokenLine) ->
    yyaction_18(TokenLine);
yyaction(19, TokenLen, YYtcs, TokenLine) ->
    TokenChars = yypre(YYtcs, TokenLen),
    yyaction_19(TokenChars, TokenLine);
yyaction(20, _, _, TokenLine) ->
    yyaction_20(TokenLine);
yyaction(21, _, _, _) ->
    yyaction_21();
yyaction(_, _, _, _) -> error.

-compile({inline,yyaction_0/2}).
-file("src/rivus_cep_scanner.xrl", 11).
yyaction_0(TokenChars, TokenLine) ->
     { token, { integer, TokenLine, list_to_integer (TokenChars) } } .

-compile({inline,yyaction_1/2}).
-file("src/rivus_cep_scanner.xrl", 13).
yyaction_1(TokenChars, TokenLine) ->
     Atom = list_to_atom (TokenChars),
     { token, case reserved_word (Atom) of
     true -> case Atom of
     'end' -> { end_token, { 'end', TokenLine } } ;
     _ -> { Atom, TokenLine }
     end ;
     false -> { atom, TokenLine, Atom }
     end } .

-compile({inline,yyaction_2/2}).
-file("src/rivus_cep_scanner.xrl", 22).
yyaction_2(TokenChars, TokenLine) ->
     { token, { var, TokenLine, list_to_atom (TokenChars) } } .

-compile({inline,yyaction_3/3}).
-file("src/rivus_cep_scanner.xrl", 26).
yyaction_3(TokenChars, TokenLen, TokenLine) ->
     S = lists : sublist (TokenChars, 2, TokenLen - 2),
     { token, { string, TokenLine, S } } .

-compile({inline,yyaction_4/3}).
-file("src/rivus_cep_scanner.xrl", 30).
yyaction_4(TokenChars, TokenLen, TokenLine) ->
     S = lists : sublist (TokenChars, 2, TokenLen - 2),
     { token, { string, TokenLine, S } } .

-compile({inline,yyaction_5/2}).
-file("src/rivus_cep_scanner.xrl", 34).
yyaction_5(TokenChars, TokenLine) ->
     { token, { char, TokenLine, cc_convert (TokenChars) } } .

-compile({inline,yyaction_6/1}).
-file("src/rivus_cep_scanner.xrl", 35).
yyaction_6(TokenLine) ->
     { token, { '+', TokenLine } } .

-compile({inline,yyaction_7/1}).
-file("src/rivus_cep_scanner.xrl", 36).
yyaction_7(TokenLine) ->
     { token, { '-', TokenLine } } .

-compile({inline,yyaction_8/1}).
-file("src/rivus_cep_scanner.xrl", 37).
yyaction_8(TokenLine) ->
     { token, { '*', TokenLine } } .

-compile({inline,yyaction_9/1}).
-file("src/rivus_cep_scanner.xrl", 38).
yyaction_9(TokenLine) ->
     { token, { '/', TokenLine } } .

-compile({inline,yyaction_10/1}).
-file("src/rivus_cep_scanner.xrl", 39).
yyaction_10(TokenLine) ->
     { token, { '(', TokenLine } } .

-compile({inline,yyaction_11/1}).
-file("src/rivus_cep_scanner.xrl", 40).
yyaction_11(TokenLine) ->
     { token, { ')', TokenLine } } .

-compile({inline,yyaction_12/1}).
-file("src/rivus_cep_scanner.xrl", 41).
yyaction_12(TokenLine) ->
     { token, { '=', TokenLine } } .

-compile({inline,yyaction_13/1}).
-file("src/rivus_cep_scanner.xrl", 42).
yyaction_13(TokenLine) ->
     { token, { '<', TokenLine } } .

-compile({inline,yyaction_14/1}).
-file("src/rivus_cep_scanner.xrl", 43).
yyaction_14(TokenLine) ->
     { token, { '>', TokenLine } } .

-compile({inline,yyaction_15/1}).
-file("src/rivus_cep_scanner.xrl", 44).
yyaction_15(TokenLine) ->
     { token, { '>=', TokenLine } } .

-compile({inline,yyaction_16/1}).
-file("src/rivus_cep_scanner.xrl", 45).
yyaction_16(TokenLine) ->
     { token, { '<=', TokenLine } } .

-compile({inline,yyaction_17/1}).
-file("src/rivus_cep_scanner.xrl", 46).
yyaction_17(TokenLine) ->
     { token, { '<>', TokenLine } } .

-compile({inline,yyaction_18/1}).
-file("src/rivus_cep_scanner.xrl", 47).
yyaction_18(TokenLine) ->
     { token, { '->', TokenLine } } .

-compile({inline,yyaction_19/2}).
-file("src/rivus_cep_scanner.xrl", 50).
yyaction_19(TokenChars, TokenLine) ->
     { token, { list_to_atom (TokenChars), TokenLine } } .

-compile({inline,yyaction_20/1}).
-file("src/rivus_cep_scanner.xrl", 51).
yyaction_20(TokenLine) ->
     { end_token, { semicolon, TokenLine } } .

-compile({inline,yyaction_21/0}).
-file("src/rivus_cep_scanner.xrl", 52).
yyaction_21() ->
     skip_token .

-file("/usr/local/lib/erlang/lib/parsetools-2.0.11/include/leexinc.hrl", 282).
