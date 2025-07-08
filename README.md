# Text-to-Shader Backend

An Elixir/Phoenix backend that generates GLSL shader code using Groq's LLM API.

## Features

- **GLSL Shader Generation**: Converts text prompts into WebGL-compatible vertex and fragment shaders
- **Separate Shader Components**: Generates vertex and fragment shaders independently for better control
- **WebGL 1.0 Compatible**: Ensures generated shaders work with WebGL 1.0 (GLSL ES 1.00)
- **Precision Handling**: Automatically includes required precision declarations

## API Endpoints

### POST `/api/shader`

Generates GLSL vertex and fragment shader code from a text prompt.

**Request:**
```json
{
  "prompt": "flowing lava effect with animated colors"
}
```

**Response:**
```json
{
  "vertex_shader_code": "precision mediump float;\nattribute vec2 a_position;\nvarying vec2 v_uv;\nvoid main() {\n  v_uv = a_position * 0.5 + 0.5;\n  gl_Position = vec4(a_position, 0.0, 1.0);\n}",
  "fragment_shader_code": "precision mediump float;\nvarying vec2 v_uv;\nuniform float u_time;\nuniform vec2 u_resolution;\nvoid main() {\n  vec2 uv = v_uv;\n  vec3 color = 0.5 + 0.5 * sin(u_time + uv.xyx + vec3(0,2,4));\n  gl_FragColor = vec4(color, 1.0);\n}"
}
```

## Setup

1. Install dependencies: `mix deps.get`
2. Set your Groq API key: `export GROQ_API_KEY=your_api_key_here`
3. Start the server: `mix phx.server`

The API is available at `https://text-to-shader-backend.fly.dev/api/shader`