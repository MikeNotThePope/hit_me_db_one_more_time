defmodule HitMeDbOneMoreTimes.Plugins.Behaviour do
  @moduledoc """
  Defines the behaviour that all plugins must implement.

  Plugins can intercept requests before they reach the database and either:
  - Pass the request through to the next plugin (`:pass`)
  - Short-circuit and return a response immediately (`{:respond, response}`)
  """

  @doc """
  Process a request through the plugin.

  ## Parameters
    - request: The MCP tool request map
    - context: Shared context map that plugins can read/write to

  ## Returns
    - `:pass` - Continue to next plugin
    - `{:respond, response}` - Short-circuit and return this response
    - `{:pass, updated_context}` - Continue with updated context
  """
  @callback process(request :: map(), context :: map()) ::
              :pass
              | {:pass, updated_context :: map()}
              | {:respond, response :: any()}
end
