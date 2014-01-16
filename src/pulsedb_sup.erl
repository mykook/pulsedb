-module(pulsedb_sup).
-export([start_link/0, stop/0, init/1]).
-export([start_collector/3]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_collector(Name, Module, Args) ->
  Spec = {Name, {pulsedb_collector, start_link, [Name, Module, Args]}, transient, 200, worker, []},
  case supervisor:start_child(pulsedb_collectors, Spec) of
    {ok, Pid} -> {ok, Pid};
    {error, already_present} -> supervisor:restart_child(pulsedb_collectors, Name);
    {error, {already_started, Pid}} -> {ok, Pid}
  end.



stop() ->
  erlang:exit(erlang:whereis(?MODULE), shutdown).

init([pulsedb_collectors]) ->
  {ok, {{one_for_one, 5, 10}, []}};


init([]) ->
  Supervisors = [
    {pulsedb_memory, {pulsedb_memory, start_link, []}, permanent, 100, worker, []},
    {pulsedb_collectors, {supervisor, start_link, [{local,pulsedb_collectors}, ?MODULE, [pulsedb_collectors]]}, permanent, infinity, supervisor, []},
    {pulsedb_repeater, {pulsedb_repeater, start_link, []}, permanent, 100, worker, []}
  ],
  {ok, {{one_for_one, 10, 10}, Supervisors}}.
