defmodule HitMeDbOneMoreTimes.Plugins.PipelineTest do
  use ExUnit.Case, async: true

  alias HitMeDbOneMoreTimes.Plugins.Pipeline

  defmodule PassThroughPlugin do
    @behaviour HitMeDbOneMoreTimes.Plugins.Behaviour

    def process(_request, _context), do: :pass
  end

  defmodule ShortCircuitPlugin do
    @behaviour HitMeDbOneMoreTimes.Plugins.Behaviour

    def process(_request, _context) do
      {:respond, %{"cached" => true}}
    end
  end

  defmodule ContextUpdatingPlugin do
    @behaviour HitMeDbOneMoreTimes.Plugins.Behaviour

    def process(_request, context) do
      {:pass, Map.put(context, :updated, true)}
    end
  end

  describe "execute/3" do
    test "calls handler when all plugins pass" do
      request = %{"name" => "test"}
      handler = fn req, _ctx -> %{"result" => req["name"]} end

      result = Pipeline.execute([PassThroughPlugin], request, handler)

      assert result == %{"result" => "test"}
    end

    test "short-circuits when plugin returns response" do
      request = %{"name" => "test"}
      handler = fn _req, _ctx -> %{"should" => "not be called"} end

      result = Pipeline.execute([ShortCircuitPlugin], request, handler)

      assert result == %{"cached" => true}
    end

    test "passes updated context through pipeline" do
      request = %{"name" => "test"}

      handler = fn _req, ctx ->
        assert ctx.updated == true
        %{"context_was_updated" => true}
      end

      result = Pipeline.execute([ContextUpdatingPlugin], request, handler)

      assert result == %{"context_was_updated" => true}
    end

    test "executes plugins in order" do
      request = %{"name" => "test"}

      handler = fn _req, _ctx ->
        %{"reached_handler" => true}
      end

      # First plugin passes, second short-circuits
      result =
        Pipeline.execute([PassThroughPlugin, ShortCircuitPlugin], request, handler)

      assert result == %{"cached" => true}
    end
  end
end
