/**
 * Quick and dirty (but improving!) OpenGL bindings for D.
 *
 * Author: Leandro Motta Barros
 */

module dogl;

import std.string;
import std.c.stdlib;
import derelict.opengl3.gl3;


/**
 * Boilerplate code for reference-counted OpenGL objects.
 *
 * This shall be mixed into the OpenGL object wrapper $(D struct)s. These $(D
 * struct)s shall call the $(D initRefCount()) method upon initialization and
 * they also should implement a $(D freeResources()) method, which the
 * boilerplate code will call when the last reference to the object is gone.
 */
mixin template RefCountedBoilerplate()
{
   /// Pointer to the reference count.
   private int* refCount;

   /// Allocates memory for the reference counter, sets it to one.
   private void initRefCount()
   {
      refCount = cast(int*)malloc(typeof(*refCount).sizeof);
      *refCount = 1;
   }

   /// Is this object's reference counter initialized?
   private @property bool isRefCountInited()
   {
      return refCount !is null;
   }

   /**
    * Decrements the reference counter; if it reaches zero, frees the reference
    * counter memory and calls $(D freeResources()).
    */
   public ~this()
   {
      if (!isRefCountInited)
         return;

      --(*refCount);

      if (*refCount == 0)
      {
         freeResources();
         free(refCount);
      }
   }

   /// Increments the reference counter.
   public this(this)
   in
   {
      assert(isRefCountInited,
             "Cannot copy uninitialized reference-counted objects");
   }
   body
   {
      ++(*refCount);
   }
}


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
