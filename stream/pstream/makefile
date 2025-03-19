pstream:pstream.c
	mpicc -O3 -fopenmp pstream.c -o pstream

clean:
	rm -rf pstream pstream.out pstream.triad mstream stream strm.0* pstream.map

mstream: mstream.cu
	ml 2>&1 | grep  PrgEnv-nvhpc > /dev/null && CC -gpu=cc90  -DNTIMES=1000   mstream.cu -o mstream || echo PrgEnv-nvhpc not loaded

stream: stream.cu
	nvcc stream.cu -o stream || echo nvcc not loaded

