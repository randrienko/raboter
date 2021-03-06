-module(raboter).

-export([start/0]).

-define(TOKEN, "<YOUR TOKEN>").
-define(BASE_URL, "https://api.telegram.org/bot" ++ ?TOKEN).
-define(GET_COMMAND_URL, ?BASE_URL ++ "/getUpdates?offset=").
-define(SET_COMMAND_URL, ?BASE_URL ++ "/sendMessage").


start() ->
	io:format("---Start bot---~n"),
	inets:start(),
	ssl:start(),
	command_handler(?GET_COMMAND_URL, 0).


command_handler(Url, UpdateId) ->
	Response = parse_response(get_command(Url ++ integer_to_list(UpdateId + 1))),
	{JsonObj} = jiffy:decode(Response),
	Result = proplists:get_value(<<"result">>, JsonObj, []),
	case Result of
		[{[{<<"update_id">>, NewUpdateId}, {<<"message">>, {Message}} |_]}] -> 
			{From} = proplists:get_value(<<"from">>, Message),
			ChatID = proplists:get_value(<<"id">>, From),
			Command = proplists:get_value(<<"text">>, Message),
			run_command(ChatID, binary_to_list(Command));
		[] -> 
			NewUpdateId = UpdateId,
			io:format("~w~n", [empty])
	end,
	timer:sleep(3000),
	command_handler(Url, NewUpdateId).

send_message(ChatID, Text) ->
	set_command(?SET_COMMAND_URL, "chat_id=" ++ integer_to_list(ChatID) ++ "&text=" ++ Text).

get_command(Url) ->	
	request(get, {Url, []}).

set_command(Url, Data) -> 
	Response = request(post, {Url, [], "application/x-www-form-urlencoded", Data}),
	{ok, {{"HTTP/1.1",ReturnCode, State}, Head, Body}} = Response,
	io:format("~w / ~w~n", [ReturnCode, State]).

request(Method, Body) ->
    httpc:request(Method, Body, [{ssl,[{verify,0}]}], []).

parse_response({ok, { _, _, Body}}) ->
	 Body.

terminate() ->
	ssl:stop(),
	inets:stop().


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You can expand the list of commands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

run_command(ChatID, "test") -> 
	send_message(ChatID, "Test message");

run_command(ChatID, "/help") -> 
	send_message(ChatID, "Help text");

run_command(ChatID, _) ->
	send_message(ChatID, "Command not found").