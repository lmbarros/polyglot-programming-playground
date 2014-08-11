module Example_04_GPUAnimation;

import std.stdio;
import std.string;
import derelict.sdl2.sdl;
import derelict.opengl3.gl3;

import dogl;
import dsdl;


void initializeProgram()
{
   Shader vertexShader;
   Shader fragmentShader;

   vertexShader.initFromFile(
      GL_VERTEX_SHADER, "04_GPUAnimation/turn_around.vert");
   fragmentShader.initFromFile(
      GL_FRAGMENT_SHADER, "04_GPUAnimation/anim_colors.frag");

   theProgram.init(vertexShader, fragmentShader);

   theProgram.setUniform("loopDuration", 5.0);
   theProgram.setUniform("fragLoopDuration", 8.0);
}


void initializeVertexBuffer()
{
   dataBufferObject.init();
   dataBufferObject.bind();

   glBufferData(
      GL_ARRAY_BUFFER, vertexData.sizeof, vertexData.ptr, GL_STREAM_DRAW);

   dataBufferObject.unbind();
}


void init()
{
   initializeProgram();
   initializeVertexBuffer();

   glGenVertexArrays(1, &vao);
   glBindVertexArray(vao);
}


Program theProgram;

VertexBufferObject dataBufferObject;
GLuint vao;

enum SCREEN_WIDTH = 1024;
enum SCREEN_HEIGHT = 768;

immutable float[24] vertexData = [
     0.0f,  0.5f,   0.0f, 1.0f,
     0.5f, -0.366f, 0.0f, 1.0f,
    -0.5f, -0.366f, 0.0f, 1.0f,
     1.0f,  0.0f,   0.0f, 1.0f,
     0.0f,  1.0f,   0.0f, 1.0f,
     0.0f,  0.0f,   1.0f, 1.0f,
];


void main()
{
   auto appManager = SDLAppManager(SDL_INIT_VIDEO);

   // Window, please
   auto window = Window("GPU Animation",
                        SDL_WINDOWPOS_UNDEFINED,
                        SDL_WINDOWPOS_UNDEFINED,
                        SCREEN_WIDTH,
                        SCREEN_HEIGHT,
                        SDL_WINDOW_OPENGL);
   init();

   // The main loop
   auto keepRunning = true;

   appManager.addHandler(
      SDL_QUIT,
      delegate(in ref SDL_Event event)
      {
         keepRunning = false;
      });

   appManager.addHandler(
      SDL_KEYUP,
      delegate(in ref SDL_Event event)
      {
         if (event.key.keysym.sym == SDLK_ESCAPE)
         keepRunning = false;
      });

   appManager.addDrawHandler(
      delegate(double deltaTime, double totalTime)
      {
         glClearColor(0.0, 0.4, 0.3, 0.0);
         glClear(GL_COLOR_BUFFER_BIT);

         theProgram.use();

         theProgram.setUniform("time", SDL_GetTicks() / 1000.0);

         dataBufferObject.bind();

         glEnableVertexAttribArray(0); // positions
         glEnableVertexAttribArray(1); // colors

         glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, null);
         glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, cast(void*)(48));

         glDrawArrays(GL_TRIANGLES, 0, 3);

         glDisableVertexAttribArray(0);
         glDisableVertexAttribArray(1);

         theProgram.unuse();

         window.swapBuffers();
      });

   appManager.run(delegate() { return keepRunning; });
}
