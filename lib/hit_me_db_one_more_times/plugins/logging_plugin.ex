defmodule HitMeDbOneMoreTimes.Plugins.LoggingPlugin do
  @moduledoc """
  A simple logging plugin that logs all requests passing through the pipeline.

  This demonstrates a basic plugin that always passes requests through.
  """

  @behaviour HitMeDbOneMoreTimes.Plugins.Behaviour

  require Logger

  @impl true
  def process(request, context) do
    tool_name = Map.get(request, "name", "unknown")
    params = Map.get(request, "arguments", %{})

    Logger.info("""
    [Plugin Pipeline] Request received:
      Tool: #{tool_name}
      Params: #{inspect(params)}
      Timestamp: #{context.timestamp}
    """)

    :pass
  end
end
