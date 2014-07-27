import std.stdio;
import std.string;
import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

import dogl;


void initializeProgram()
{
   Shader vertexShader;
   Shader fragmentShader;

   vertexShader.init(GL_VERTEX_SHADER, strVertexShader);
   fragmentShader.init(GL_FRAGMENT_SHADER, strFragmentShader);

   theProgram.init(vertexShader, fragmentShader);
}


void initializeVertexBuffer()
{
   glGenBuffers(1, &positionBufferObject);

   glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
   glBufferData(GL_ARRAY_BUFFER, vertexPositions.sizeof, vertexPositions.ptr, GL_STATIC_DRAW);
   glBindBuffer(GL_ARRAY_BUFFER, 0);
}


void init()
{
   initializeProgram();
   initializeVertexBuffer();

   glGenVertexArrays(1, &vao);
   glBindVertexArray(vao);
}



immutable string strVertexShader = `
   #version 330
   layout(location = 0) in vec4 position;
   void main()
   {
      gl_Position = position;
   }
`;

immutable string strFragmentShader = `
   #version 330
   out vec4 outputColor;
   void main()
   {
      outputColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
   }
`;


SDL_Window* theWindow;
SDL_GLContext theContext;
Program theProgram;

GLuint positionBufferObject;
GLuint vao;

enum SCREEN_WIDTH = 1024;
enum SCREEN_HEIGHT = 768;

immutable float[12] vertexPositions = [
   0.75f, 0.75f, 0.0f, 1.0f,
   0.75f, -0.75f, 0.0f, 1.0f,
   -0.75f, -0.75f, 0.0f, 1.0f,
];


void main()
{
   DerelictSDL2.load();

   DerelictGL3.load();

   auto success = true;

   // Window, please
   if (SDL_Init(SDL_INIT_VIDEO) < 0)
   {
      writefln("SDL could not initialize! SDL Error: %s", SDL_GetError());
      return;
   }

   //Use OpenGL 3.1
   SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
   SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
   SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,
                       SDL_GL_CONTEXT_PROFILE_CORE);

   theWindow = SDL_CreateWindow("D/SDL/OpenGL Experiments",
                                SDL_WINDOWPOS_UNDEFINED,
                                SDL_WINDOWPOS_UNDEFINED,
                                SCREEN_WIDTH,
                                SCREEN_HEIGHT,
                                SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
   if (theWindow is null )
   {
      writefln("Window could not be created! SDL Error: %s\n", SDL_GetError());
      return;
   }

   // Create context
   theContext = SDL_GL_CreateContext(theWindow);
   if (theContext is null)
   {
      printf("OpenGL context could not be created! SDL Error: %s\n",
             SDL_GetError());
      return;
   }

   // Now that we have a context, we can reload the OpenGL bindings, and we'll
   // get all the OpenGL 3+ stuff
   DerelictGL3.reload();

   // Use Vsync
   if (SDL_GL_SetSwapInterval(1) < 0)
      printf("Warning: Unable to set VSync! SDL Error: %s\n", SDL_GetError());

   init();

   // The main loop
   while (true)
   {
      // Handle events
      SDL_Event e;
      while (SDL_PollEvent(&e) != 0)
      {
         if (e.type == SDL_QUIT || e.type == SDL_KEYDOWN)
            return;
      }

      // Draw!
      glClearColor(0.0, 0.4, 0.3, 0.0);
      glClear(GL_COLOR_BUFFER_BIT);

      theProgram.use();

      glBindBuffer(GL_ARRAY_BUFFER, positionBufferObject);
      glEnableVertexAttribArray(0);
      glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, null);

      glDrawArrays(GL_TRIANGLES, 0, 3);

      glDisableVertexAttribArray(0);
      theProgram.unuse();

      SDL_GL_SwapWindow(theWindow);
   }
}
