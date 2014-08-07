#version 330

smooth in vec4 theColor;

out vec4 outputColor;

uniform float fragLoopDuration;
uniform float time;

const vec4 firstColor = vec4(1.0f, 0.15f, 0.15f, 1.0f);
const vec4 secondColor = vec4(0.15f, 0.15f, 1.0f, 1.0f);

void main()
{
   float currTime = mod(time, fragLoopDuration);
   float currLerp = (currTime / fragLoopDuration) * 6.2831853071796;

   outputColor = mix(firstColor, secondColor, (sin(currLerp) + 1.0) * 0.5);
}
