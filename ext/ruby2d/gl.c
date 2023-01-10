// Ruby 2D OpenGL Functions

#include "ruby2d.h"

// Set to `true` to force OpenGL 2.1 (for testing)
static bool FORCE_GL2 = false;

// Flag set if using OpenGL 2.1
static bool R2D_GL2 = false;

// The orthographic projection matrix for 2D rendering.
// Elements 0 and 5 are set in R2D_GL_SetViewport.
static GLfloat orthoMatrix[16] =
  {    0,    0,     0,    0,
       0,    0,     0,    0,
       0,    0,     0,    0,
   -1.0f, 1.0f, -1.0f, 1.0f };


/*
 * Prints current GL error
 */
void R2D_GL_PrintError(const char *error) {
  R2D_Log(R2D_ERROR, "%s (%d)", error, glGetError());
}


/*
 * Print info about the current OpenGL context
 */
void R2D_GL_PrintContextInfo(R2D_Window *window) {
  R2D_Log(R2D_INFO,
    "OpenGL Context\n"
    "      GL_VENDOR: %s\n"
    "      GL_RENDERER: %s\n"
    "      GL_VERSION: %s\n"
    "      GL_SHADING_LANGUAGE_VERSION: %s",
    window->R2D_GL_VENDOR,
    window->R2D_GL_RENDERER,
    window->R2D_GL_VERSION,
    window->R2D_GL_SHADING_LANGUAGE_VERSION
  );
}


/*
 * Store info about the current OpenGL context
 */
void R2D_GL_StoreContextInfo(R2D_Window *window) {

  window->R2D_GL_VENDOR   = glGetString(GL_VENDOR);
  window->R2D_GL_RENDERER = glGetString(GL_RENDERER);
  window->R2D_GL_VERSION  = glGetString(GL_VERSION);

  // These are not defined in GLES
  #if GLES
    window->R2D_GL_MAJOR_VERSION = 0;
    window->R2D_GL_MINOR_VERSION = 0;
  #else
    glGetIntegerv(GL_MAJOR_VERSION, &window->R2D_GL_MAJOR_VERSION);
    glGetIntegerv(GL_MINOR_VERSION, &window->R2D_GL_MINOR_VERSION);
  #endif

  window->R2D_GL_SHADING_LANGUAGE_VERSION = glGetString(GL_SHADING_LANGUAGE_VERSION);
};


/*
 * Creates a shader object, loads shader string, and compiles.
 * Returns 0 if shader could not be compiled.
 */
GLuint R2D_GL_LoadShader(GLenum type, const GLchar *shaderSrc, const char *shaderName) {

  // Create the shader object
  GLuint shader = glCreateShader(type);

  if (shader == 0) {
    R2D_GL_PrintError("Failed to create shader program");
    return 0;
  }

  // Load the shader source
  glShaderSource(shader, 1, &shaderSrc, NULL);

  // Compile the shader
  glCompileShader(shader);

  // Check the compile status
  GLint compiled;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

  if (!compiled) {
    GLint infoLen = 0;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);

    if (infoLen > 1) {
      char *infoLog = malloc(sizeof(char) * infoLen);
      glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
      printf("Error compiling shader \"%s\":\n%s\n", shaderName, infoLog);
      free(infoLog);
    }

    glDeleteShader(shader);
    return 0;
  }

  return shader;
}


/*
 * Check if shader program was linked
 */
int R2D_GL_CheckLinked(GLuint program, const char *name) {

  GLint linked;
  glGetProgramiv(program, GL_LINK_STATUS, &linked);

  if (!linked) {
    GLint infoLen = 0;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLen);

    if (infoLen > 1) {
      char *infoLog = malloc(sizeof(char) * infoLen);
      glGetProgramInfoLog(program, infoLen, NULL, infoLog);
      printf("Error linking program `%s`: %s\n", name, infoLog);
      free(infoLog);
    }

    glDeleteProgram(program);
    return GL_FALSE;
  }

  return GL_TRUE;
}


/*
 * Calculate the viewport's scaled width and height
 */
void R2D_GL_GetViewportScale(R2D_Window *window, int *w, int *h, double *scale) {

  double s = fmin(
    window->width  / (double)window->viewport.width,
    window->height / (double)window->viewport.height
  );

  *w = window->viewport.width  * s;
  *h = window->viewport.height * s;

  if (scale) *scale = s;
}


/*
 * Sets the viewport and matrix projection
 */
void R2D_GL_SetViewport(R2D_Window *window) {

  int ortho_w = window->viewport.width;
  int ortho_h = window->viewport.height;
  int x, y, w, h;  // calculated GL viewport values

  x = 0; y = 0; w = window->width; h = window->height;

  switch (window->viewport.mode) {

    case R2D_FIXED:
      w = window->orig_width;
      h = window->orig_height;
      y = window->height - h;
      break;

    case R2D_EXPAND:
      ortho_w = w;
      ortho_h = h;
      break;

    case R2D_SCALE:
      R2D_GL_GetViewportScale(window, &w, &h, NULL);
      // Center the viewport
      x = window->width  / 2.0 - w/2.0;
      y = window->height / 2.0 - h/2.0;
      break;

    case R2D_STRETCH:
      break;
  }

  glViewport(x, y, w, h);

  // Set orthographic projection matrix
  orthoMatrix[0] =  2.0f / (GLfloat)ortho_w;
  orthoMatrix[5] = -2.0f / (GLfloat)ortho_h;

  #if GLES
    R2D_GLES_ApplyProjection(orthoMatrix);
  #else
    if (R2D_GL2) {
      R2D_GL2_ApplyProjection(ortho_w, ortho_h);
    } else {
      R2D_GL3_ApplyProjection(orthoMatrix, ortho_w, ortho_h);
    }
  #endif
}


