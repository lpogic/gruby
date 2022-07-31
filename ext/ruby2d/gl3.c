// OpenGL 3.3+

#include "ruby2d.h"

#if !GLES

#define R2D_GL3_ELEMENTS_CAPACITY 7500
#define R2D_GL3_TRIANGLES_VBO_CAPACITY 5000
#define R2D_GL3_PINS_VBO_CAPACITY 5000
#define R2D_GL3_TRIANGLE_ID 0
#define R2D_GL3_PIN_ID 0xFFFFFFFF

static GLuint vertices[R2D_GL3_ELEMENTS_CAPACITY]; // store the texture_id of each vertices
static GLuint verticesIndex = 0;  // index of the current object being rendered

static GLuint trianglesVao;  // our primary vertex array object (VAO)
static GLuint trianglesVbo;  // our primary vertex buffer object (VBO)
static GLfloat *trianglesVboData;  // pointer to the VBO data
static GLfloat *trianglesVboCurrent;  // pointer to the data for the current vertices
static GLuint trianglesVboIndex = 0;  // index of the current object being rendered
static GLuint trianglesShaderProgram;  // triangle shader program
static GLuint texturesShaderProgram;  // texture shader program

static GLuint pinsVao;
static GLuint pinsVbo;
static GLfloat *pinsVboData;  // pointer to the VBO data
static GLfloat *pinsVboCurrent;  // pointer to the data for the current vertices
static GLuint pinsVboIndex = 0;  // index of the current object being rendered
static GLuint pinsShaderProgram; 
static GLfloat vertex[10];


/*
 * Applies the projection matrix
 */
void R2D_GL3_ApplyProjection(GLfloat orthoMatrix[16], int w, int h) {

  // Use the triangles program object
  glUseProgram(trianglesShaderProgram);

  // Apply the projection matrix to the triangles shader
  glUniformMatrix4fv(
    glGetUniformLocation(trianglesShaderProgram, "u_mvpMatrix"),
    1, GL_FALSE, orthoMatrix
  );

  // Use the textures program object
  glUseProgram(texturesShaderProgram);

  // Apply the projection matrix to the textures shader
  glUniformMatrix4fv(
    glGetUniformLocation(texturesShaderProgram, "u_mvpMatrix"),
    1, GL_FALSE, orthoMatrix
  );

  // Use the pins program object
  glUseProgram(pinsShaderProgram);

  // Apply window dimensions to the pins shader
  glUniform2f(
    glGetUniformLocation(pinsShaderProgram, "winSize"),
    w, h
  );
}


/*
 * Initalize OpenGL
 */
int R2D_GL3_Init() {

  // Enable transparency
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  int loadResult = R2D_GL3_Load_Triangles_Textures();
  if(loadResult != GL_TRUE) {
    return loadResult;
  }
  return R2D_GL3_Load_Pins();
}

/*
 * Initalize OpenGL
 */
