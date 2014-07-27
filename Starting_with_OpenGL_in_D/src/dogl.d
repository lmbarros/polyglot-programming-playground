// Quick and dirty D OpenGL bindings

module dogl;

import std.string;
import std.c.stdlib;
import derelict.opengl3.gl3;


public struct VertexBufferObject
{
   private struct Impl
   {
      private GLuint buffer = 0;
      private int refCount = 0;
   }

   private Impl* _data = null;

   public void init()
   {
      _data = cast(Impl*)malloc(Impl.sizeof);
      _data.refCount = 1;
      glGenBuffers(1, &_data.buffer);
   }

   public this(this)
   {
      if (_data is null)
         return;
      ++_data.refCount;
   }

   public ~this()
   {
      if (_data is null)
         return;

      --_data.refCount;

      if (_data.refCount == 0)
      {
         // glDeleteBuffers() unbinds the buffer object if it is bound
         glDeleteBuffers(1, &_data.buffer);

         free(_data);
      }
   }


   public void bind()
   in
   {
      assert(_data !is null);
   }
   body
   {
      glBindBuffer(GL_ARRAY_BUFFER, _data.buffer);
   }

   public void unbind()
   in
   {
      assert(_data !is null);
   }
   body
   {
      glBindBuffer(GL_ARRAY_BUFFER, 0);
   }
}


public struct Shader
{
   private struct Impl
   {
      private GLuint shader = 0;
      private int refCount = 0;
   }

   private Impl* _data = null;

   public void init(GLenum shaderType, string shaderText)
   {
      _data = cast(Impl*)malloc(Impl.sizeof);
      _data.refCount = 1;

      _data.shader = glCreateShader(shaderType);
      const st = shaderText.toStringz;
      glShaderSource(_data.shader, 1, &st, null);
      glCompileShader(_data.shader);

      GLint status;
      glGetShaderiv(_data.shader, GL_COMPILE_STATUS, &status);

      if (status == GL_FALSE)
      {
         GLint infoLogLength;
         glGetShaderiv(_data.shader, GL_INFO_LOG_LENGTH, &infoLogLength);

         GLchar[] strInfoLog = new GLchar[infoLogLength + 1];
         glGetShaderInfoLog(_data.shader, infoLogLength, null, strInfoLog.ptr);

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

   public this(this)
   {
      if (_data is null)
         return;
      ++_data.refCount;
   }

   public ~this()
   {
      if (_data is null)
         return;

      --_data.refCount;

      if (_data.refCount == 0)
      {
         glDeleteShader(_data.shader);
         free(_data);
      }
   }
}



public struct Program
{
   private struct Impl
   {
      private GLuint program = 0;
      private int refCount = 0;
   }

   private Impl* _data = null;

   public void init(Shader[] shaders...)
   in
   {
      assert(shaders.length > 0);
   }
   body
   {
      _data = cast(Impl*)malloc(Impl.sizeof);
      _data.refCount = 1;

      _data.program = glCreateProgram();

      foreach (shader; shaders)
         glAttachShader(_data.program, shader._data.shader);

      glLinkProgram(_data.program);

      GLint status;
      glGetProgramiv(_data.program, GL_LINK_STATUS, &status);
      if (status == GL_FALSE)
      {
         GLint infoLogLength;
         glGetProgramiv(_data.program, GL_INFO_LOG_LENGTH, &infoLogLength);

         GLchar[] strInfoLog = new GLchar[infoLogLength + 1];
         glGetProgramInfoLog(_data.program, infoLogLength,
                             null, strInfoLog.ptr);
         throw new Exception(format("Shader linker error: %s", strInfoLog));
      }

      foreach (shader; shaders)
         glDetachShader(_data.program, shader._data.shader);
   }

   public this(this)
   {
      if (_data is null)
         return;
      ++_data.refCount;
   }

   public ~this()
   {
      if (_data is null)
         return;

      --_data.refCount;

      if (_data.refCount == 0)
      {
         glDeleteProgram(_data.program);
         free(_data);
      }
   }

   public void use()
   in
   {
      assert(_data !is null);
   }
   body
   {
      glUseProgram(_data.program);
   }

   public void unuse()
   in
   {
      assert(_data !is null);
   }
   body
   {
      glUseProgram(0);
   }
}
