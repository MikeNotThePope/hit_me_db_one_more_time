defmodule HitMeDbOneMoreTime.Plugins.RateLimiterPluginTest do
  use ExUnit.Case, async: false

  alias HitMeDbOneMoreTime.Plugins.RateLimiterPlugin

  setup do
    # Initialize the rate limiter table
    RateLimiterPlugin.start_link()

    # Clean up before each test
    :ets.delete_all_objects(:rate_limits)

    :ok
  end

  describe "process/2" do
    test "allows requests within rate limit" do
      request = %{"name" => "test_tool", "arguments" => %{}}
      context = %{timestamp: DateTime.utc_now()}

      # First 5 requests should pass
      for i <- 1..5 do
        assert {:pass, updated_context} = RateLimiterPlugin.process(request, context)
        assert updated_context.rate_limit_current == i
        assert updated_context.rate_limit_max == 5
      end
    end

    test "denies requests when rate limit exceeded" do
      request = %{"name" => "test_tool", "arguments" => %{}}
      context = %{timestamp: DateTime.utc_now()}

      # Make 5 requests (at the limit)
      for _i <- 1..5 do
        {:pass, _} = RateLimiterPlugin.process(request, context)
      end

      # 6th request should be denied
      assert {:respond, response} = RateLimiterPlugin.process(request, context)
      assert response["error"] == "rate_limit_exceeded"
      assert response["message"] =~ "Too many requests"
      assert response["details"]["limit"] == 5
      assert response["details"]["retry_after_seconds"] > 0
    end

    test "resets counter after window expires" do
      request = %{"name" => "test_tool", "arguments" => %{}}
      context = %{
        timestamp: DateTime.utc_now(),
        rate_limit_window: 1  # Use 1 second window for testing
      }

      # Make 5 requests (at the limit)
      for _i <- 1..5 do
        {:pass, _} = RateLimiterPlugin.process(request, context)
      end

      # 6th request should be denied
      assert {:respond, _} = RateLimiterPlugin.process(request, context)

      # Wait for window to expire
      :timer.sleep(1100)

      # Should allow new requests
      assert {:pass, updated_context} = RateLimiterPlugin.process(request, context)
      assert updated_context.rate_limit_current == 1
    end

    test "tracks different tools separately" do
      context = %{timestamp: DateTime.utc_now()}

      tool1_request = %{"name" => "tool_1", "arguments" => %{}}
      tool2_request = %{"name" => "tool_2", "arguments" => %{}}

      # Make 5 requests to tool_1
      for _i <- 1..5 do
        {:pass, _} = RateLimiterPlugin.process(tool1_request, context)
      end

      # tool_1 should be at limit
      assert {:respond, _} = RateLimiterPlugin.process(tool1_request, context)

      # tool_2 should still be allowed
      assert {:pass, _} = RateLimiterPlugin.process(tool2_request, context)
    end

    test "respects custom rate limits from context" do
      request = %{"name" => "test_tool", "arguments" => %{}}
      context = %{
        timestamp: DateTime.utc_now(),
        rate_limit_max: 3,      # Custom limit: 3 requests
        rate_limit_window: 5    # Custom window: 5 seconds
      }

      # First 3 requests should pass
      for i <- 1..3 do
        assert {:pass, updated_context} = RateLimiterPlugin.process(request, context)
        assert updated_context.rate_limit_current == i
        assert updated_context.rate_limit_max == 3
      end

      # 4th request should be denied
      assert {:respond, response} = RateLimiterPlugin.process(request, context)
      assert response["details"]["limit"] == 3
      assert response["details"]["window_seconds"] == 5
    end

    test "includes rate limit info in context for successful requests" do
      request = %{"name" => "test_tool", "arguments" => %{}}
      context = %{timestamp: DateTime.utc_now()}

      {:pass, updated_context} = RateLimiterPlugin.process(request, context)

      assert updated_context.rate_limit_current == 1
      assert updated_context.rate_limit_max == 5
      assert updated_context.rate_limit_window == 10
    end
  end

  describe "reset_limit/1" do
    test "resets rate limit for a specific client" do
      request = %{"name" => "test_tool", "arguments" => %{}}
      context = %{timestamp: DateTime.utc_now()}

      # Make 5 requests (at the limit)
      for _i <- 1..5 do
        {:pass, _} = RateLimiterPlugin.process(request, context)
      end

      # Should be at limit
      assert {:respond, _} = RateLimiterPlugin.process(request, context)

      # Reset the limit
      RateLimiterPlugin.reset_limit("test_tool")

      # Should allow requests again
      assert {:pass, _} = RateLimiterPlugin.process(request, context)
    end
  end

  describe "get_status/1" do
    test "returns status for client with no requests" do
      status = RateLimiterPlugin.get_status("new_client")

      assert status.client_id == "new_client"
      assert status.current_count == 0
      assert status.max_requests == 5
      assert status.window_start == nil
      assert status.remaining_time == 0
    end

    test "returns status for client with active requests" do
      request = %{"name" => "test_tool", "arguments" => %{}}
      context = %{timestamp: DateTime.utc_now()}

      # Make 3 requests
      for _i <- 1..3 do
        {:pass, _} = RateLimiterPlugin.process(request, context)
      end

      status = RateLimiterPlugin.get_status("test_tool")

      assert status.client_id == "test_tool"
      assert status.current_count == 3
      assert status.max_requests == 5
      assert status.window_start != nil
      assert status.remaining_time > 0
      assert status.remaining_time <= 10
    end
  end
end
