defmodule TextToShaderBackendWeb.ShaderController do
  use TextToShaderBackendWeb, :controller

  def generate_shader_code(conn, %{"prompt" => shader_generation_prompt}) do
    full_prompt = build_llm_prompt(shader_generation_prompt)

    try do
      case call_groq_api(full_prompt) do
        {:ok, shader_code} ->
          # Remove markdown code block markers if present
          cleaned_shader_code =
            shader_code
            |> String.replace(~r/^```[a-zA-Z]*\n/, "")
            |> String.replace(~r/```$/, "")

          conn
          |> put_status(:created)
          |> json(%{shader_code: cleaned_shader_code})

        {:error, error_message} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Failed to call LLM: #{error_message}"})
      end
    catch
      {:error, error_message} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: error_message})
    end
  end

  defp build_llm_prompt(user_prompt) do
    """
    You are a GLSL shader generator.
    Generate a single GLSL code block containing both a vertex and a fragment shader for WebGL.
    The vertex shader MUST provide a `v_pos` varying to the fragment shader.
    The fragment shader will have access to the following uniforms:
    - `uniform float u_time;` (the running time in seconds)
    - `uniform vec2 u_resolution;` (the resolution of the canvas)
    - `varying vec2 v_pos;` (the screen coordinate from -1.0 to 1.0)

    Separate the two shaders with a comment: `// FRAGMENT SHADER`.
    Do not include any explanation, just the raw GLSL code.

    User request: "#{user_prompt}"
    """
  end

  defp call_groq_api(prompt) do
    api_key = System.get_env("GROQ_API_KEY")
    if is_nil(api_key) or api_key == "" do
      IO.puts("GROQ_API_KEY is missing! Please set it in your .env file and restart the server.")
      throw {:error, "GROQ_API_KEY is missing!"}
    end

    groq_api_endpoint = "https://api.groq.com/openai/v1/chat/completions"

    headers = [
      {"Authorization", "Bearer " <> api_key},
      {"Content-Type", "application/json"}
    ]

    # 4. Create the request body with the Llama 3 model and correct message structure
    body =
      %{
        "messages" => [
          %{
            "role" => "user",
            "content" => prompt
          }
        ],
        "model" => "llama3-8b-8192"
      }
      |> Jason.encode!()

    case HTTPoison.post(groq_api_endpoint, body, headers) do
      {:ok, %{status_code: 200, body: resp_body}} ->
        # 6. Parse the Groq API response to get the text content
        decoded = Jason.decode!(resp_body)
        choices = Map.get(decoded, "choices", [])
        shader_code =
          choices
          |> Enum.at(0, %{})
          |> Map.get("message", %{})
          |> Map.get("content")

        {:ok, shader_code}

      {:ok, %{status_code: _, body: error_body}} ->
        {:error, "API Error: #{error_body}"}

      {:error, %{reason: reason}} ->
        {:error, reason}
    end
  end

end
