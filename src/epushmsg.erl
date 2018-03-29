%% -*- erlang-indent-level: 4; indent-tabs-mode: nil; fill-column: 80 -*-
%%% Copyright 2012 Erlware, LLC. All Rights Reserved.
%%%
%%% This file is provided to you under the Apache License,
%%% Version 2.0 (the "License"); you may not use this file
%%% except in compliance with the License.  You may obtain
%%% a copy of the License at
%%%
%%%   http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing,
%%% software distributed under the License is distributed on an
%%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%%% KIND, either express or implied.  See the License for the
%%% specific language governing permissions and limitations
%%% under the License.
%%%---------------------------------------------------------------------------
%%% @author Jordan Wilberding <jwilberding@gmail.com>
%%% @copyright (C) 2013 Erlware, LLC.
%%%
%%% @doc
%%%  An Erlang API for Urban Airship mobile push notifications
%%% @end

-module(epushmsg).

-export([new_params/0,
         new_params/2,
         new_params/3,
         new_payload/3,
         new_alert/1,
         new_androidChannel/1,
         push/1]).

-include("epushmsg.hrl").

-include_lib("hackney/include/hackney.hrl").

-define(DEFAULT_URL, <<"https://go.urbanairship.com/api">>).
-define(DEFAULT_KEY,<<"CHANGEME">>).
-define(DEFAULT_SECRET, <<"CHANGEME">>).

%%%===================================================================
%%% New record functions
%%%===================================================================

-spec new_params() -> pushmsg_params.
new_params() ->
    {ok, URL} = with_default(application:get_env(epushmsg, url), ?DEFAULT_URL),
    {ok, Key} = with_default(application:get_env(epushmsg, key), ?DEFAULT_KEY),
    {ok, Secret} = with_default(application:get_env(epushmsg, secret),
                                ?DEFAULT_SECRET),
    #pushmsg_params{url=URL, key=Key, secret=Secret}.

-spec new_params(binary(), binary()) -> pushmsg_params.
new_params(Secret, Key) ->
    {ok, URL} = with_default(application:get_env(epushmsg, url), ?DEFAULT_URL),
    #pushmsg_params{url=URL, key=Key, secret=Secret}.

-spec new_params(binary(), binary(), binary()) -> pushmsg_params.
new_params(URL, Secret, Key) ->
    #pushmsg_params{url=URL, key=Key, secret=Secret}.

new_payload(Audience, Notification, DeviceType) ->
    #pushmsg_payload{audience=Audience, notification=Notification, device_type=DeviceType}.

new_alert(Alert) ->
    #pushmsg_alert{alert=Alert}.

new_androidChannel(AndroidChannel) ->
    #pushmsg_androidChannel{androidChannel=AndroidChannel}.

%%%===================================================================
%%% Charge functions
%%%===================================================================

decode_audience(#pushmsg_androidChannel{androidChannel=AndroidChannel}) ->
    {android_channel, AndroidChannel}.

decode_notification(#pushmsg_alert{alert=Alert}) ->
    {alert, Alert}.

-spec push(pushmsg_params) -> integer().
push(#pushmsg_params{url=URL, key=Key, secret=Secret, payload=#pushmsg_payload{audience=Audience, notification=Notification, device_type=DeviceType}}) ->
    Method = post,
    URL2 = hackney_url:parse_url(<<URL/binary, <<"/push/">>/binary >> ),
    URL3 = URL2#hackney_url{user=Key, password=Secret},
    Headers = [{<<"Content-type">>, <<"application/json">>}],
    Options = [],
    PayloadJSON = {[{audience, {[decode_audience(Audience)]}},
                    {notification, {[decode_notification(Notification)]}},
                    {device_types, [DeviceType]}]},

    {ok, StatusCode, _RespHeaders, _Client} = hackney:request(Method, URL3,
                                                            Headers, jiffy:encode(PayloadJSON),
                                                            Options),
    StatusCode.


%%%===================================================================
%%% Local helper functions
%%%===================================================================

-spec with_default(any(), any()) -> any().
with_default(X, Y) ->
    case X of
        undefined ->
            {ok, Y};
        _ ->
            X
    end.
