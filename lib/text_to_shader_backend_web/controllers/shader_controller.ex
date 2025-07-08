defmodule TextToShaderBackendWeb.ShaderController do
  use TextToShaderBackendWeb, :controller

  def generate_shader_code(conn, %{"prompt" => shader_generation_prompt}) do
    vertex_prompt = build_vertex_shader_prompt(shader_generation_prompt)
    fragment_prompt = build_fragment_shader_prompt(shader_generation_prompt)

    try do
      with {:ok, vertex_shader_code} <- call_groq_api(vertex_prompt),
           {:ok, fragment_shader_code} <- call_groq_api(fragment_prompt) do
        conn
        |> put_status(:created)
        |> json(%{
          vertex_shader_code: vertex_shader_code,
          fragment_shader_code: fragment_shader_code
        })
      else
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

  # Vertex shader prompt builder
  # User prompt is included for context, but the LLM is instructed to only return the vertex shader code
  # No markdown, no explanations, no formatting, no code blocks

  defp build_vertex_shader_prompt(user_prompt) do
    """
You are a highly skilled GLSL vertex shader generator for WebGL 1.0 (GLSL ES 1.00).
Carefully analyze the user's request and requirements before generating code. Think step by step to ensure the shader logic is correct and robust.
Generate ONLY raw GLSL code for the vertex shader, with NO markdown, NO explanations, NO formatting, NO code blocks.

REQUIREMENTS:
- The FIRST line MUST be: precision mediump float;
- Use attribute vec2 a_position for the vertex position.
- Output varying vec2 v_uv that maps a_position from [-1, 1] to [0, 1].
- Set gl_Position for a full-screen quad.
- All variables must be declared before use.
- Do not use any variables or uniforms that are not explicitly declared above.
- Do not include any comments or explanations.
- The code MUST be valid for WebGL 1.0 (GLSL ES 1.00).
- The code MUST be correct and robust, and must fully satisfy the user's intent and requirements.

User request: "#{user_prompt}"

Return ONLY the raw GLSL code for the vertex shader, starting with 'precision mediump float;'.
"""
  end

  # Fragment shader prompt builder
  # User prompt is included for context, but the LLM is instructed to only return the fragment shader code
  # No markdown, no explanations, no formatting, no code blocks

  defp build_fragment_shader_prompt(user_prompt) do
    """
You are a highly skilled GLSL fragment shader generator for WebGL 1.0 (GLSL ES 1.00).
Carefully analyze the user's request and requirements before generating code. Think step by step to ensure the shader logic is correct and robust.
Generate ONLY raw GLSL code for the fragment shader, with NO markdown, NO explanations, NO formatting, NO code blocks.

REQUIREMENTS:
- The FIRST line MUST be: precision mediump float;
- Use varying vec2 v_uv from the vertex shader.
- Use uniforms float u_time and vec2 u_resolution.
- Output a color to gl_FragColor.
- The effect should be an animated color wave using v_uv and u_time.
- All variables must be declared before use.
- Do not use any variables or uniforms that are not explicitly declared above.
- Do not include any comments or explanations.
- The code MUST be valid for WebGL 1.0 (GLSL ES 1.00).
- The code MUST be correct and robust, and must fully satisfy the user's intent and requirements.

User request: "#{user_prompt}"

Return ONLY the raw GLSL code for the fragment shader, starting with 'precision mediump float;'.
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
        "model" => "meta-llama/llama-4-scout-17b-16e-instruct"
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
