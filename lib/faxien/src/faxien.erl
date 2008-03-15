%%-------------------------------------------------------------------
%%% @doc This is the UI for Faxien. Application programmers should use the lower level API's provided by other faxien modules
%%% in most cases.  This module encapsulates many of the side effects and configuration that makes the faxien commandline 
%%% application behave in the way it should.  Most functions within are intended to be called from the command line. This means 
%%% that they will be wrapped by fax_cmdln:faxien_apply. Note that all exported functions contained within should return 
%%% ok | {ok, Value} in the correct case and {error, Reason} or an exception in the error case.  The exception to these rules 
%%% are exported functions that are not to be called from the commandline. 
%%%
%%% Types:
%%%  @type repo() = string(). Contains domain and repo root. 
%%%   Example: http://www.erlware.org/stable   
%%%  @type repo_suffix() = string(). Contains ErtsVsn/Area/Application/Vsn/TarFile.
%%%  @type timeout() = integer() | infinity. Timeouts are specified in milliseconds.
%%%
%%% @author Martin Logan
%%% @copyright 2007 Erlware
%%% @end
%%%-------------------------------------------------------------------
-module(faxien).

%%--------------------------------------------------------------------
%% Include files
%%--------------------------------------------------------------------
-include("faxien.hrl").

%%--------------------------------------------------------------------
%% External exports
%%--------------------------------------------------------------------
-export([
	 install_app/3,
	 install_app/2,
	 install_app/1,
	 fetch_app/4,
	 fetch_app/3,
	 fetch_app/2,
	 fetch_release/4,
	 fetch_release/3,
	 fetch_release/2,
	 install_release/3,
	 install_release/2,
	 install_release/1
	]).

-export([
	 search/4,
	 search/2,
	 search/1,
	 search/0,

	 describe_release/2,
	 describe_release/1,
	 describe_app/2,
	 describe_app/1,

	 installed/1,
	 installed/0,

	 remove_repo/1,
	 add_repo/1,
	 show_repos/0,
	 add_publish_repo/1,
	 remove_publish_repo/1,
	 show_publish_repos/0,
	 set_request_timeout/1,
	 show_target_erts_vsn/0,
	 set_target_erts_vsn/1,
	 show_request_timeout/0,
	 environment/0,
	 environment_help/0,

	 help/0,
	 help/1,
	 version/0,

	 remove_release/1, 
	 remove_release/2,

	 remove_app/1, 
	 remove_app/2
	]).

-export([
	 publish/3,
	 publish/2,
	 publish/1
	]).

-export([
	 outdated_apps/1,
	 outdated_apps/0,
	 outdated_releases/1,
	 outdated_releases/0,
	 upgrade_all_releases/1,
	 upgrade_all_releases/0,
	 upgrade_release/2,
	 upgrade_release/1,
	 upgrade_all_apps/1,
	 upgrade_all_apps/0,
	 upgrade_app/2,
	 upgrade_app/1
	]).

-export([
	 outdated_release_help/0,
	 outdated_apps_help/0,
	 examples_help/0,
	 commands_help/0,
	 set_request_timeout_help/0,
	 show_request_timeout_help/0,
	 set_target_erts_vsn_help/0,
	 show_target_erts_vsn_help/0,
	 add_publish_repo_help/0,
	 remove_publish_repo_help/0,
	 show_publish_repos_help/0,
	 remove_repo_help/0,
	 add_repo_help/0,
	 show_repos_help/0,
	 upgrade_app_help/0,
	 upgrade_all_apps_help/0,
	 upgrade_release_help/0,
	 upgrade_all_releases_help/0,
	 install_release_help/0,
	 install_app_help/0,
	 fetch_app_help/0,
	 fetch_release_help/0,
	 publish_help/0,
	 search_help/0,
	 installed_help/0,
	 describe_release_help/0,
	 describe_app_help/0,
	 remove_release_help/0,
	 remove_app_help/0
	]).

%%--------------------------------------------------------------------
%% Macros
%%--------------------------------------------------------------------

%% Absolute default settings.  Configs override these. 
-define(ERLWARE_URL, "http://repo.erlware.org/pub").
-define(REQUEST_TIMEOUT, 120000).
-define(IS_LOCAL_BOOT, false).

			

%%====================================================================
%% External functions
%%====================================================================

%%--------------------------------------------------------------------
%% @doc upgrade a single application.
%% <pre>
%% Examples:
%%  upgrade_app(["http://erlware.org/stable", "http://erlwaremirror.org/stable"], faxien, "usr/local/erlware").
%% or
%%  upgrade_app('http://erlware.org/stable', faxien, "usr/local/erlware").
%% </pre>
%% @spec upgrade_app(Repos, AppName) -> ok | {error, Reason}
%%  where
%%   Repos = [string()] | atom()
%%   AppName = string() | atom()
%% @end
%%--------------------------------------------------------------------
upgrade_app(Repo, AppName) when is_atom(Repo) -> 
    upgrade_app([atom_to_list(Repo)], AppName);
upgrade_app(Repos, AppName) -> 
    A = epkg_util:if_atom_or_integer_to_string(AppName),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_manage:upgrade_application(Repos, TargetErtsVsn, A, false, ?REQUEST_TIMEOUT).

%% @spec upgrade_app(AppName) -> ok | {error, Reason}
%% @equiv upgrade_app(Repos, AppName)
upgrade_app(AppName) -> 
    {ok, Repos}            = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    upgrade_app(Repos, AppName).

    
%% @private
upgrade_app_help() ->
    ["\nHelp for upgrade-app\n",
     "upgrade-app <app name>: will upgrade an installed application"]. 

    

