#
# Not exactly an award-wining build system, but should work for now
#

all: demo benchmark

#DMDFLAGS=-unittest
DMDFLAGS=-O -inline


#
# Implicit rules
#
%.o: %.d
	dmd -c $(DMDFLAGS) -I/Programs/Derelict/3-git/import -Isrc $< -of$@

#
# Terrain
#
TERRAIN_OBJECTS=\
	src/noise/simplex_noise.o

#
# The demo
#
DEMO_OBJECTS=\
	src/demo.o

demo: $(TERRAIN_OBJECTS) $(DEMO_OBJECTS)
	gcc -o demo $^ -lcsfml-window -lcsfml-graphics \
		-lDerelictSFML2 -lDerelictUtil -lphobos2

#
# The benchmark
#
BENCHMARK_OBJECTS=\
	src/benchmark.o

benchmark: $(TERRAIN_OBJECTS) $(BENCHMARK_OBJECTS)
	gcc -o benchmark $^  -lcsfml-window -lcsfml-graphics \
		-lDerelictSFML2 -lDerelictUtil -lphobos2

#
# Clean
#
clean:
	rm -f $(TERRAIN_OBJECTS) $(DEMO_OBJECTS) $(BENCHMARK_OBJECTS) demo benchmark
