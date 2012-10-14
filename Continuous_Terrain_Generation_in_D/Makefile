#
# Not exactly an award-wining build system, but should work for now
#

all: simplex_noise_demo fractional_brownian_motion_demo terrain_demo

#DMDFLAGS=-unittest
DMDFLAGS=-O -inline
#DMDFLAGS=-debug

#
# Implicit rules
#
%.o: %.d
	dmd -c $(DMDFLAGS) -I/Programs/Derelict/3-git/import -Isrc $< -of$@

#
# Terrain
#
TERRAIN_OBJECTS=\
	src/syagrus/noise/fractional_brownian_motion.o \
	src/syagrus/noise/simplex_noise.o

#
# The Simplex Noise Demo
#
SIMPLEX_NOISE_DEMO_OBJECTS=\
	src/simplex_noise_demo.o

simplex_noise_demo: $(TERRAIN_OBJECTS) $(SIMPLEX_NOISE_DEMO_OBJECTS)
	gcc -o simplex_noise_demo $^ -lcsfml-window -lcsfml-graphics \
		-lDerelictSFML2 -lDerelictUtil -lphobos2


#
# The fBm Demo
#
FBM_DEMO_OBJECTS=\
	src/fractional_brownian_motion_demo.o

fractional_brownian_motion_demo: $(TERRAIN_OBJECTS) $(FBM_DEMO_OBJECTS)
	gcc -o fractional_brownian_motion_demo $^ -lcsfml-window -lcsfml-graphics \
		-lDerelictSFML2 -lDerelictUtil -lphobos2

#
# The Terrain Demo
#
TERRAIN_DEMO_OBJECTS=\
	src/terrain_demo.o

terrain_demo: $(TERRAIN_OBJECTS) $(TERRAIN_DEMO_OBJECTS)
	gcc -o terrain_demo $^ -lcsfml-window -lcsfml-graphics \
		-lDerelictSFML2 -lDerelictUtil -lphobos2

#
# Clean
#
clean:
	rm -f $(TERRAIN_OBJECTS) $(SIMPLEX_NOISE_DEMO_OBJECTS) $(FBM_DEMO_OBJECTS) \
	   $(TERRAIN_DEMO_OBJECTS) simplex_noise_demo \
	   fractional_brownian_motion_demo terrain_demo