int R2D_GL3_Load_Triangles_Textures() {

  // Vertex shader source string
  GLchar vertexSource[] =
    "#version 150 core\n"  // shader version

    "uniform mat4 u_mvpMatrix;"  // projection matrix

    // Input attributes to the vertex shader
    "in vec4 position;"  // position value
    "in vec4 color;"     // vertex color
    "in vec2 texcoord;"  // texture coordinates

    // Outputs to the fragment shader
    "out vec4 Color;"     // vertex color
    "out vec2 Texcoord;"  // texture coordinates

    "void main() {"
    // Send the color and texture coordinates right through to the fragment shader
    "  Color = color;"
    "  Texcoord = texcoord;"
    // Transform the vertex position using the projection matrix
    "  gl_Position = u_mvpMatrix * position;"
    "}";

  // Fragment shader source string
  GLchar fragmentSource[] =
    "#version 150 core\n"  // shader version
    "in vec4 Color;"       // input color from vertex shader
    "out vec4 outColor;"   // output fragment color

    "void main() {"
    "  outColor = Color;"  // pass the color right through
    "}";

  // Fragment shader source string for textures
  GLchar texFragmentSource[] =
    "#version 150 core\n"     // shader version
    "in vec4 Color;"          // input color from vertex shader
    "in vec2 Texcoord;"       // input texture coordinates
    "out vec4 outColor;"      // output fragment color
    "uniform sampler2D tex;"  // 2D texture unit

    "void main() {"
    // Apply the texture unit, texture coordinates, and color
    "  outColor = texture(tex, Texcoord) * Color;"
    "}";

  // Create a vertex array object
  glGenVertexArrays(1, &trianglesVao);
  glBindVertexArray(trianglesVao);

  // Create a vertex buffer object and allocate data
  glGenBuffers(1, &trianglesVbo);
  glBindBuffer(GL_ARRAY_BUFFER, trianglesVbo);
  trianglesVboData = (GLfloat *) malloc(R2D_GL3_TRIANGLES_VBO_CAPACITY * sizeof(GLfloat) * 8);
  trianglesVboCurrent = trianglesVboData;
  glBufferData(GL_ARRAY_BUFFER, R2D_GL3_TRIANGLES_VBO_CAPACITY * sizeof(GLfloat) * 8, NULL, GL_DYNAMIC_DRAW);

  // Load the vertex and fragment shaders
  GLuint vertexShader      = R2D_GL_LoadShader(  GL_VERTEX_SHADER,      vertexSource, "GL3 Vertex");
  GLuint fragmentShader    = R2D_GL_LoadShader(GL_FRAGMENT_SHADER,    fragmentSource, "GL3 Fragment");
  GLuint texFragmentShader = R2D_GL_LoadShader(GL_FRAGMENT_SHADER, texFragmentSource, "GL3 Texture Fragment");

  // Triangle Shader //

  // Create the shader program object
  trianglesShaderProgram = glCreateProgram();

  // Check if program was created successfully
  if (trianglesShaderProgram == 0) {
    R2D_GL_PrintError("Failed to create shader program");
    return GL_FALSE;
  }

  // Attach the shader objects to the program object
  glAttachShader(trianglesShaderProgram, vertexShader);
  glAttachShader(trianglesShaderProgram, fragmentShader);

  // Bind the output color variable to the fragment shader color number
  glBindFragDataLocation(trianglesShaderProgram, 0, "outColor");

  // Link the shader program
  glLinkProgram(trianglesShaderProgram);

  // Check if linked
  R2D_GL_CheckLinked(trianglesShaderProgram, "GL3 shader");

  // Specify the layout of the position vertex data...
  GLint posAttrib = glGetAttribLocation(trianglesShaderProgram, "position");
  glEnableVertexAttribArray(posAttrib);
  glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), 0);

  // ...and the color vertex data
  GLint colAttrib = glGetAttribLocation(trianglesShaderProgram, "color");
  glEnableVertexAttribArray(colAttrib);
  glVertexAttribPointer(colAttrib, 4, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat)));

  // Texture Shader //

  // Create the texture shader program object
  texturesShaderProgram = glCreateProgram();

  // Check if program was created successfully
  if (texturesShaderProgram == 0) {
    R2D_GL_PrintError("Failed to create shader program");
    return GL_FALSE;
  }

  // Attach the shader objects to the program object
  glAttachShader(texturesShaderProgram, vertexShader);
  glAttachShader(texturesShaderProgram, texFragmentShader);

  // Bind the output color variable to the fragment shader color number
  glBindFragDataLocation(texturesShaderProgram, 0, "outColor");

  // Link the shader program
  glLinkProgram(texturesShaderProgram);

  // Check if linked
  R2D_GL_CheckLinked(texturesShaderProgram, "GL3 texture shader");

  // Specify the layout of the position vertex data...
  posAttrib = glGetAttribLocation(texturesShaderProgram, "position");
  glVertexAttribPointer(posAttrib, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), 0);
  glEnableVertexAttribArray(posAttrib);

  // ...and the color vertex data...
  colAttrib = glGetAttribLocation(texturesShaderProgram, "color");
  glVertexAttribPointer(colAttrib, 4, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat)));
  glEnableVertexAttribArray(colAttrib);

  // ...and the texture coordinates
  GLint texAttrib = glGetAttribLocation(texturesShaderProgram, "texcoord");
  glVertexAttribPointer(texAttrib, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (void*)(6 * sizeof(GLfloat)));
  glEnableVertexAttribArray(texAttrib);

  // Clean up
  glDeleteShader(vertexShader);
  glDeleteShader(fragmentShader);
  glDeleteShader(texFragmentShader);

  return GL_TRUE;
}

