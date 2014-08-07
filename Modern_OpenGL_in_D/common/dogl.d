/**
 * Quick and dirty (but improving!) OpenGL wrappers for D.
 *
 * Author: Leandro Motta Barros
 */

module dogl;

import std.string;
import std.c.stdlib;
import derelict.opengl3.gl3;
import util;


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

   public void initFromString(GLenum shaderType, string shaderText)
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

   public void initFromFile(GLenum shaderType, string path)
   {
      import std.file;

      string shaderString;

      try
      {
         shaderString = readText(path);
      }
      catch (Exception e)
      {
         throw new Exception(
            format("Error reading shader from file: %s", e.msg));
      }

      initFromString(shaderType, shaderString);
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

   // Also makes this the currently used program
   private GLint getUniformLocation(string name)
   {
      const uniformLoc = glGetUniformLocation(program, name.toStringz);
      if (uniformLoc < 0)
         throw new Exception(format("Uniform '%s' not found", name));

      GLint currentProgram;
      glGetIntegerv(GL_CURRENT_PROGRAM, &currentProgram);

      if (currentProgram != program)
         use();

      return uniformLoc;
   }

   // Also makes this the currently used program
   public void setUniform(string name, float x)
   {
      const uniformLoc = getUniformLocation(name);
      glUniform1f(uniformLoc, x);
   }

   // Also makes this the currently used program
   public void setUniform(string name, float x, float y)
   {
      const uniformLoc = getUniformLocation(name);
      glUniform2f(uniformLoc, x, y);
   }
}
