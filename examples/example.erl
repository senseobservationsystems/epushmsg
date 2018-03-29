-module(example).
-export([ex1/0]).

-include("epushmsg.hrl").

%% example of sending a push notification to a specific user
%% returns status code (200 if successful)
-spec ex1() -> integer().
ex1() ->
    hackney:start(),
    PushMsgParams = epushmsg:new_params(),
    Audience = epushmsg:new_androidChannel(<<"CHANGE ME">>),
    Alert = epushmsg:new_alert(<<"You got alert!">>),
    Payload = epushmsg:new_payload(Audience, Alert, android),

    PushMsgParams2 = PushMsgParams#pushmsg_params{payload=Payload},
    epushmsg:push(PushMsgParams2).