/*
 * Initalize Pins Shader
 */
int R2D_GL3_Load_Pins() {

  GLchar vertexSource[] =
    "#version 330 core\n"
    "layout (location = 0) in vec2 pos0;"
    "layout (location = 1) in vec2 pos1;"
    "layout (location = 2) in float thick;"
    "layout (location = 3) in float rad;"
    "layout (location = 4) in vec4 col;"

    "uniform vec2 winSize;"

    "out VS_OUT {"
        "mat2 rot;"
        "float width;"
        "float height;"
        "vec4 color;"
    "} vs_out;"

    "void main()"
    "{"
        "float ar = winSize.x / winSize.y;"
        "float x = (pos1.x + pos0.x) / winSize.x - 1;"
        "float y = -(pos1.y + pos0.y) / winSize.y + 1;"
        "float length = sqrt(pow(pos1.x - pos0.x, 2.0) + pow(pos1.y - pos0.y, 2.0));"
        "if(thick > 0) {"
        "  gl_Position = vec4(x, y, rad, 1);"
        "  if(length > 0) {"
        "    float c = (pos1.x - pos0.x) / length;"
        "    float s = (pos1.y - pos0.y) / length;"
        "    vs_out.rot = mat2(c, -s * ar, s / ar, c);"
        "  } else {"
        "    vs_out.rot = mat2(1, 0, 0, 1);"
        "  }"
        "  vs_out.width = (length + thick) / winSize.x;"
        "  vs_out.height = thick / winSize.y;"
        "} else {"
        "  gl_Position = vec4(x, y, rad, 0);"
        "  vs_out.rot = mat2(1, 0, 0, 1);"
        "  vs_out.width = rad / winSize.x;"
        "  vs_out.height = rad / winSize.y;"
        "}"
        "vs_out.color = col;"
    "}";

  GLchar geometrySource[] =
    "#version 330 core\n"
    "layout (points) in;"
    "layout (triangle_strip, max_vertices = 36) out;"

    "in VS_OUT {"
    "    mat2 rot;"
    "    float width;"
    "    float height;"
    "    vec4 color;"
    "} gs_in[];"

    "uniform vec2 winSize;"

    "out vec4 c;"
    "out vec4 p;"

    "void emit(vec4 pos)"
    "{"
    "  vec4 position = vec4(pos.xy, 0, 1);"
    "  vec2 r = vec2(pos.z / winSize.x, pos.z / winSize.y);"
    "  vec4 c1 = gs_in[0].color;"
    "  float smr = 1.5;"
    "  if(pos.a > 0) {"
    "    vec4 c0 = vec4(gs_in[0].color.rgb, 0);"
    "    vec2 sm = vec2(3.0 / winSize.x, 3.0 / winSize.y);"
    "    if(r.x < sm.x || r.y < sm.y) {"
    "      r = sm;"
    "    }"
    "    p = vec4(0,0,0,0);"
    "    c = c0;"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x, -gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x, -gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    c = c1;"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x, -gs_in[0].height + sm.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x, -gs_in[0].height + sm.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x, gs_in[0].height - sm.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x, gs_in[0].height - sm.y), 0 ,0);"
    "    EmitVertex();"
    "    c = c0;"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x, gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x, gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    EndPrimitive();"

    "    c = c0;"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width,  gs_in[0].height - r.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width, -gs_in[0].height + r.y), 0 ,0);"
    "    EmitVertex();"
    "    c = c1;"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + sm.x,  gs_in[0].height - r.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + sm.x, -gs_in[0].height + r.y), 0 ,0);"
    "    EmitVertex();"
    "    if(r.x > sm.x || r.y > sm.y) {"
    "      gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x,  gs_in[0].height - r.y), 0 ,0);"
    "      EmitVertex();"
    "      gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x, -gs_in[0].height + r.y), 0 ,0);"
    "      EmitVertex();"
    "    }"
    "    EndPrimitive();"

    "    c = c0;"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width,  gs_in[0].height - r.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width, -gs_in[0].height + r.y), 0 ,0);"
    "    EmitVertex();"
    "    c = c1;"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - sm.x,  gs_in[0].height - r.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - sm.x, -gs_in[0].height + r.y), 0 ,0);"
    "    EmitVertex();"
    "    if(r.x > sm.x || r.y > sm.y) {"
    "      gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x,  gs_in[0].height - r.y), 0 ,0);"
    "      EmitVertex();"
    "      gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x, -gs_in[0].height + r.y), 0 ,0);"
    "      EmitVertex();"
    "    }"
    "    EndPrimitive();"
    "  }"

    // "  if(pos.z > 0) {"
    "    vec4 p0;"
    "    c = c1;"
    "    float rad = pos.z / 2;"
    "    if(rad < smr) {"
    "      rad = smr;"
    "    }"
    "    p0 = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x,  gs_in[0].height - r.y), 0, 0);"
    "    p = vec4((p0.x + 1) / 2 * winSize.x,  (p0.y + 1) / 2 * winSize.y, rad, smr);"
    "    gl_Position = p0;"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x,  gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width,  gs_in[0].height - r.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width,  gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    EndPrimitive();"

    "    p0 = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x, -gs_in[0].height + r.y), 0 ,0);"
    "    p = vec4((p0.x + 1) / 2 * winSize.x,  (p0.y + 1) / 2 * winSize.y, rad, smr);"
    "    gl_Position = p0;"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width - r.x, -gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width, -gs_in[0].height + r.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2( gs_in[0].width, -gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    EndPrimitive();"

    "    p0 = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x,  gs_in[0].height - r.y), 0 ,0);"
    "    p = vec4((p0.x + 1) / 2 * winSize.x,  (p0.y + 1) / 2 * winSize.y, rad, smr);"
    "    gl_Position = p0;"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x,  gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width,  gs_in[0].height - r.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width,  gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    EndPrimitive();"

    "    p0 = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x, -gs_in[0].height + r.y), 0 ,0);"
    "    p = vec4((p0.x + 1) / 2 * winSize.x,  (p0.y + 1) / 2 * winSize.y, rad, smr);"
    "    gl_Position = p0;"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width + r.x, -gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width, -gs_in[0].height + r.y), 0 ,0);"
    "    EmitVertex();"
    "    gl_Position = position + vec4(gs_in[0].rot * vec2(-gs_in[0].width, -gs_in[0].height), 0 ,0);"
    "    EmitVertex();"
    "    EndPrimitive();"
    // "  }"
    "}"

    "void main() {"
    "    emit(gl_in[0].gl_Position);"
    "}";

  GLchar fragmentSource[] =
    "#version 330 core\n"
    "in vec4 c;"
    "in vec4 p;"
    "out vec4 color;"

    "void main()"
    "{"
    "    if(p.z > 0) {"
    "        float x = p.x - gl_FragCoord.x;"
    "        float y = p.y - gl_FragCoord.y;"
    "        float d = p.z - sqrt(x * x + y * y);"
    "        if(d < 0) {"
    //"          if(d < -4) color = vec4(0,0,0,0);"
    // "          else color = vec4(0,0,0,1);"
    "          color = vec4(0,0,0,0);"
    "        } else if(d <= p.a) color = vec4(c.rgb, c.a * d / p.a);"
    "        else color = c;"
    "    } else color = c;"
    "}";

  // Create a vertex array object
  glGenVertexArrays(1, &pinsVao);
  glBindVertexArray(pinsVao);
  glGenBuffers(1, &pinsVbo);
  glBindBuffer(GL_ARRAY_BUFFER, pinsVbo);


  pinsVboData = (GLfloat *) malloc(R2D_GL3_PINS_VBO_CAPACITY * sizeof(GLfloat) * 10);
  pinsVboCurrent = pinsVboData;
  glBufferData(GL_ARRAY_BUFFER, R2D_GL3_PINS_VBO_CAPACITY * sizeof(GLfloat) * 10, NULL, GL_DYNAMIC_DRAW);

  // Load the vertex, geometry and fragment shaders
  GLuint vertexShader      = R2D_GL_LoadShader(  GL_VERTEX_SHADER, vertexSource, "GL3 Pin Vertex");
  GLuint geometryShader = R2D_GL_LoadShader(GL_GEOMETRY_SHADER, geometrySource, "GL3 Pin Geometry");
  GLuint fragmentShader    = R2D_GL_LoadShader(GL_FRAGMENT_SHADER, fragmentSource, "GL3 Pin Fragment");
  
  // Create the shader program object
  pinsShaderProgram = glCreateProgram();

  // Check if program was created successfully
  if (pinsShaderProgram == 0) {
    R2D_GL_PrintError("Failed to create shader program");
    return GL_FALSE;
  }

  // Attach the shader objects to the program object
  glAttachShader(pinsShaderProgram, vertexShader);
  glAttachShader(pinsShaderProgram, geometryShader);
  glAttachShader(pinsShaderProgram, fragmentShader);

  // Link the shader program
  glLinkProgram(pinsShaderProgram);

  // Check if linked
  R2D_GL_CheckLinked(pinsShaderProgram, "GL3 pin shader");

  glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 10 * sizeof(GLfloat), (void*)0);
  glEnableVertexAttribArray(0);

  glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 10 * sizeof(GLfloat), (void*)(2 * sizeof(GLfloat)));
  glEnableVertexAttribArray(1);

  glVertexAttribPointer(2, 1, GL_FLOAT, GL_FALSE, 10 * sizeof(GLfloat), (void*)(4 * sizeof(GLfloat)));
  glEnableVertexAttribArray(2);

  glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, 10 * sizeof(GLfloat), (void*)(5 * sizeof(GLfloat)));
  glEnableVertexAttribArray(3);

  glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, 10 * sizeof(GLfloat), (void*)(6 * sizeof(GLfloat)));
  glEnableVertexAttribArray(4);

  glDeleteShader(vertexShader);
  glDeleteShader(geometryShader);
  glDeleteShader(fragmentShader);    

  // If successful, return true
  return GL_TRUE;
}


