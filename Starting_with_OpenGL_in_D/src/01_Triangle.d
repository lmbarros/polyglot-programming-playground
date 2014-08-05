module Example_01_Triangle;

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

   vertexShader.init(GL_VERTEX_SHADER, strVertexShader);
   fragmentShader.init(GL_FRAGMENT_SHADER, strFragmentShader);

   theProgram.init(vertexShader, fragmentShader);
}


void initializeVertexBuffer()
{
   positionBufferObject.init();
   positionBufferObject.bind();

   glBufferData(GL_ARRAY_BUFFER, vertexPositions.sizeof, vertexPositions.ptr, GL_STATIC_DRAW);

   positionBufferObject.unbind();
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
      float t = gl_FragCoord.y / 768.0;

      outputColor = mix(vec4(1.0f, 0.0f, 0.0f, 1.0f),
                        vec4(0.0f, 0.0f, 1.0f, 1.0f),
                        t);
   }
`;


Program theProgram;

VertexBufferObject positionBufferObject;
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
   auto appManager = SDLAppManager(SDL_INIT_VIDEO);

   // Window, please
   auto window = Window("Triangle",
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

         positionBufferObject.bind();
         glEnableVertexAttribArray(0);
         glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 0, null);

         glDrawArrays(GL_TRIANGLES, 0, 3);

         glDisableVertexAttribArray(0);
         theProgram.unuse();

         window.swapBuffers();
      });

   appManager.run(delegate() { return keepRunning; });
}