%%--------------------------------------------------------------------
%% @doc upgrade a all installed applications.
%% <pre>
%% Examples:
%%  upgrade_all_apps(["http://erlware.org/stable", "http://erlwaremirror.org/stable"]).
%% or
%%  upgrade_all_apps('http://erlware.org/stable', "usr/local/erlware").
%% </pre>
%% @spec upgrade_all_apps(Repos) -> ok | {error, Reason}
%%  where
%%   Repos = [string()] | atom()
%% @end
%%--------------------------------------------------------------------
upgrade_all_apps(Repo) when is_atom(Repo) ->
    upgrade_all_apps([atom_to_list(Repo)]);
upgrade_all_apps(Repos) ->
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_manage:upgrade_applications(Repos, TargetErtsVsn, false, ?REQUEST_TIMEOUT).

upgrade_all_apps() -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    upgrade_all_apps(Repos).

%% @private
upgrade_all_apps_help() ->
    ["\nHelp for upgrade-all-apps\n",
     "upgrade-all-apps: will upgrade all installed applications"]. 


%%--------------------------------------------------------------------
%% @doc Display all currently installed releases that have available updates.
%% @spec outdated_releases(Repos)-> {ok, OutdatedReleases}
%%  where
%%   Repos = [repo] | repo()
%% @end
%%--------------------------------------------------------------------
outdated_releases(Repo) when is_atom(Repo) ->
    outdated_releases([atom_to_list(Repo)]);
outdated_releases(Repos) ->
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    lists:foreach(fun({Name, CurrentVsn, UpgradeVsn}) ->
			  io:format("The ~s release has an available upgrade from ~s to ~s~n", [Name, CurrentVsn, UpgradeVsn])
		  end, 
		  fax_manage:outdated_releases(Repos, TargetErtsVsn, ?REQUEST_TIMEOUT)).

%% @spec outdated_releases()-> {ok, OutdatedReleases}
%% @equiv outdated_releases(Repos)
outdated_releases() -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    outdated_releases(Repos).

%% @private
outdated_release_help() ->
    ["\nHelp for outdated-releases\n",
     "outdated-releases: will display all releases that have available updates"]. 

%%--------------------------------------------------------------------
%% @doc Display all currently installed applications that have available updates.
%% @spec outdated_apps(Repos)-> {ok, OutdatedApps}
%%  where
%%   Repos = [string()] | Repo
%% @end
%%--------------------------------------------------------------------
outdated_apps(Repo) when is_atom(Repo) ->
    outdated_apps([atom_to_list(Repo)]);
outdated_apps(Repos) ->
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    lists:foreach(fun({Name, CurrentVsn, UpgradeVsn}) ->
			  io:format("The ~s application has an available upgrade from ~s to ~s~n", [Name, CurrentVsn, UpgradeVsn])
		  end, 
		  fax_manage:outdated_applications(Repos, TargetErtsVsn, ?REQUEST_TIMEOUT)).

%% @spec outdated_apps()-> {ok, OutdatedApps}
%% @equiv outdated_apps(Repos)
outdated_apps() -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    outdated_apps(Repos).

%% @private
outdated_apps_help() ->
    ["\nHelp for outdated-apps\n",
     "outdated-apps: will display all applications that have available updates"]. 

%%--------------------------------------------------------------------
%% @doc upgrade a single release.
%% <pre>
%% Examples:
%%  upgrade_release(["http://erlware.org/stable", "http://erlwaremirror.org/stable"], faxien, "usr/local/erlware").
%% or
%%  upgrade_release('http://erlware.org/stable', faxien, "usr/local/erlware").
%% </pre>
%% @spec upgrade_release(Repos, RelName) -> ok | {error, Reason}
%%  where
%%   Repos = [string()] | atom()
%%   RelName = string() | atom()
%% @end
%%--------------------------------------------------------------------
upgrade_release(Repo, RelName) when is_atom(Repo) -> 
    upgrade_release([atom_to_list(Repo)], RelName);
upgrade_release(Repos, RelName) -> 
    A                 = epkg_util:if_atom_or_integer_to_string(RelName),
    {ok, IsLocalBoot} = gas:get_env(faxien, is_local_boot, ?IS_LOCAL_BOOT),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_manage:upgrade_release(Repos, TargetErtsVsn, A, IsLocalBoot, false, ?REQUEST_TIMEOUT).

%% @spec upgrade_release(RelName) -> ok | {error, Reason}
%% @equiv upgrade_release(Repos, RelName)
upgrade_release(RelName) -> 
    {ok, Repos}            = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    upgrade_release(Repos, RelName).

%% @private
upgrade_release_help() ->
    ["\nHelp for upgrade-release\n",
     "upgrade_release <release name>: will upgrade an installed release"]. 

%%--------------------------------------------------------------------
%% @doc upgrade_all a all installed releases.
%% <pre>
%% Examples:
%%  upgrade_all_releases(["http://erlware.org/stable", "http://erlwaremirror.org/stable"]).
%% or
%%  upgrade_all_releases('http://erlware.org/stable').
%% </pre>
%% @spec upgrade_all_releases(Repos) -> ok | {error, Reason}
%%  where
%%   Repos = [string()] | atom()
%% @end
%%--------------------------------------------------------------------
upgrade_all_releases(Repo) when is_atom(Repo) ->
    upgrade_all_releases([atom_to_list(Repo)]);
upgrade_all_releases(Repos) ->
    {ok, IsLocalBoot} = gas:get_env(faxien, is_local_boot, ?IS_LOCAL_BOOT),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_manage:upgrade_releases(Repos, TargetErtsVsn, IsLocalBoot, false, ?REQUEST_TIMEOUT).

%% @spec upgrade_all_releases() -> ok | {error, Reason}
%% @equiv upgrade_all_releases(Repos)
upgrade_all_releases() -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    upgrade_all_releases(Repos).