/*
 * Render the vertex buffer and reset it
 */
void R2D_GL3_FlushBuffers() {
  // Bind to the vertex buffer object and update its dat
  glBindVertexArray(trianglesVao);
  glBindBuffer(GL_ARRAY_BUFFER, trianglesVbo);
  glBufferSubData(GL_ARRAY_BUFFER, 0, trianglesVboIndex * sizeof(GLfloat) * 8, trianglesVboData);

  glBindVertexArray(pinsVao);
  glBindBuffer(GL_ARRAY_BUFFER, pinsVbo);
  glBufferSubData(GL_ARRAY_BUFFER, 0, pinsVboIndex * sizeof(GLfloat) * 10, pinsVboData);

  GLuint trianglesOffset = 0, ti = 0, pinsOffset = 0, pi = 0;
  GLuint lastVertex = vertices[0];

  for (GLuint i = 0; i <= verticesIndex; i++) {
    if(lastVertex == R2D_GL3_PIN_ID) {
      ++pi;
    } else {
      ++ti;
    }
    if(lastVertex != vertices[i] || i == verticesIndex) {
      if(lastVertex == R2D_GL3_PIN_ID) {
        glBindVertexArray(pinsVao);
        glUseProgram(pinsShaderProgram);
        glBindBuffer(GL_ARRAY_BUFFER, pinsVbo);
        glDrawArrays(GL_POINTS, pinsOffset, pi - pinsOffset);
        pinsOffset = pi;
      } else if(lastVertex == R2D_GL3_TRIANGLE_ID) {
        glBindVertexArray(trianglesVao);
        glUseProgram(trianglesShaderProgram);
        glBindBuffer(GL_ARRAY_BUFFER, trianglesVbo);
        glDrawArrays(GL_TRIANGLES, trianglesOffset, ti - trianglesOffset);
        trianglesOffset = ti;
      } else {
        glBindVertexArray(trianglesVao);
        glUseProgram(texturesShaderProgram);
        glBindBuffer(GL_ARRAY_BUFFER, trianglesVbo);
        glBindTexture(GL_TEXTURE_2D, lastVertex);
        glDrawArrays(GL_TRIANGLES, trianglesOffset, ti - trianglesOffset);
        trianglesOffset = ti;
      }

      lastVertex = vertices[i];
    }
  }

  // Reset the buffer object index and data pointer
  verticesIndex = trianglesVboIndex = pinsVboIndex = 0;
  trianglesVboCurrent = trianglesVboData;
  pinsVboCurrent = pinsVboData;
}


