defmodule HitMeDbOneMoreTimes.Plugins.CachePlugin do
  @moduledoc """
  A caching plugin that can serve responses from cache without hitting the database.

  This demonstrates how to short-circuit the pipeline - perfect for rate limiting!
  For this demo, we use a simple ETS-based cache. In a real rate limiter, you'd
  check request rates here and either serve cached results or deny the request.
  """

  @behaviour HitMeDbOneMoreTimes.Plugins.Behaviour

  require Logger

  @cache_table :request_cache
  @cache_ttl_seconds 30

  def start_link do
    :ets.new(@cache_table, [:named_table, :public, read_concurrency: true])
    {:ok, self()}
  end

  @impl true
  def process(request, context) do
    cache_key = generate_cache_key(request)

    case get_from_cache(cache_key) do
      {:ok, cached_response} ->
        Logger.info("[Cache Plugin] Cache HIT for key: #{cache_key}")
        {:respond, cached_response}

      :miss ->
        Logger.info("[Cache Plugin] Cache MISS for key: #{cache_key}")
        # Store the cache key in context so we can cache the response later
        {:pass, Map.put(context, :cache_key, cache_key)}
    end
  end

  @doc """
  Store a response in the cache. Call this after getting the real response.
  """
  def cache_response(cache_key, response) do
    expires_at = System.system_time(:second) + @cache_ttl_seconds
    :ets.insert(@cache_table, {cache_key, response, expires_at})
    Logger.info("[Cache Plugin] Cached response for key: #{cache_key}")
  end

  defp generate_cache_key(request) do
    tool_name = Map.get(request, "name", "unknown")
    arguments = Map.get(request, "arguments", %{})

    # Create a simple cache key from tool name and arguments
    "#{tool_name}:#{inspect(arguments)}"
    |> :erlang.md5()
    |> Base.encode16()
  end

  defp get_from_cache(key) do
    current_time = System.system_time(:second)

    case :ets.lookup(@cache_table, key) do
      [{^key, response, expires_at}] when expires_at > current_time ->
        {:ok, response}

      [{^key, _response, _expires_at}] ->
        # Expired entry, delete it
        :ets.delete(@cache_table, key)
        :miss

      [] ->
        :miss
    end
  end
end
