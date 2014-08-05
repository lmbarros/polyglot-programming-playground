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


/**
 * Lotsa things: event handling, main loop, Derelict little dances, you name it.
 */
public struct SDLAppManager
{
   alias eventHandler = void delegate(in ref SDL_Event event);
   alias tickDrawHandler = void delegate(double deltaTime, double totalTime);

   @disable this();

   // Flags passed directly to SDL
   public this(uint flags)
   {
      DerelictSDL2.load();
      DerelictGL3.load();

      if (SDL_Init(flags) < 0)
      {
         throw new Exception(
            format("Error initializing SDL: %s", SDL_GetError()));
      }
   }

   public void run(bool delegate() keepRunning)
   {
      auto prevTime = SDL_GetTicks() / 1000.0;

      while (keepRunning())
      {
         // What time is it?
         const now = SDL_GetTicks() / 1000.0;
         const deltaTime = now - prevTime;
         prevTime = now;

         // Call tick and draw handlers
         foreach (handler; _tickHandlers)
            handler(deltaTime, now);

         foreach (handler; _drawHandlers)
            handler(deltaTime, now);

         // Call event handlers
         SDL_Event event;
         while (SDL_PollEvent(&event) != 0)
         {
            if (event.type in _eventHandlers)
            {
               foreach (handler; _eventHandlers[event.type])
                  handler(event);
            }
         }
      }
   }

   public void addHandler(uint eventType, eventHandler handler)
   {
      if (eventType !in _eventHandlers)
         _eventHandlers[eventType] = [];
      _eventHandlers[eventType] ~= handler;
   }

   public void addTickHandler(tickDrawHandler handler)
   {
      _tickHandlers ~= handler;
   }

   public void addDrawHandler(tickDrawHandler handler)
   {
      _drawHandlers ~= handler;
   }

   private eventHandler[][uint] _eventHandlers;
   private tickDrawHandler[] _tickHandlers;
   private tickDrawHandler[] _drawHandlers;
}