/*
 * Draw triangle
 */
void R2D_GL3_DrawTriangle(GLfloat x1, GLfloat y1,
                          GLfloat r1, GLfloat g1, GLfloat b1, GLfloat a1,
                          GLfloat x2, GLfloat y2,
                          GLfloat r2, GLfloat g2, GLfloat b2, GLfloat a2,
                          GLfloat x3, GLfloat y3,
                          GLfloat r3, GLfloat g3, GLfloat b3, GLfloat a3) {

  // If buffer is full, flush it
  if (trianglesVboIndex + 3 >= R2D_GL3_TRIANGLES_VBO_CAPACITY) R2D_GL3_FlushBuffers();

  // Set the triangle data into a formatted array
  GLfloat v[24] =
    { x1, y1, r1, g1, b1, a1, 0, 0,
      x2, y2, r2, g2, b2, a2, 0, 0,
      x3, y3, r3, g3, b3, a3, 0, 0 };

  // Copy the vertex data into the current position of the buffer
  memcpy(trianglesVboCurrent, v, sizeof(v));

  // Increment the buffer object index and the vertex data pointer for next use
  vertices[verticesIndex] = vertices[verticesIndex + 1] = vertices[verticesIndex + 2] = R2D_GL3_TRIANGLE_ID;
  verticesIndex += 3;
  trianglesVboIndex += 3;
  trianglesVboCurrent = (GLfloat *)((char *)trianglesVboCurrent + (sizeof(GLfloat) * 24));
}


