%%--------------------------------------------------------------------
%% Copyright (c) 2013-2018 EMQ Enterprise, Inc. (http://emqtt.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_auth_http_cli).

-include_lib("emqx/include/emqx.hrl").

-export([request/5, feedvar/2, feedvar/3]).

%%--------------------------------------------------------------------
%% HTTP Request
%%--------------------------------------------------------------------

request(Method, Url, Params, Headers, _Opts = #{body_type := 'query'}) ->
    reply(httpc:request(Method, query_string(Url, Params, Headers), [{autoredirect, true}], []));
request(Method, Url, Params, Headers, _Opts = #{body_type := urlencoded}) ->
    reply(httpc:request(Method, url_encoded(Url, Params, Headers), [{autoredirect, true}], []));
request(Method, Url, Body, Headers, _Opts = #{body_type := json}) ->
    reply(httpc:request(Method, json_encoded(Url, Body, Headers), [{autoredirect, true}], []));
request(Method, Url, Body, Headers, _Opts = #{body_type := ril}) ->
    reply(httpc:request(Method, ril_encoded(Url, Body, Headers), [{autoredirect, true}], [])).

query_string(Url, Params, Headers) ->
    {Url ++ "?" ++ mochiweb_util:urlencode(Params), Headers}.
url_encoded(Url, Params, Headers) ->
    {Url, Headers, "application/x-www-form-urlencoded", mochiweb_util:urlencode(Params)}.
json_encoded(Url, BodyParams, Headers) ->
    {Url, Headers, "application/json", jsx:encode(BodyParams)}.
ril_encoded(Url, Body, Headers) ->
    {Url, Headers, "application/json", Body}.

reply({ok, {{_, Code, _}, _Headers, Body}}) ->
    {ok, Code, Body};
reply({ok, Code, Body}) ->
    {ok, Code, Body};
reply({error, Error}) ->
    {error, Error}.

%%--------------------------------------------------------------------
%% Feed Variables
%%--------------------------------------------------------------------

feedvar(Params, #mqtt_client{username = Username, client_id = ClientId, peername = {IpAddr, _}}) ->
    lists:map(fun({Param, <<"%u">>}) -> {Param, Username};
                 ({Param, <<"%c">>}) -> {Param, ClientId};
                 ({Param, <<"%a">>}) -> {Param, inet:ntoa(IpAddr)};
                 (Param)         -> Param
              end, Params).

feedvar(Params, Var, Val) ->
    lists:map(fun({Param, Var0}) when Var0 == Var -> {Param, Val}; (Param) -> Param end, Params).