%% @private
upgrade_all_releases_help() ->
    ["\nHelp for upgrade-all-releases\n",
     "upgrade-all-releases: will upgrade_all all installed releases"]. 


%%--------------------------------------------------------------------
%% @doc 
%%  Install a release and all its applications from a repository. This function will pull down the release tarball for the 
%%  specified application unpack it, pull down all the applications specified by the included .rel file and finally build
%%  a local .boot file used for startup.  
%% @spec install_release(Repos, ReleaseName, ReleaseVsn) -> ok | {error, Reason}
%% where
%%     Repos = [string()] | [atom()] | atom()
%%     ReleaseName = string() | atom()
%%     ReleaseVsn = 'LATEST' | string() | atom()
%% @end
%%--------------------------------------------------------------------
install_release(Repos, ReleaseName, ReleaseVsn) when is_atom(Repos)  -> 
    install_release([atom_to_list(Repos)], ReleaseName, ReleaseVsn);
install_release(Repos, ReleaseName, ReleaseVsn)  -> 
    ?INFO_MSG("faxien:install_release(~p, ~p, ~p)~n", [Repos, ReleaseName, ReleaseVsn]),
    % Any atoms must be turned to strings.  Atoms are accepted because it makes
    % the invocation from the command line cleaner. 
    [A,B]                  = epkg_util:if_atom_or_integer_to_string([ReleaseName, ReleaseVsn]),
    {ok, IsLocalBoot}      = gas:get_env(faxien, is_local_boot, ?IS_LOCAL_BOOT),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_install:install_remote_release(Repos, TargetErtsVsn, A, B, IsLocalBoot, false, ?REQUEST_TIMEOUT).

%% @spec install_release(ReleaseName, ReleaseVsn) -> ok | {error, Reason}
%% @equiv install_release(ERLWARE, ReleaseName, ReleaseVsn)
install_release(ReleaseName, ReleaseVsn) -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    install_release(Repos, ReleaseName, ReleaseVsn).

%%--------------------------------------------------------------------
%% @doc 
%%  This function will determine if the release to be installed is a local release package or it is a package that must
%%  first be pulled down from a remote repo and pulled down.  If the package is local then it will be installed into the 
%%  configured location.  If the package is remote than the latest version of that package will be pulled down and installed. 
%%
%% @spec install_release(ReleaseNameOrPath) -> ok | {error, Reason}
%%  where
%%   ReleaseNameOrPath = atom() | string()
%% @end
%%--------------------------------------------------------------------
install_release(ReleaseNameOrPath) when is_atom(ReleaseNameOrPath) -> 
    install_release(atom_to_list(ReleaseNameOrPath));
install_release(ReleaseNameOrPath) -> 
    {ok, Repos}         = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    {ok, IsLocalBoot}   = gas:get_env(faxien, is_local_boot, ?IS_LOCAL_BOOT),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_install:install_release(Repos, TargetErtsVsn, ReleaseNameOrPath, IsLocalBoot, false, ?REQUEST_TIMEOUT).
	
    
%% @private
install_release_help() ->
    ["\nHelp for install-release\n",
     "Usage: install-release <release-name|release-tarball> [release-version]: will install a release remotely or from a local package depending on its argument\n"]. 

%%--------------------------------------------------------------------
%% @doc 
%%  Fetch a release and all its applications from a repository and place them into a specified directory. 
%%
%% @spec fetch_release(Repos, ReleaseName, ReleaseVsn, ToDir) -> ok | {error, Reason}
%% where
%%     Repos = [string()] | [atom()] | atom()
%%     ReleaseName = string() | atom()
%%     ReleaseVsn = 'LATEST' | string() | atom()
%% @end
%%--------------------------------------------------------------------
fetch_release(Repos, ReleaseName, ReleaseVsn, ToDir) when is_atom(Repos)  -> 
    fetch_release([atom_to_list(Repos)], ReleaseName, ReleaseVsn);
fetch_release(Repos, ReleaseName, ReleaseVsn, ToDir)  -> 
    ?INFO_MSG("faxien:fetch_release(~p, ~p, ~p)~n", [Repos, ReleaseName, ReleaseVsn]),
    % Any atoms must be turned to strings.  Atoms are accepted because it makes
    % the invocation from the command line cleaner. 
    [A,B,C]             = epkg_util:if_atom_or_integer_to_string([ReleaseName, ReleaseVsn, ToDir]),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_install:fetch_remote_release(Repos, TargetErtsVsn, A, B, C, ?REQUEST_TIMEOUT).

%% @spec fetch_release(ReleaseName, ReleaseVsn, ToDir) -> ok | {error, Reason}
%% @equiv fetch_release(ERLWARE, ReleaseName, ReleaseVsn, ToDir)
fetch_release(ReleaseName, ReleaseVsn, ToDir) -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    fetch_release(Repos, ReleaseName, ReleaseVsn, ToDir).

%%--------------------------------------------------------------------
%% @doc 
%%  Fetch the latest version of a release and all its applications from a repository and place them in a specified directory. 
%%
%% @spec fetch_release(ReleaseNameOrPath, ToDir) -> ok | {error, Reason}
%%  where
%%   ReleaseNameOrPath = atom() | string()
%% @end
%%--------------------------------------------------------------------
fetch_release(ReleaseName, ToDir) -> 
    {ok, Repos}         = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    [A,B]               = epkg_util:if_atom_or_integer_to_string([ReleaseName, ToDir]),
    fax_install:fetch_latest_remote_release(Repos, TargetErtsVsn, A, B, ?REQUEST_TIMEOUT).
	
    
%% @private
fetch_release_help() ->
    ["\nHelp for fetch-release\n",
     "Usage: fetch_release <release-name> [release version] <to-dir>: will fetch a release package and place it in the specifie directory"]. 


