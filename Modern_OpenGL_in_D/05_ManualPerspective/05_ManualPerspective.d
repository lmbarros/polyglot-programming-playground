module Example_05_ManualPerspective;

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
      GL_VERTEX_SHADER, "05_ManualPerspective/manual_perspective.vert");
   fragmentShader.initFromFile(
      GL_FRAGMENT_SHADER, "05_ManualPerspective/colors.frag");

   theProgram.init(vertexShader, fragmentShader);

   theProgram.setUniform("offset", offsetX, offsetY);
   theProgram.setUniform("frustumScale", 1.0);
   theProgram.setUniform("zNear", 1.0);
   theProgram.setUniform("zFar", 3.0);
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

   glEnable(GL_CULL_FACE);
   glCullFace(GL_BACK);
   glFrontFace(GL_CW);
}


Program theProgram;

VertexBufferObject dataBufferObject;
GLuint vao;

enum SCREEN_WIDTH = 1024;
enum SCREEN_HEIGHT = 768;

immutable float[288] vertexData = [

   // Positions
    0.25f,  0.25f, -1.25f, 1.0f,
    0.25f, -0.25f, -1.25f, 1.0f,
   -0.25f,  0.25f, -1.25f, 1.0f,

    0.25f, -0.25f, -1.25f, 1.0f,
   -0.25f, -0.25f, -1.25f, 1.0f,
   -0.25f,  0.25f, -1.25f, 1.0f,

    0.25f,  0.25f, -2.75f, 1.0f,
   -0.25f,  0.25f, -2.75f, 1.0f,
    0.25f, -0.25f, -2.75f, 1.0f,

    0.25f, -0.25f, -2.75f, 1.0f,
   -0.25f,  0.25f, -2.75f, 1.0f,
   -0.25f, -0.25f, -2.75f, 1.0f,

   -0.25f,  0.25f, -1.25f, 1.0f,
   -0.25f, -0.25f, -1.25f, 1.0f,
   -0.25f, -0.25f, -2.75f, 1.0f,

   -0.25f,  0.25f, -1.25f, 1.0f,
   -0.25f, -0.25f, -2.75f, 1.0f,
   -0.25f,  0.25f, -2.75f, 1.0f,

    0.25f,  0.25f, -1.25f, 1.0f,
    0.25f, -0.25f, -2.75f, 1.0f,
    0.25f, -0.25f, -1.25f, 1.0f,

    0.25f,  0.25f, -1.25f, 1.0f,
    0.25f,  0.25f, -2.75f, 1.0f,
    0.25f, -0.25f, -2.75f, 1.0f,

    0.25f,  0.25f, -2.75f, 1.0f,
    0.25f,  0.25f, -1.25f, 1.0f,
   -0.25f,  0.25f, -1.25f, 1.0f,

    0.25f,  0.25f, -2.75f, 1.0f,
   -0.25f,  0.25f, -1.25f, 1.0f,
   -0.25f,  0.25f, -2.75f, 1.0f,

    0.25f, -0.25f, -2.75f, 1.0f,
   -0.25f, -0.25f, -1.25f, 1.0f,
    0.25f, -0.25f, -1.25f, 1.0f,

    0.25f, -0.25f, -2.75f, 1.0f,
   -0.25f, -0.25f, -2.75f, 1.0f,
   -0.25f, -0.25f, -1.25f, 1.0f,

   // Colors
   0.0f, 0.0f, 1.0f, 1.0f,
   0.0f, 0.0f, 1.0f, 1.0f,
   0.0f, 0.0f, 1.0f, 1.0f,

   0.0f, 0.0f, 0.9f, 0.9f,
   0.0f, 0.0f, 0.9f, 0.9f,
   0.0f, 0.0f, 0.9f, 0.9f,

   0.8f, 0.8f, 0.8f, 1.0f,
   0.8f, 0.8f, 0.8f, 1.0f,
   0.8f, 0.8f, 0.8f, 1.0f,

   0.9f, 0.9f, 0.9f, 1.0f,
   0.9f, 0.9f, 0.9f, 1.0f,
   0.9f, 0.9f, 0.9f, 1.0f,

   0.0f, 1.0f, 0.0f, 1.0f,
   0.0f, 1.0f, 0.0f, 1.0f,
   0.0f, 1.0f, 0.0f, 1.0f,

   0.0f, 0.9f, 0.0f, 1.0f,
   0.0f, 0.9f, 0.0f, 1.0f,
   0.0f, 0.9f, 0.0f, 1.0f,

   0.5f, 0.5f, 0.0f, 1.0f,
   0.5f, 0.5f, 0.0f, 1.0f,
   0.5f, 0.5f, 0.0f, 1.0f,

   0.6f, 0.6f, 0.0f, 1.0f,
   0.6f, 0.6f, 0.0f, 1.0f,
   0.6f, 0.6f, 0.0f, 1.0f,

   1.0f, 0.0f, 0.0f, 1.0f,
   1.0f, 0.0f, 0.0f, 1.0f,
   1.0f, 0.0f, 0.0f, 1.0f,

   0.9f, 0.0f, 0.0f, 1.0f,
   0.9f, 0.0f, 0.0f, 1.0f,
   0.9f, 0.0f, 0.0f, 1.0f,

   0.0f, 1.0f, 1.0f, 1.0f,
   0.0f, 1.0f, 1.0f, 1.0f,
   0.0f, 1.0f, 1.0f, 1.0f,

   0.0f, 0.9f, 0.9f, 1.0f,
   0.0f, 0.9f, 0.9f, 1.0f,
   0.0f, 0.9f, 0.9f, 1.0f,
];


float offsetX = 0.5;
float offsetY = 0.5;

void main()
{
   auto appManager = SDLAppManager(SDL_INIT_VIDEO);

   // Window, please
   auto window = Window("Manual Perspective",
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
         switch (event.key.keysym.sym)
         {
            case SDLK_ESCAPE:
               keepRunning = false;
               break;

            case SDLK_LEFT: offsetX -= 0.05; break;
            case SDLK_RIGHT: offsetX += 0.05; break;
            case SDLK_UP: offsetY += 0.05; break;
            case SDLK_DOWN: offsetY -= 0.05; break;
         }

         theProgram.use();
         theProgram.setUniform("offset", offsetX, offsetY);
         theProgram.unuse();
      });

   appManager.addDrawHandler(
      delegate(double deltaTime, double totalTime)
      {
         glClearColor(0.0, 0.4, 0.3, 0.0);
         glClear(GL_COLOR_BUFFER_BIT);

         theProgram.use();

         dataBufferObject.bind();

         glEnableVertexAttribArray(0); // positions
         glEnableVertexAttribArray(1); // colors

         const colorData = vertexData.sizeof / 2;
         glVertexAttribPointer(
            0, 4, GL_FLOAT, GL_FALSE, 0, null);
         glVertexAttribPointer(
            1, 4, GL_FLOAT, GL_FALSE, 0, cast(void*)(colorData));

         glDrawArrays(GL_TRIANGLES, 0, 36);

         glDisableVertexAttribArray(0);
         glDisableVertexAttribArray(1);

         theProgram.unuse();

         window.swapBuffers();
      });

   appManager.run(delegate() { return keepRunning; });
}
