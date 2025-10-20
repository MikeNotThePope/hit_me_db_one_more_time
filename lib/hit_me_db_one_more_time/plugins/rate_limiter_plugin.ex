defmodule HitMeDbOneMoreTime.Plugins.RateLimiterPlugin do
  @moduledoc """
  A rate limiting plugin that tracks and limits requests based on a fixed window algorithm.

  This plugin demonstrates:
  - Request counting per client/tool
  - Short-circuiting when rate limit is exceeded
  - Automatic window reset after time period

  ## Configuration

  - **Rate Limit**: 5 requests per 10 seconds (configurable)
  - **Algorithm**: Fixed window
  - **Storage**: ETS (in-memory)

  ## How It Works

  1. Extract client identifier from request (tool name + optional client_id)
  2. Check current request count in the time window
  3. If limit exceeded: short-circuit with 429 error
  4. If within limit: increment counter and pass through
  5. When window expires: reset counter automatically

  ## For Production

  For a production rate limiter, consider:
  - Sliding window algorithm for more accurate limiting
  - Redis for distributed rate limiting
  - Per-IP or per-API-key tracking
  - Different limits for different endpoints
  - Rate limit headers in responses (X-RateLimit-*)
  """

  @behaviour HitMeDbOneMoreTime.Plugins.Behaviour

  require Logger

  @rate_limit_table :rate_limits
  @default_max_requests 5
  @default_window_seconds 10

  def start_link do
    :ets.new(@rate_limit_table, [:named_table, :public, read_concurrency: true])
    {:ok, self()}
  end

  @impl true
  def process(request, context) do
    # Extract identifier for rate limiting
    # In a real system, this would be client_id, API key, or IP address
    client_id = extract_client_id(request, context)

    max_requests = Map.get(context, :rate_limit_max, @default_max_requests)
    window_seconds = Map.get(context, :rate_limit_window, @default_window_seconds)

    case check_rate_limit(client_id, max_requests, window_seconds) do
      {:ok, current_count} ->
        Logger.info("""
        [Rate Limiter] Request allowed for #{client_id}
          Count: #{current_count}/#{max_requests}
          Window: #{window_seconds}s
        """)

        # Add rate limit info to context for potential response headers
        updated_context =
          context
          |> Map.put(:rate_limit_current, current_count)
          |> Map.put(:rate_limit_max, max_requests)
          |> Map.put(:rate_limit_window, window_seconds)

        {:pass, updated_context}

      {:error, :rate_limit_exceeded, retry_after} ->
        Logger.warning("""
        [Rate Limiter] Rate limit exceeded for #{client_id}
          Limit: #{max_requests} requests per #{window_seconds}s
          Retry after: #{retry_after}s
        """)

        # Short-circuit with rate limit error
        {:respond,
         %{
           "error" => "rate_limit_exceeded",
           "message" => "Too many requests. Please try again later.",
           "details" => %{
             "limit" => max_requests,
             "window_seconds" => window_seconds,
             "retry_after_seconds" => retry_after
           }
         }}
    end
  end

  # Extract a client identifier from the request.
  #
  # For this demo, we use the tool name. In production, you'd use:
  # - API key from request headers
  # - Client ID from authentication token
  # - IP address from connection metadata
  defp extract_client_id(request, _context) do
    tool_name = Map.get(request, "name", "unknown")

    # You could also extract from context if client info is available:
    # client_id = Map.get(context, :client_id, "anonymous")
    # "#{client_id}:#{tool_name}"

    # For demo: just use tool name
    tool_name
  end

  # Check if the request is within rate limits using a fixed window algorithm.
  #
  # Returns:
  # - `{:ok, current_count}` if within limits (and increments counter)
  # - `{:error, :rate_limit_exceeded, retry_after}` if limit exceeded
  defp check_rate_limit(client_id, max_requests, window_seconds) do
    current_time = System.system_time(:second)

    case :ets.lookup(@rate_limit_table, client_id) do
      [{^client_id, count, window_start}] ->
        # Check if we're still in the same window
        if current_time - window_start < window_seconds do
          # Same window - check if limit exceeded
          if count >= max_requests do
            retry_after = window_seconds - (current_time - window_start)
            {:error, :rate_limit_exceeded, retry_after}
          else
            # Increment counter
            new_count = count + 1
            :ets.insert(@rate_limit_table, {client_id, new_count, window_start})
            {:ok, new_count}
          end
        else
          # Window expired - start new window
          :ets.insert(@rate_limit_table, {client_id, 1, current_time})
          {:ok, 1}
        end

      [] ->
        # First request - start new window
        :ets.insert(@rate_limit_table, {client_id, 1, current_time})
        {:ok, 1}
    end
  end

  @doc """
  Reset rate limit for a specific client (useful for testing or admin operations).
  """
  def reset_limit(client_id) do
    :ets.delete(@rate_limit_table, client_id)
    :ok
  end

  @doc """
  Get current rate limit status for a client.
  """
  def get_status(client_id) do
    current_time = System.system_time(:second)

    case :ets.lookup(@rate_limit_table, client_id) do
      [{^client_id, count, window_start}] ->
        remaining_time = @default_window_seconds - (current_time - window_start)

        %{
          client_id: client_id,
          current_count: count,
          max_requests: @default_max_requests,
          window_start: window_start,
          remaining_time: max(0, remaining_time)
        }

      [] ->
        %{
          client_id: client_id,
          current_count: 0,
          max_requests: @default_max_requests,
          window_start: nil,
          remaining_time: 0
        }
    end
  end
end
