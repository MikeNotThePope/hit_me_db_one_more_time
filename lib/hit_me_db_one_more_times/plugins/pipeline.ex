defmodule HitMeDbOneMoreTimes.Plugins.Pipeline do
  @moduledoc """
  Executes a chain of plugins in order.

  Each plugin can either pass the request to the next plugin or short-circuit
  the pipeline by returning a response directly.
  """

  @doc """
  Execute the plugin pipeline.

  ## Parameters
    - plugins: List of plugin modules to execute in order
    - request: The MCP tool request
    - handler: Function to call if all plugins pass (arity 2: request, context)

  ## Returns
    The response from either a short-circuiting plugin or the handler
  """
  def execute(plugins, request, handler) do
    initial_context = %{timestamp: DateTime.utc_now()}

    case run_plugins(plugins, request, initial_context) do
      {:respond, response} -> response
      {:pass, context} -> handler.(request, context)
    end
  end

  defp run_plugins([], _request, context) do
    {:pass, context}
  end

  defp run_plugins([plugin | rest], request, context) do
    case plugin.process(request, context) do
      :pass ->
        run_plugins(rest, request, context)

      {:pass, updated_context} ->
        run_plugins(rest, request, updated_context)

      {:respond, response} ->
        {:respond, response}
    end
  end
end
