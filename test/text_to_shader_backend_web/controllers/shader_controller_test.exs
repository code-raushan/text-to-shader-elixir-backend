defmodule TextToShaderBackendWeb.ShaderControllerTest do
  use TextToShaderBackendWeb.ConnCase

  test "POST /api/shader returns 201 with prompt", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post(~p"/api/shader", Jason.encode!(%{"prompt" => "Create a simple gradient from red to blue"}))

    assert conn.state == :sent
    assert conn.status == 201
  end
end
