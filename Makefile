#
# Not exactly an award-wining build system, but should work for now
#

all: simplex_noise_demo

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
# Clean
#
clean:
	rm -f $(TERRAIN_OBJECTS) $(SIMPLEX_NOISE_DEMO_OBJECTS) simplex_noise_demo
