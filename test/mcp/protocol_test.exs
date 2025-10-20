defmodule HitMeDbOneMoreTimes.MCP.ProtocolTest do
  use ExUnit.Case, async: true

  alias HitMeDbOneMoreTimes.MCP.Protocol

  describe "parse_request/1" do
    test "parses valid JSON request" do
      json = ~s({"jsonrpc": "2.0", "id": 1, "method": "test"})

      assert {:ok, request} = Protocol.parse_request(json)
      assert request["jsonrpc"] == "2.0"
      assert request["id"] == 1
      assert request["method"] == "test"
    end

    test "returns error for invalid JSON" do
      assert {:error, {:invalid_json, _}} = Protocol.parse_request("{invalid}")
    end
  end

  describe "success_response/2" do
    test "creates valid JSON-RPC success response" do
      json = Protocol.success_response(1, %{"data" => "test"})
      response = Jason.decode!(json)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 1
      assert response["result"]["data"] == "test"
    end
  end

  describe "error_response/3" do
    test "creates valid JSON-RPC error response" do
      json = Protocol.error_response(1, -32600, "Invalid request")
      response = Jason.decode!(json)

      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 1
      assert response["error"]["code"] == -32600
      assert response["error"]["message"] == "Invalid request"
    end

    test "includes data in error response when provided" do
      json = Protocol.error_response(1, -32600, "Error", %{"detail" => "info"})
      response = Jason.decode!(json)

      assert response["error"]["data"]["detail"] == "info"
    end
  end

  describe "notification/2" do
    test "creates valid notification without id" do
      json = Protocol.notification("test/event", %{"data" => "value"})
      notification = Jason.decode!(json)

      assert notification["jsonrpc"] == "2.0"
      assert notification["method"] == "test/event"
      assert notification["params"]["data"] == "value"
      refute Map.has_key?(notification, "id")
    end
  end
end
