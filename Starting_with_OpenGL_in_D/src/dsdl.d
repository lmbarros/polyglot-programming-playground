/**
 * Quick and dirty (but improving!) SDL wrappers for D.
 *
 * Focus on using SDL for rendering with OpenGL.
 *
 * Author: Leandro Motta Barros
 */

module dsdl;

import std.string;
import std.c.stdlib;
import derelict.sdl2.sdl;
import derelict.opengl3.gl3;
import util;


/**
 * A window, with an associated OpenGL context.
 */
public struct Window
{
   mixin RefCountedBoilerplate;

   // RefCountedBoilerplate works only with reference objects, so let's make
   // sure we really know what a SDL_GLContext is -- and that it is a reference.
   static assert(is(SDL_GLContext == void*));

   /// The SDL window object.
   private SDL_Window* window = null;

   /// The SDL OpenGL context object.
   private SDL_GLContext context = null;

   @disable public this();

   /// Constructs the Window; parameters as passed to SDL.
   public this(string title, int x, int y, int w, int h, uint flags,
               int glMajorVer = 3, int glMinorVer = 3)
   {
      initRefCount();

      // OpenGL context attributes
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, glMajorVer);
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, glMinorVer);
      SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,
                          SDL_GL_CONTEXT_PROFILE_CORE);

      // Create the window
      window = SDL_CreateWindow(title.toStringz, x, y, w, h, flags);
      if (window is null)
      {
         throw new Exception(
            format("Error creating window: %s", SDL_GetError()));
      }

      scope(failure)
         SDL_DestroyWindow(window);

      // Create the OpenGL context
      context = SDL_GL_CreateContext(window);
      if (context is null)
      {
         throw new Exception(
            format("Error creating OpenGL context: %s", SDL_GetError()));
      }

      // Now that we have a context, we can reload the OpenGL bindings, and
      // we'll get all the OpenGL 3+ stuff
      DerelictGL3.reload();

      // Enable VSync (TODO: Shouldn't be an error)
      if (SDL_GL_SetSwapInterval(1) < 0)
         throw new Exception(format("Unable to set VSync: %s", SDL_GetError()));
   }

   private void freeResources()
   {
      SDL_GL_DeleteContext(context);
      SDL_DestroyWindow(window);
   }

   /// Swap buffers; make things appear.
   public void swapBuffers()
   {
      SDL_GL_SwapWindow(window);
   }
}



/+

/// A Vertex Buffer Object, AKA VBO.
public struct VertexBufferObject
{
   mixin RefCountedBoilerplate;

   /// The buffer object itself, as OpenGL sees it.
   private GLuint buffer = 0;

   /// Initializes the object.
   public void init()
   {
      initRefCount();
      glGenBuffers(1, &buffer);
   }

   /// Frees the object.
   private void freeResources()
   {
      glDeleteBuffers(1, &buffer);
   }

   /// Binds the object to $(D GL_ARRAY_BUFFER).
   public void bind()
   in
   {
      assert(isRefCountInited);
   }
   body
   {
      glBindBuffer(GL_ARRAY_BUFFER, buffer);
   }

   /// Unbinds the object, leaving $(D GL_ARRAY_BUFFER) unbound.
   public void unbind()
   in
   {
      assert(isRefCountInited);
   }
   body
   {
      glBindBuffer(GL_ARRAY_BUFFER, 0);
   }
}



/**
 * A Shader.
 */
public struct Shader
{
   mixin RefCountedBoilerplate;

   /// The shader object itself, as OpenGL sees it.
   private GLuint shader = 0;

   public void init(GLenum shaderType, string shaderText)
   {
      initRefCount();

      shader = glCreateShader(shaderType);
      const st = shaderText.toStringz;
      glShaderSource(shader, 1, &st, null);
      glCompileShader(shader);

      GLint status;
      glGetShaderiv(shader, GL_COMPILE_STATUS, &status);

      if (status == GL_FALSE)
      {
         GLint infoLogLength;
         glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);

         GLchar[] strInfoLog = new GLchar[infoLogLength + 1];
         glGetShaderInfoLog(shader, infoLogLength, null, strInfoLog.ptr);

         string strShaderType;
         switch (shaderType)
         {
            case GL_VERTEX_SHADER:
               strShaderType = "vertex";
               break;
            case GL_GEOMETRY_SHADER:
               strShaderType = "geometry";
               break;
            case GL_FRAGMENT_SHADER:
               strShaderType = "fragment";
               break;
            default:
               strShaderType = "unknown";
         }

         throw new Exception(format("Error compiling %s shader: %s",
                                    strShaderType, strInfoLog));
      }

   }

   private void freeResources()
   {
      glDeleteShader(shader);
   }
}



public struct Program
{
   mixin RefCountedBoilerplate;

   private GLuint program = 0;

   public void init(Shader[] shaders...)
   in
   {
      assert(shaders.length > 0);
   }
   body
   {
      initRefCount();
      program = glCreateProgram();

      foreach (shader; shaders)
         glAttachShader(program, shader.shader);

      glLinkProgram(program);

      GLint status;
      glGetProgramiv(program, GL_LINK_STATUS, &status);
      if (status == GL_FALSE)
      {
         GLint infoLogLength;
         glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);

         GLchar[] strInfoLog = new GLchar[infoLogLength + 1];
         glGetProgramInfoLog(program, infoLogLength, null, strInfoLog.ptr);
         throw new Exception(format("Shader linker error: %s", strInfoLog));
      }

      foreach (shader; shaders)
         glDetachShader(program, shader.shader);
   }

   private void freeResources()
   {
      glDeleteProgram(program);
   }

   public void use()
   in
   {
      assert(isRefCountInited);
   }
   body
   {
      glUseProgram(program);
   }

   public void unuse()
   in
   {
      assert(isRefCountInited);
   }
   body
   {
      glUseProgram(0);
   }
}


+/