/*
 * Draw a texture (New method with vertices pre-calculated)
 */
void R2D_GL3_DrawTexture(GLfloat coordinates[], GLfloat texture_coordinates[], GLfloat color[], int texture_id) {
  // If buffer is full, flush it
  if (trianglesVboIndex + 6 >= R2D_GL3_TRIANGLES_VBO_CAPACITY) R2D_GL3_FlushBuffers();

  // There are 6 vertices for a square as we are rendering two Triangles to make up our square:
  // Triangle one: Top left, Top right, Bottom right
  // Triangle two: Bottom right, Bottom left, Top left
  GLfloat v[48] = {
    coordinates[0], coordinates[1], color[0], color[1], color[2], color[3], texture_coordinates[0], texture_coordinates[1],
    coordinates[2], coordinates[3], color[0], color[1], color[2], color[3], texture_coordinates[2], texture_coordinates[3],
    coordinates[4], coordinates[5], color[0], color[1], color[2], color[3], texture_coordinates[4], texture_coordinates[5],
    coordinates[4], coordinates[5], color[0], color[1], color[2], color[3], texture_coordinates[4], texture_coordinates[5],
    coordinates[6], coordinates[7], color[0], color[1], color[2], color[3], texture_coordinates[6], texture_coordinates[7],
    coordinates[0], coordinates[1], color[0], color[1], color[2], color[3], texture_coordinates[0], texture_coordinates[1],
  };

  // Copy the vertex data into the current position of the buffer
  memcpy(trianglesVboCurrent, v, sizeof(v));

  vertices[verticesIndex] = vertices[verticesIndex + 1] = vertices[verticesIndex + 2] = 
    vertices[verticesIndex + 3] = vertices[verticesIndex + 4] = vertices[verticesIndex + 5] = texture_id;
  verticesIndex += 6;
  trianglesVboIndex += 6;
  trianglesVboCurrent = (GLfloat *)((char *)trianglesVboCurrent + (sizeof(GLfloat) * 48));
}

/*
 * Draw a pin
 */
void R2D_GL3_DrawPin(GLfloat x1, GLfloat y1, GLfloat x2, GLfloat y2,
                    GLfloat width, GLfloat round,
                    GLfloat r, GLfloat g, GLfloat b, GLfloat a) {
  // If buffer is full, flush it
  if (pinsVboIndex + 1 >= R2D_GL3_PINS_VBO_CAPACITY) R2D_GL3_FlushBuffers();

  GLfloat v[10] = { x1, y1, x2, y2, width, round, r, g, b, a};

  // Copy the vertex data into the current position of the buffer
  memcpy(pinsVboCurrent, v, sizeof(v));

  vertices[verticesIndex] = R2D_GL3_PIN_ID;
  verticesIndex += 1;
  pinsVboIndex += 1;
  pinsVboCurrent = (GLfloat *)((char *)pinsVboCurrent + (sizeof(GLfloat) * 10));
}


#endif