%%--------------------------------------------------------------------
%% @doc 
%%  Install an application from a repository.
%% <pre>
%% Examples:
%%  install_app(["http"//www.erlware.org/pub"], gas, "4.6.0")
%%  install_app(["http"//www.erlware.org/pub"], gas, "LATEST")
%% </pre>
%% @spec install_app(Repos, AppName, AppVsn) -> ok | {error, Reason}
%% where
%%     Repos = [string()] | [atom()] | atom()
%%     AppName = string() | atom()
%%     AppVsn = 'LATEST' | string() | atom()
%% @end
%%--------------------------------------------------------------------
install_app(Repos, AppName, AppVsn) when is_atom(Repos)  -> 
    install_app([atom_to_list(Repos)], AppName, AppVsn);
install_app(Repos, AppName, AppVsn)  -> 
    % Any atoms must be turned to strings.  Atoms are accepted because it makes
    % the invocation from the command line cleaner. 
    [A,B]         = epkg_util:if_atom_or_integer_to_string([AppName, AppVsn]),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_install:install_remote_application(Repos, TargetErtsVsn, A, B, false, ?REQUEST_TIMEOUT).

%% @spec install_app(AppName, AppVsn) -> ok | {error, Reason}
%% @equiv install_app(ERLWARE, AppName, AppVsn)
install_app(AppName, AppVsn) -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    install_app(Repos, AppName, AppVsn).

%%--------------------------------------------------------------------
%% @doc 
%%  This function will determine if the application to be installed is a local release package or it is a package that must
%%  first be pulled down from a remote repo and pulled down.  If the package is local then it will be installed into the 
%%  configured location.  If the package is remote than the latest version of that package will be pulled down and installed. 
%%
%% @spec install_app(AppNameOrPath) -> ok | {error, Reason}
%%  where
%%   AppNameOrPath = atom() | string()
%% @end
%%--------------------------------------------------------------------
install_app(AppNameOrPath) when is_atom(AppNameOrPath) -> 
    install_app(atom_to_list(AppNameOrPath));
install_app(AppNameOrPath) -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    case filelib:is_file(AppNameOrPath) of
	true  -> 
	    AppDirPath = epkg_util:unpack_to_tmp_if_archive(AppNameOrPath),
	    case fax_util:get_erts_vsn(AppDirPath) of
		{ok, ErtsVsn} ->
		    epkg:install_app(AppDirPath, ErtsVsn);
		_ ->
		    io:format("Could not find an erts vsn for the app you are trying to install."),
		    {error, wrong_erts_vsn}
	    end;
	false -> 
	    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
	    fax_install:install_latest_remote_application(Repos, TargetErtsVsn, AppNameOrPath, false, ?REQUEST_TIMEOUT)
    end.

%% @private
install_app_help() ->
    ["\nHelp for install-app\n",
     "Usage: install-app <app name|app tarball> [app version]: will install an OTP app remotely or from a local package depending on its argument\n"]. 


%%--------------------------------------------------------------------
%% @doc 
%%  Fetch an application from a repository and place it into the specified directory
%% <pre>
%% Examples:
%%  fetch_app(["http"//www.erlware.org/pub"], gas, "./")
%% </pre>
%% @spec fetch_app(Repos, AppName, AppVsn, ToDir) -> ok | {error, Reason}
%% where
%%     Repos = [string()] | [atom()] | atom()
%%     AppName = string() | atom()
%%     AppVsn = 'LATEST' | string() | atom()
%%     ToDir = string() | atom()
%% @end
%%--------------------------------------------------------------------
fetch_app(Repos, AppName, AppVsn, ToDir) when is_atom(Repos)  -> 
    fetch_app([atom_to_list(Repos)], AppName, AppVsn, ToDir);
fetch_app(Repos, AppName, AppVsn, ToDir)  -> 
    % Any atoms must be turned to strings.  Atoms are accepted because it makes
    % the invocation from the command line cleaner. 
    [A,B,C]         = epkg_util:if_atom_or_integer_to_string([AppName, AppVsn, ToDir]),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    fax_install:fetch_remote_application(Repos, TargetErtsVsn, A, B, C, ?REQUEST_TIMEOUT).

%% @spec fetch_app(AppName, AppVsn, ToDir) -> ok | {error, Reason}
%% @equiv fetch_app(ERLWARE, AppName, AppVsn, ToDir)
fetch_app(AppName, AppVsn, ToDir) -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    fetch_app(Repos, AppName, AppVsn, ToDir).

%%--------------------------------------------------------------------
%% @doc 
%%  Fetch the highest version of an application from a repository and place it into the specified directory
%% <pre>
%% Examples:
%%  fetch_app(gas, "./")
%% </pre>
%% @spec fetch_app(AppName, ToDir) -> ok | {error, Reason}
%% where
%%     AppName = string() | atom()
%%     ToDir = string() | atom()
%% @end
%%--------------------------------------------------------------------
fetch_app(AppName, ToDir) -> 
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    {ok, Repos}         = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    [A,B]               = epkg_util:if_atom_or_integer_to_string([AppName, ToDir]),
    fax_install:fetch_latest_remote_application(Repos, TargetErtsVsn, A, B, ?REQUEST_TIMEOUT).

%% @private
fetch_app_help() ->
    ["\nHelp for fetch-app\n",
     "Usage: fetch-app <app-name> [app-vsn] <to-dir> [app version]: will fetch an OTP app remotely and place it into the to dir."]. 


%%--------------------------------------------------------------------
%% @doc 
%%  Publishes a pre-built generic application or a release to a remote unguarded repository. A generic application 
%%  typically consists of erlang object code and possibly other platform independent code.  
%%  This code is then available for immediate use by any application is erlware repo compatible such as Sinan.
%%
%% @spec publish(Repos, AppDir, Timeout) -> ok | {error, Reason}
%% where
%%     Repo = string() | atom()
%%     AppDir = string() | atom()
%%     Timeout = timeout()
%% @end
%%--------------------------------------------------------------------
publish(Repo, PackageDir, Timeout) -> 
    [A,B]         = epkg_util:if_atom_or_integer_to_string([Repo, PackageDir]),
    fax_publish:publish([A], B, Timeout, ?REQUEST_TIMEOUT).

%% @spec publish(PackageDir, Timeout) -> ok | {error, Reason}
%% @equiv publish(Repos, PackageDir, Timeout)
publish(PackageDir, Timeout) when is_integer(Timeout); Timeout == infinity -> 
    {ok, Repos}   = gas:get_env(faxien, repos_to_publish_to, ?ERLWARE_URL),
    [A]           = epkg_util:if_atom_or_integer_to_string([PackageDir]),
    fax_publish:publish(Repos, A, Timeout);

%% @spec publish(Repos PackageDir) -> ok | {error, Reason}
%% @equiv publish(Repos AppDir, Timeout)
publish(Repo, PackageDir) -> 
    {ok, Timeout} = gas:get_env(faxien, request_timeout, ?REQUEST_TIMEOUT),
    publish([Repo], PackageDir, Timeout).

%% @spec publish(AppDir) -> ok | {error, Reason}
%% @equiv publish(DefaultRepos, AppDir)
publish(PackageDir) -> 
    {ok, Timeout} = gas:get_env(faxien, request_timeout, ?REQUEST_TIMEOUT),
    publish(PackageDir, Timeout).

%% @private
publish_help() ->
    ["\nHelp for publish\n",
     "Usage: publish <release package|app package>: will publish an erts, release, or application package. Faxien figures out which based on inspection.\n",
     "Packages should be of the form <package name>-<package version>[.tar.gz|.epkg] for example erts-5.5.5.tar.gz"]. 


%%--------------------------------------------------------------------
%% @doc 
%%  Return the version of the current Faxien release.
%% @spec version() -> string()
%% @end
%%--------------------------------------------------------------------
version() -> 
    {value, {faxien, _, Vsn}} = lists:keysearch(faxien, 1, application:which_applications()),
    {ok, Vsn}.

%%--------------------------------------------------------------------
%% @doc 
%%  Print the help screen
%% @spec help() -> ok
%% @end
%%--------------------------------------------------------------------
help() -> 
    print_help_list(
      [
       "\nFaxien is a powerful package manager for the Erlang language. This message is the gateway into further Faxien help.",
       "\nUsage:",
       "faxien help",
       "faxien version",
       "faxien <command> [options|arguments...]",
       "\nMore Help:",
       "faxien help commands: Lists all faxien commands",
       "faxien help <command>: Gives help on an individual command",
       "faxien help examples: Lists example usages of faxien",
       "\nShort Examples:",
       "faxien install-release sinan",
       "faxien search yaws",
       "faxien help search"
      ]).  

%% @private
examples_help() ->
    [
     "\nExamples:",
     "\nPublish the tools application with a timeout of infinity",
     "  faxien publish /usr/local/erlang/lib/tools-2.5.4 infinity",
     "\nInstall the tools application from the local filesystem",
     "  faxien install-app /usr/local/erlang/lib/tools-2.5.4",
     "\nInstall sinan from a remote repository",
     "  faxien install-release sinan",
     "\nInstall sinan-release version 0.8.8 from a remote repository",
     "  faxien install-release sinan 0.8.8",
     "\nInstall a new version of faxien from a release tarball",
     "  faxien install-release faxien-0.19.3.epkg",
     "\nSearch for an appliction or release with the word \"cloth\" in it",
     "  faxien search cloth",
     "  or",
     "  faxien search regexp \".*cloth.*\"",
     "\nAdd an additional repo to publish to",
     "  faxien add-publish-repo http://www.martinjlogan.com:8080/pub"
    ].

%% @private
commands_help() ->
    [
     "\nCommands:",
     "help                    print help information",
     "search                  search for remote packages",
     "installed               list the packages installed on the local system",
     "describe-app            print more information about a specific application package",
     "install-release         install a release package",
     "fetch-release           fetch a release package into the specified directory",
     "install-app             install an application package",
     "fetch-app               fetch an application package into the specified directory",
     "publish                 publish a package to remote repositories",
     "remove-release          uninstall a release package",
     "remove-app              uninstall an application package",
     "upgrade-release         upgrade a release package installed on the local system",
     "upgrade-all-releases    upgrade all the release packages installed on the local system",
     "upgrade-app             upgrade an application package installed on the local system",  
     "upgrade-all-apps        upgrade all the application packages installed on the local system",  
     "version                 display the current Faxien version installed on the local system",

     "\nConfiguration Management Commands:",
     "environment             display information about the current Faxien environment seetings.",
     "add-repo                add a repo to search for packages in",
     "remove-repo             remove one of the repos Faxien is set to search for packages in",
     "show-repos              display the repos Faxien is set to search for packages in",
     "add-publish-repo        add a repo to publish packages to",
     "remove-publish-repo     remove one of the repos Faxien is set to publish to",
     "show-publish-repos      display the repos Faxien is set to publish to",
     "set-request-timeout     set the timeout faxien uses for requests to remote repositories",
     "show-request-timeout    display the timeout faxien uses for requests to remote repositories",
     "set-target-erts-vsn     set the highest erts vsn faxien will interact with without explicit instruction",
     "show-target-erts-vsn    display the highest erts vsn faxien will interact with without explicit instruction"
    ].

%%--------------------------------------------------------------------
%% @doc 
%%  Print the help screen for a specific command.
%% @spec help(Command::atom()) -> ok
%% @end
%%--------------------------------------------------------------------
help(Command) when is_atom(Command) ->
    help_for_command(atom_to_list(Command));
help(Command) when is_list(Command) ->
    help_for_command(Command).

%%--------------------------------------------------------------------
%% @doc 
%%  Returns a list of packages.
%% @spec search(Repos, Side, SearchType, SearchString) -> string()
%%  where
%%   Repos = list()
%%   Side = lib | releases | both
%%   SearchType = regexp | normal
%%   SearchString = string() | atom()
%% @end
%%--------------------------------------------------------------------
search(Repos, Side, SearchType, SearchString) when is_atom(SearchString) -> 
    search(Repos, Side, SearchType, atom_to_list(SearchString));
search(Repos, Side, SearchType, SearchString) -> 
    fax_manage:search(Repos, Side, SearchType, SearchString).

%% @spec search(SearchType, SearchString) -> string()
%% @equiv search(Repos, both, SearchType, SearchString) 
search(SearchType, SearchString) -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    search(Repos, both, SearchType, SearchString).

%% @spec search(SearchString) -> string()
%% @equiv search(Repos, both, normal, SearchString) 
search(SearchString) -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    search(Repos, both, normal, SearchString).
    
%% @spec search() -> string()
%% @equiv search(Repos, both, regexp, ".*") 
search() -> 
    {ok, Repos} = gas:get_env(faxien, repos_to_fetch_from, [?ERLWARE_URL]),
    search(Repos, both, normal, "").

%% @private
search_help() ->
    ["\nHelp for search\n",
     "Usage: search [[space separated repos] [both|lib|releases] [normal|regexp] search_string]: lists the contents of a repository in various ways.\n",
     "Example: search lib regexp std.* - this example will list all libraries (lib) that match the regexp std.*" ,
     "Example: search regexp std.* - this example will list all libraries and releases that match the regexp std.*" ,
     "Example: search yaw - this example will list all libraries and releases that contain the string 'yaw'" ,
     "Example: search - this example will list all libraries and releases"].


%%--------------------------------------------------------------------
%% @doc 
%%  Returns a list of packages that are currently installed.
%% @spec installed(Side) -> string()
%%  where
%%   Side = lib | releases | all
%% @end
%%--------------------------------------------------------------------
installed(Side) when Side == lib; Side == releases; Side == all ->
    case Side of
	lib -> 
	    epkg:list_lib();
	releases ->
	    epkg:list_releases();
	all ->
	    epkg:list()
    end.

%% @spec installed() -> string()
%% @equiv installed(all)
installed() ->
    installed(all).

%% @private
installed_help() ->
    ["\nHelp for installed\n",
     "Usage: list [all|applications|releases]: lib will list all installed applications, releases all installed releases, and all will list all\n",
     "Example: list - will list all installed applications and releases.",
     "\nnote: The use of side = releases | lib is historical.  Applications are installed into erlang under lib and releases under releases.",
     "hence the somewhat odd names :). Perhaps someone will complain a lot and we will write a translator."].

%%--------------------------------------------------------------------
%% @doc 
%%  Remove an installed application.
%% @spec remove_app(AppName, AppVsn) -> ok
%%  where
%%   AppName = string()
%%   AppVsn = string() | integer()
%% @end
%%--------------------------------------------------------------------
remove_app(AppName, AppVsn) ->
    epkg:remove_app(AppName, AppVsn). 

%%--------------------------------------------------------------------
%% @doc 
%%  Remove all versions of an installed application.
%% @spec remove_app(AppName) -> ok
%%  where
%%   AppName = string()
%% @end
%%--------------------------------------------------------------------
remove_app(AppName) ->
    epkg:remove_all_apps(AppName).

%% @private
remove_app_help() ->
    ["\nHelp for remove-app\n",
     "Usage: remove-app <app name> [app version]: remove a particular application for all versions or a particular version.\n",
     "Example: remove-app tools - removes all versions of the tools application currently installed.",
     "Example: remove-app tools 2.4.5 - removes version 2.4.5 of the tools version."].

%%--------------------------------------------------------------------
%% @doc 
%%  Remove an installed release.
%% @spec remove_release(RelName, RelVsn) -> ok
%%  where
%%   RelName = string()
%%   RelVsn = string() | atom() | integer()
%% @end
%%--------------------------------------------------------------------
remove_release(RelName, RelVsn) ->
    epkg:remove(RelName, RelVsn). 

%%--------------------------------------------------------------------
%% @doc 
%%  Remove all versions of an installed release.
%% @spec remove_release(RelName) -> ok
%%  where
%%   RelName = string()
%% @end
%%--------------------------------------------------------------------
remove_release(RelName) ->
    epkg:remove_all(RelName). 

%% @private
remove_release_help() ->
    ["\nHelp for remove-release\n",
     "Usage: remove-release <release name> [release version]: remove all versions or a specific version of a particular release.\n",
     "Example: remove-release sinan - removes all versions of the sinan release that are currently installed.",
     "Example: remove-release sinan 0.8.8 - removes version 0.8.8 of the sinan release."].

%%--------------------------------------------------------------------
%% @doc 
%%  Fetch the description for a particular application.
%% @spec describe_app(AppName, AppVsn) -> ok
%%  where
%%   AppName = string() | atom()
%%   AppVsn = string() | atom() | integer()
%% @end
%%--------------------------------------------------------------------
describe_app(AppName, AppVsn) ->
    [A, B]              = epkg_util:if_atom_or_integer_to_string([AppName, AppVsn]),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    {ok, Repos}         = gas:get_env(faxien, repos_to_fetch_from, []),
    fax_manage:describe_app(Repos, TargetErtsVsn, A, B, ?REQUEST_TIMEOUT).

%%--------------------------------------------------------------------
%% @doc 
%%  Fetch the description for the highest vesion available for a particular application.
%% @spec describe_app(AppName) -> ok
%%  where
%%   AppName = string() | atom()
%% @end
%%--------------------------------------------------------------------
describe_app(AppName) ->
    [A]                 = epkg_util:if_atom_or_integer_to_string([AppName]),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    {ok, Repos}         = gas:get_env(faxien, repos_to_fetch_from, []),
    fax_manage:describe_latest_app(Repos, TargetErtsVsn, A, ?REQUEST_TIMEOUT).

%% @private
describe_app_help() ->
    ["\nHelp for describe-app\n",
     "Usage: describe-app <application name> [app version]: Fetch the description for a particular application.\n",
     "Example: describe-app sinan - Bring back a description of the highest version available for Sinan.",
     "Example: describe-app sinan 0.8.8 - Bring back a description of version 0.8.8 of the Sinan application."].

%%--------------------------------------------------------------------
%% @doc 
%%  Fetch the description for a particular release.
%% @spec describe_release(RelName, RelVsn) -> ok
%%  where
%%   RelName = string() | atom()
%%   RelVsn = string() | atom() | integer()
%% @end
%%--------------------------------------------------------------------
describe_release(RelName, RelVsn) ->
    [A, B]              = epkg_util:if_atom_or_integer_to_string([RelName, RelVsn]),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    {ok, Repos}         = gas:get_env(faxien, repos_to_fetch_from, []),
    fax_manage:describe_release(Repos, TargetErtsVsn, A, B, ?REQUEST_TIMEOUT).

%%--------------------------------------------------------------------
%% @doc 
%%  Fetch the description for the highest vesion available for a particular release.
%% @spec describe_release(RelName) -> ok
%%  where
%%   RelName = string() | atom()
%% @end
%%--------------------------------------------------------------------
describe_release(RelName) ->
    [A]                 = epkg_util:if_atom_or_integer_to_string([RelName]),
    {ok, TargetErtsVsn} = gas:get_env(epkg, target_erts_vsn, ewr_util:erts_version()),
    {ok, Repos}         = gas:get_env(faxien, repos_to_fetch_from, []),
    fax_manage:describe_latest_release(Repos, TargetErtsVsn, A, ?REQUEST_TIMEOUT).

%% @private
describe_release_help() ->
    ["\nHelp for describe-release\n",
     "Usage: describe-release <release name> [release version]: Fetch the description for a particular release.\n",
     "Example: describe-release sinan - Bring back a description of the highest version available for Sinan.",
     "Example: describe-release sinan 0.8.8 - Bring back a description of version 0.8.8 of the Sinan release."].

%%====================================================================
%% Config Management External Functions
%%====================================================================
%%--------------------------------------------------------------------
%% @doc Display information about the current Faxien environment seetings.
%% @spec environment() -> {ok, list()} 
%% @end
%%--------------------------------------------------------------------
environment() ->
    {ok, Version} = version(),
    io:format("~nFaxien Environment:~n~nFaxien Version is ~n  ~s~n", [Version]),
    {ok, TargetErtsVsn} = show_target_erts_vsn(),
    io:format("~nThe target erts version~n  ~p~n", [TargetErtsVsn]),
    {ok, InstallationPath} = epkg_installed_paths:get_installation_path(),
    io:format("~nThe installation path is ~n  ~s~n", [InstallationPath]),
    {ok, Timeout} = show_request_timeout(),
    io:format("~nThe Request Timeout is~n  ~p~n", [Timeout]),
    {ok, Repos} = show_repos(),
    io:format("~nRepos to search~n  ~p~n", [Repos]),
    {ok, PublishRepos} = show_publish_repos(),
    io:format("~nRepos to publish to~n  ~p~n", [PublishRepos]).
    
								   
%% @private
environment_help() ->
    ["\nHelp for environment\n",
     "Usage: environment - Display information about the current Faxien environment seetings.\n"].


%%--------------------------------------------------------------------
%% @doc Remove a repository from the list of repos to fetch from. 
%% @spec remove_repo(Repo) -> ok | {error, Reason}
%%  where
%%   Repo = string() | atom()
%% @end
%%--------------------------------------------------------------------
remove_repo(Repo) when is_atom(Repo)->
    remove_repo(atom_to_list(Repo));
remove_repo(Repo) ->
    fax_manage:remove_repo_to_fetch_from(Repo, epkg_installed_paths:installed_config_file_path()).

%% @private
remove_repo_help() ->
    ["\nHelp for remove-repo\n",
     "Usage: remove-repo <url> - will remove one of the repos that faxien pulls packages from.\n",
     "Example: faxien remove-repo http://www.martinjlogan.com:8080/pub"].

%%--------------------------------------------------------------------
%% @doc Add a repository to the list of repos to fetch from. 
%% @spec add_repo(Repo) -> ok | {error, Reason}
%%  where
%%   Repo = string() | atom()
%% @end
%%--------------------------------------------------------------------
add_repo(Repo) when is_atom(Repo)->
    add_repo(atom_to_list(Repo));
add_repo(Repo) ->
    fax_manage:add_repo_to_fetch_from(Repo, epkg_installed_paths:installed_config_file_path()).
    
%% @private
add_repo_help() ->
    ["\nHelp for add-repo\n",
     "Usage: add-repo <url> - will add a repo to the list of repos that faxien pulls packages from.\n",
     "Example: faxien add-repo http://www.martinjlogan.com:8080/pub"].

%%--------------------------------------------------------------------
%% @doc Show the list of repos that faxien is currently configured to fetch from.
%% @spec show_repos() -> {ok, list()} 
%% @end
%%--------------------------------------------------------------------
show_repos() ->
    gas:get_env(faxien, repos_to_fetch_from, []).
								   
%% @private
show_repos_help() ->
    ["\nHelp for show-repos\n",
     "Usage: show-repos - display the list of repos that faxien pulls packages from.\n"].


%%--------------------------------------------------------------------
%% @doc Set repository to publish to.
%% @spec set_request_timeout(Timeout::timeout()) -> ok | {error, Reason}
%%  where
%%   Repo = string() | atom()
%% @end
%%--------------------------------------------------------------------
set_request_timeout(infinity) ->
    fax_manage:set_request_timeout(infinity, epkg_installed_paths:installed_config_file_path());
set_request_timeout(Timeout) when is_list(Timeout) ->
    fax_manage:set_request_timeout(list_to_integer(Timeout), epkg_installed_paths:installed_config_file_path()).

%% @private
set_request_timeout_help() ->
    ["\nHelp for set-request-timeout\n",
     "Usage: set-request-timeout <milliseconds> - will set a new timeout value for all remote requests.\n"].

%%--------------------------------------------------------------------
%% @doc Show the faxien remote request timeout.
%% @spec show_request_timeout() -> {ok, timeout()} | {error, no_request_timeout}
%% @end
%%--------------------------------------------------------------------
show_request_timeout() ->
    gas:get_env(faxien, request_timeout, {error, no_request_timeout}).

%% @private
show_request_timeout_help() ->
    ["\nHelp for show-request-timeout\n",
     "Usage: show-request-timeout - will display the current timeout value for all remote requests.\n"].

%%--------------------------------------------------------------------
%% @doc Set the target erts vsn for Faxien.  This is the highest erts vsn faxien will interact with automatically.
%% @spec set_target_erts_vsn(TargetErtsVsn) -> ok | {error, Reason}
%%  where
%%   Repo = string() | atom()
%% @end
%%--------------------------------------------------------------------
set_target_erts_vsn(TargetErtsVsn) ->
    fax_manage:set_target_erts_vsn(TargetErtsVsn, epkg_installed_paths:installed_config_file_path()).

%% @private
set_target_erts_vsn_help() ->
    ["\nHelp for set-target-erts-vsn\n",
     "Usage: set-target-erts-vsn <erts-vsn> - will set a new target erts vsn. This is the highest erts vsn faxien will interact with automatically.\n"].

%%--------------------------------------------------------------------
%% @doc Set the target erts vsn for Faxien.  This is the highest erts vsn faxien will interact with automatically.
%% @spec show_target_erts_vsn() -> {ok, timeout()} | {error, no_target_erts_vsn}
%% @end
%%--------------------------------------------------------------------
show_target_erts_vsn() ->
    gas:get_env(epkg, target_erts_vsn, {error, no_target_erts_vsn}).

%% @private
show_target_erts_vsn_help() ->
    ["\nHelp for show-target-erts-vsn\n",
     "Usage: show-target-erts-vsn - will show the target erts vsn. This is the highest erts vsn faxien will interact with automatically.\n"].

%%--------------------------------------------------------------------
%% @doc Remove a repository from the list of repos to fetch from. 
%% @spec remove_publish_repo(Repo) -> ok | {error, Reason}
%%  where
%%   Repo = string() | atom()
%% @end
%%--------------------------------------------------------------------
remove_publish_repo(Repo) when is_atom(Repo)->
    remove_repo(atom_to_list(Repo));
remove_publish_repo(Repo) ->
    fax_manage:remove_repo_to_publish_to(Repo, epkg_installed_paths:installed_config_file_path()).

%% @private
remove_publish_repo_help() ->
    ["\nHelp for remove-publish-repo\n",
     "Usage: remove-publish-repo <url> - will remove one of the repos that faxien publishes packages to.\n",
     "Example: faxien remove-publish_repo http://www.martinjlogan.com:8080/pub"].

%%--------------------------------------------------------------------
%% @doc Add a repository to the list of repos to publish to. 
%% @spec add_publish_repo(Repo) -> ok | {error, Reason}
%%  where
%%   Repo = string() | atom()
%% @end
%%--------------------------------------------------------------------
add_publish_repo(Repo) ->
    fax_manage:add_repo_to_publish_to(Repo, epkg_installed_paths:installed_config_file_path()).
    
%% @private
add_publish_repo_help() ->
    ["\nHelp for add-publish-repo\n",
     "Usage: add-publish-repo <url> - will add a repo to the list of repos that faxien publishes packages to.\n",
     "Example: faxien add-publish-repo http://www.martinjlogan.com:8080/pub"].

%%--------------------------------------------------------------------
%% @doc Show the list of publish repos that faxien is currently configured to publish to.
%% @spec show_publish_repos() -> {ok, list()}
%% @end
%%--------------------------------------------------------------------
show_publish_repos() ->
    gas:get_env(faxien, repos_to_publish_to, []).
								   
%% @private
show_publish_repos_help() ->
    ["\nHelp for show-publish-repos\n",
     "Usage: show-publish-repos - display the list of repos that faxien publishes packages to.\n"].

%%====================================================================
%% Internal functions
%%====================================================================

help_for_command(RawCommand) ->
    Command = fax_cmdln:sub_func(RawCommand, ?ALIAS_LIST),
    Func             = list_to_atom(Command ++ "_help"),
    case catch ?MODULE:Func() of
	{'EXIT', _Reason} ->
	    io:format("The command ~s does not have detailed help associated with it~n", [Command]);
	HelpList -> 
	    print_help_list(HelpList) 
    end.

%% @private
print_help_list(HelpList) ->	   
    lists:foreach(fun(HelpString) -> io:format("~s~n", [HelpString]) end, HelpList).
    
    
