CFLAGS = -O2 -qopenmp -mcmodel=medium

#  -fdefault-integer-8 required to handle associated array sizes for large memory.
FFLAGS = -O2 -qopenmp -fdefault-integer-8
FFLAGS = -O2 -qopenmp -i8
FFLAGS = -O2 -qopenmp 


all: stream_f.exe stream_c.exe

stream_f.exe: stream.f mysecond.o
	$(CC) $(CFLAGS) $(CPPFLAGS) -c mysecond.c
	$(FC) $(FFLAGS) $(CPPFLAGS) -c stream.f
	$(FC) $(FFLAGS) stream.o mysecond.o -o stream_f.$(FC).exe

stream_c.exe: stream.c
	$(CC) $(CFLAGS) $(CPPFLAGS) stream.c -o stream_c.$(CC).exe

clean:
	rm -f  *.exe  *.o numz.*

# an example of a more complex build line for the Intel icc compiler
stream.icc: stream.c
	icc -O3 -xCORE-AVX2 -ffreestanding -qopenmp -DSTREAM_ARRAY_SIZE=80000000 -DNTIMES=20 stream.c -o stream.omp.AVX2.80M.20x.icc