/*
 * Initialize OpenGL
 */
int R2D_GL_Init(R2D_Window *window) {

  // Specify OpenGL contexts and set attributes
  #if GLES
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE,   8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE,  8);
    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
  #else
    // Use legacy OpenGL 2.1
    if (FORCE_GL2) {
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

    // Request an OpenGL 3.3 forward-compatible core profile
    } else {
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    }
  #endif

  // Create and store the OpenGL context
  if (FORCE_GL2) {
    window->glcontext = NULL;
  } else {
    // Ask SDL to create an OpenGL context
    window->glcontext = SDL_GL_CreateContext(window->sdl);
  }

  // Check if a valid OpenGL context was created
  if (window->glcontext) {
    // Valid context found

    // Initialize OpenGL ES 2.0
    #if GLES
      R2D_GLES_Init();
      R2D_GL_SetViewport(window);

    // Initialize OpenGL 3.3+
    #else
      // Initialize GLEW on Windows
      #if WINDOWS
        GLenum err = glewInit();
        if (GLEW_OK != err) R2D_Error("GLEW", glewGetErrorString(err));
      #endif
      R2D_GL3_Init();
      R2D_GL_SetViewport(window);
    #endif

  // Context could not be created
  } else {

    #if GLES
      R2D_Error("GLES / SDL_GL_CreateContext", SDL_GetError());

    #else
      // Try to fallback using an OpenGL 2.1 context
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);

      // Try creating the context again
      window->glcontext = SDL_GL_CreateContext(window->sdl);

      // Check if this context was created
      if (window->glcontext) {
        // Valid context found
        R2D_GL2 = true;
        R2D_GL2_Init();
        R2D_GL_SetViewport(window);

      // Could not create any OpenGL contexts, hard failure
      } else {
        R2D_Error("GL2 / SDL_GL_CreateContext", SDL_GetError());
        R2D_Log(R2D_ERROR, "An OpenGL context could not be created");
        return -1;
      }
    #endif
  }

  // Store the context and print it if diagnostics is enabled
  R2D_GL_StoreContextInfo(window);
  if (R2D_diagnostics) R2D_GL_PrintContextInfo(window);

  return 0;
}


/*
 * Creates a texture for rendering
 */
void R2D_GL_CreateTexture(GLuint *id, GLint internalFormat, GLint format, GLenum type,
                          int w, int h,
                          const GLvoid *data, GLint filter) {

  // If 0, then a new texture; generate name
  if (*id == 0) glGenTextures(1, id);

  // Bind the named texture to a texturing target
  glBindTexture(GL_TEXTURE_2D, *id);

  // Specifies the 2D texture image
  glTexImage2D(
    GL_TEXTURE_2D, 0, internalFormat, w, h,
    0, format, type, data
  );

  // Set the filtering mode
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
}


/*
 * Free a texture
 */
void R2D_GL_FreeTexture(GLuint *id) {
  if (*id != 0) {
    glDeleteTextures(1, id);
    *id = 0;
  }
}


/*
 * Draw a triangle
 */
void R2D_GL_DrawTriangle(GLfloat x1, GLfloat y1,
                         GLfloat r1, GLfloat g1, GLfloat b1, GLfloat a1,
                         GLfloat x2, GLfloat y2,
                         GLfloat r2, GLfloat g2, GLfloat b2, GLfloat a2,
                         GLfloat x3, GLfloat y3,
                         GLfloat r3, GLfloat g3, GLfloat b3, GLfloat a3) {

  #if GLES
    R2D_GLES_DrawTriangle(x1, y1, r1, g1, b1, a1,
                          x2, y2, r2, g2, b2, a2,
                          x3, y3, r3, g3, b3, a3);
  #else
    if (R2D_GL2) {
      R2D_GL2_DrawTriangle(x1, y1, r1, g1, b1, a1,
                           x2, y2, r2, g2, b2, a2,
                           x3, y3, r3, g3, b3, a3);
    } else {
      R2D_GL3_DrawTriangle(x1, y1, r1, g1, b1, a1,
                           x2, y2, r2, g2, b2, a2,
                           x3, y3, r3, g3, b3, a3);
    }
  #endif
}

/*
 * Draw a quad, using two triangles
 */
void R2D_GL_DrawQuad(GLfloat x1, GLfloat y1,
                  GLfloat r1, GLfloat g1, GLfloat b1, GLfloat a1,
                  GLfloat x2, GLfloat y2,
                  GLfloat r2, GLfloat g2, GLfloat b2, GLfloat a2,
                  GLfloat x3, GLfloat y3,
                  GLfloat r3, GLfloat g3, GLfloat b3, GLfloat a3,
                  GLfloat x4, GLfloat y4,
                  GLfloat r4, GLfloat g4, GLfloat b4, GLfloat a4) {

  R2D_GL_DrawTriangle(x1, y1, r1, g1, b1, a1,
                      x2, y2, r2, g2, b2, a2,
                      x3, y3, r3, g3, b3, a3);

  R2D_GL_DrawTriangle(x3, y3, r3, g3, b3, a3,
                      x4, y4, r4, g4, b4, a4,
                      x1, y1, r1, g1, b1, a1);
};


/*
 * Draw a line
 */
void R2D_GL_DrawLine(GLfloat x1, GLfloat y1, GLfloat x2, GLfloat y2, GLfloat width, GLfloat border,
                    GLfloat round_tl, GLfloat round_tr, GLfloat round_bl, GLfloat round_br,
                    GLfloat r, GLfloat g, GLfloat b, GLfloat a,
                    GLfloat br, GLfloat bg, GLfloat bb, GLfloat ba) {
  #if GLES
    R2D_GL_DrawLineQuad(x1, y1, x2, y2, width, r, g, b, a);
  #else
    if (R2D_GL2) {
      R2D_GL_DrawLineQuad(x1, y1, x2, y2, width, r, g, b, a);
    } else {
      R2D_GL3_DrawPin(x1, y1, x2, y2, width, border, round_tl, round_tr, round_bl, round_br, r, g, b, a, br, bg, bb, ba);
    }
  #endif
};

/*
 * Draw a line from a quad
 */
void R2D_GL_DrawLineQuad(GLfloat x1, GLfloat y1, GLfloat x2, GLfloat y2,
                  GLfloat width, GLfloat r, GLfloat g, GLfloat b, GLfloat a) {

  double length = sqrt(powf(x1 - x2, 2) + powf(y1 - y2, 2));
  double x = ((x2 - x1) / length) * width / 2;
  double y = ((y2 - y1) / length) * width / 2;

  R2D_DrawQuad(
    x1 - y, y1 + x, r, g, b, a,
    x1 + y, y1 - x, r, g, b, a,
    x2 + y, y2 - x, r, g, b, a,
    x2 - y, y2 + x, r, g, b, a
  );
};

/*
 * Draw a texture
 */
void R2D_GL_DrawTexture(GLfloat coordinates[], GLfloat texture_coordinates[], GLfloat color[], int texture_id) {
  #if GLES
    R2D_GLES_DrawTexture(coordinates, texture_coordinates, color, texture_id);
  #else
    if (R2D_GL2) {
      R2D_GL2_DrawTexture(coordinates, texture_coordinates, color, texture_id);
    } else {
      R2D_GL3_DrawTexture(coordinates, texture_coordinates, color, texture_id);
    }
  #endif
}


/*
 * Draw a circle
 */
void R2D_GL_DrawCircle(GLfloat x, GLfloat y, GLfloat radius, GLfloat border, int sectors,
                    GLfloat r, GLfloat g, GLfloat b, GLfloat a,
                    GLfloat br, GLfloat bg, GLfloat bb, GLfloat ba) {

  #if GLES
    R2D_GL_DrawCircleTriangles(x, y, radius, sectors, r, g, b, a);
  #else
    if (R2D_GL2) {
      R2D_GL_DrawCircleTriangles(x, y, radius, sectors, r, g, b, a);
    } else {
      R2D_GL3_DrawPin(x, y, x, y, 0, border, radius, radius, radius, radius, r, g, b, a, br, bg, bb, ba);
    }
  #endif
}


/*
 * Draw a circle from triangles
 */
void R2D_GL_DrawCircleTriangles(GLfloat x, GLfloat y, GLfloat radius, int sectors,
                    GLfloat r, GLfloat g, GLfloat b, GLfloat a) {

  double angle = 2 * M_PI / sectors;

  for (int i = 0; i < sectors; i++) {

    GLfloat x1 = x + radius * cos(i * angle);
    GLfloat y1 = y + radius * sin(i * angle);

    GLfloat x2 = x + radius * cos((i - 1) * angle);
    GLfloat y2 = y + radius * sin((i - 1) * angle);

    R2D_GL_DrawTriangle( x,  y, r, g, b, a,
                        x1, y1, r, g, b, a,
                        x2, y2, r, g, b, a);
  }
}


/*
 * Render and flush OpenGL buffers
 */
void R2D_GL_FlushBuffers() {
  // Only implemented in our OpenGL 3.3+ and ES 2.0 renderers
  #if GLES
    R2D_GLES_FlushBuffers();
  #else
    if (!R2D_GL2) R2D_GL3_FlushBuffers();
  #endif
}


/*
 * Clear buffers to given color values
 */
void R2D_GL_Clear(R2D_Color clr) {
  glClearColor(clr.r, clr.g, clr.b, clr.a);
  glClear(GL_COLOR_BUFFER_BIT);
}
