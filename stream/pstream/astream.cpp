// ml openmpi
// export OMPI_CC=/opt/rocm/bin/hipcc
// mpicc -std=c++11 -O3 -lm astream.cpp -o astream
// mpirun -n 8 ./astream

#include <mpi.h>
int myid;

#include <cfloat>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <vector>


// From common.h
#define VERSION_STRING "1.0"
extern void parseArguments(int argc, char *argv[]);
extern void listDevices(void);
template < typename T > void check_solution(void* a_in, void* b_in, void* c_in);






/*=============================================================================
* https://github.com/ROCm/HIP-Examples.git
*------------------------------------------------------------------------------
* Copyright 2015: Tom Deakin, Simon McIntosh-Smith, University of Bristol HPC
* Based on John D. McCalpin’s original STREAM benchmark for CPUs
*------------------------------------------------------------------------------
*  MPI Version: Timothy Kaiser, National Renewable Energy Laboratory, 2025
*------------------------------------------------------------------------------
* License:
*  1. You are free to use this program and/or to redistribute
*     this program.
*  2. You are free to modify this program for your own use,
*     including commercial use, subject to the publication
*     restrictions in item 3.
*  3. You are free to publish results obtained from running this
*     program, or from works that you derive from this program,
*     with the following limitations:
*     3a. In order to be referred to as "GPU-STREAM benchmark results",
*         published results must be in conformance to the GPU-STREAM
*         Run Rules published at
*         http://github.com/UoB-HPC/GPU-STREAM/wiki/Run-Rules
*         and incorporated herein by reference.
*         The copyright holders retain the
*         right to determine conformity with the Run Rules.
*     3b. Results based on modified source code or on runs not in
*         accordance with the GPU-STREAM Run Rules must be clearly
*         labelled whenever they are published.  Examples of
*         proper labelling include:
*         "tuned GPU-STREAM benchmark results"
*         "based on a variant of the GPU-STREAM benchmark code"
*         Other comparable, clear and reasonable labelling is
*         acceptable.
*     3c. Submission of results to the GPU-STREAM benchmark web site
*         is encouraged, but not required.
*  4. Use of this program or creation of derived works based on this
*     program constitutes acceptance of these licensing restrictions.
*  5. Absolutely no warranty is expressed or implied.
*———————————————————————————————————-----------------------------------------*/

// #include "common.h"

// Default array size 50 * 2^20 (50*8 Mebibytes double precision)
// Use binary powers of two so divides 1024
//unsigned int ARRAY_SIZE = 52428800;
unsigned int ARRAY_SIZE = 26214400;
size_t   ARRAY_PAD_BYTES  = 0;

unsigned int NTIMES = 10;

bool useFloat = false;
unsigned int  groups   = 0;
unsigned int  groupSize   = 1024;

unsigned int deviceIndex = 0;

bool doexit = false;

int parseUInt(const char *str, unsigned int *output)
{
    char *next;
    *output = strtoul(str, &next, 10);
    return !strlen(next);
}

int parseSize(const char *str, size_t *output)
{
    char *next;
    *output = strtoull(str, &next, 0);
	int l = strlen(str);
	if (l) {
		char c = str[l-1]; // last char.
		if ((c == 'k') || (c == 'K')) {
			*output *= 1024;
		}
		if ((c == 'm') || (c == 'M')) {
			*output *= (1024*1024);
		}

	}
    return !strlen(next);
}


void parseArguments(int argc, char *argv[])
{
    for (int i = 1; i < argc; i++)
    {
        if (!strcmp(argv[i], "--list"))
        {
            listDevices();
            doexit = true;
            // exit(0);
        }
        else if (!strcmp(argv[i], "--device"))
        {
            if (++i >= argc || !parseUInt(argv[i], &deviceIndex))
            {
                std::cout << "Invalid device index" << std::endl;
                MPI_Abort(MPI_COMM_WORLD,1);
            }
        }
        else if (!strcmp(argv[i], "--arraysize") || !strcmp(argv[i], "-s"))
        {
            if (++i >= argc || !parseUInt(argv[i], &ARRAY_SIZE))
            {
                std::cout << "Invalid array size" << std::endl;
                MPI_Abort(MPI_COMM_WORLD,1);
            }
        }
        else if (!strcmp(argv[i], "--numtimes") || !strcmp(argv[i], "-n"))
        {
            if (++i >= argc || !parseUInt(argv[i], &NTIMES))
            {
                std::cout << "Invalid number of times" << std::endl;
                MPI_Abort(MPI_COMM_WORLD,1);
            }
        }
        else if (!strcmp(argv[i], "--groups"))
        {
            if (++i >= argc || !parseUInt(argv[i], &groups))
            {
                std::cout << "Invalid group number" << std::endl;
                MPI_Abort(MPI_COMM_WORLD,1);
            }
        }
        else if (!strcmp(argv[i], "--groupSize"))
        {
            if (++i >= argc || !parseUInt(argv[i], &groupSize))
            {
                std::cout << "Invalid group size" << std::endl;
                MPI_Abort(MPI_COMM_WORLD,1);
            }
        }
        else if (!strcmp(argv[i], "--pad"))
        {
            if (++i >= argc || !parseSize(argv[i], &ARRAY_PAD_BYTES))
            {
                std::cout << "Invalid size" << std::endl;
                MPI_Abort(MPI_COMM_WORLD,1);
            }

        }
        else if (!strcmp(argv[i], "--float"))
        {
            useFloat = true;
            std::cout << "Warning: If number of iterations set >= 8, expect rounding errors with single precision" << std::endl;
        }
        else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h"))
        {
            std::cout << std::endl;
            std::cout << "Usage: ./gpu-stream-cuda [OPTIONS]" << std::endl << std::endl;
            std::cout << "Options:" << std::endl;
            std::cout << "  -h  --help               Print the message" << std::endl;
            std::cout << "      --list               List available devices" << std::endl;
            std::cout << "      --device     INDEX   Select device at INDEX" << std::endl;
            std::cout << "  -s  --arraysize  SIZE    Use SIZE elements in the array" << std::endl;
            std::cout << "  -n  --numtimes   NUM     Run the test NUM times (NUM >= 2)" << std::endl;
            std::cout << "      --groups             Set number of groups to launch -  each work-item proceses multiple array items" << std::endl;
            std::cout << "      --groupSize          Set size of each group (default 1024)" << std::endl;
            std::cout << "      --pad                Add additional array padding. Can use trailing K (KB) or M (MB)" << std::endl;
            std::cout << "      --float              Use floats (rather than doubles)" << std::endl;
            std::cout << std::endl;
            doexit = true;
        }
        else
        {
            std::cout << "Unrecognized argument '" << argv[i] << "' (try '--help')"
                << std::endl;
            doexit = true;
        }
    }
}
#include "hip/hip_runtime.h"



//#include <cuda.h>
// #include "common.h"

std::string getDeviceName(int device);
int getDriver(void);

// Code to check CUDA errors
void check_cuda_error(void)
{
    hipError_t err = hipGetLastError();
    if (err != hipSuccess)
    {
        std::cerr
            << "Error: "
            << hipGetErrorString(err)
            << std::endl;
            MPI_Abort(MPI_COMM_WORLD,err);
    }
}



// looper function place more work inside each work item.
// Goal is reduce the dispatch overhead for each group, and also give more controlover the order of memory operations
template <typename T, int CLUMP_SIZE>
__global__ void
copy_looper(const T * a, T * c, int ARRAY_SIZE)
{
    int offset = (hipBlockIdx_x * hipBlockDim_x + hipThreadIdx_x)*CLUMP_SIZE;
    int stride = hipBlockDim_x * hipGridDim_x * CLUMP_SIZE;

    for (int i=offset; i<ARRAY_SIZE; i+=stride) {
        c[i] = a[i];
    }
}

template <typename T>
__global__ void
mul_looper(T * b, const T * c, int ARRAY_SIZE)
{
    int offset = hipBlockIdx_x * hipBlockDim_x + hipThreadIdx_x;
    int stride = hipBlockDim_x * hipGridDim_x;
    const T scalar = 3.0;

    for (int i=offset; i<ARRAY_SIZE; i+=stride) {
        b[i] = scalar * c[i];
    }
}

template <typename T>
__global__ void
add_looper(const T * a, const T * b, const T * d, const T * e, T * c, int ARRAY_SIZE)
{
    int offset = hipBlockIdx_x * hipBlockDim_x + hipThreadIdx_x;
    int stride = hipBlockDim_x * hipGridDim_x;

    for (int i=offset; i<ARRAY_SIZE; i+=stride) {
        c[i] = a[i] + b[i] + d[i] + e[i];
    }
}

template <typename T>
__global__ void
triad_looper(T * a, const T * b, const T * c, int ARRAY_SIZE)
{
    int offset = hipBlockIdx_x * hipBlockDim_x + hipThreadIdx_x;
    int stride = hipBlockDim_x * hipGridDim_x;
    const T scalar = 3.0;

    for (int i=offset; i<ARRAY_SIZE; i+=stride) {
        a[i] = b[i] + scalar * c[i];
    }
}




template <typename T>
__global__ void
copy(const T * a, T * c)
{
    const int i = hipBlockDim_x * hipBlockIdx_x + hipThreadIdx_x;
    c[i] = a[i];
}


template <typename T>
__global__ void
mul(T * b, const T * c)
{
    const T scalar = 3.0;
    const int i = hipBlockDim_x * hipBlockIdx_x + hipThreadIdx_x;
    b[i] = scalar * c[i];
}

template <typename T>
__global__ void
add(const T * a, const T * b, const T *d, const T *e, T * c)
{
    const int i = hipBlockDim_x * hipBlockIdx_x + hipThreadIdx_x;
    c[i] = a[i] + b[i] + d[i] + e[i];
}

template <typename T>
__global__ void
triad(T * a, const T * b, const T * c)
{
    const T scalar = 3.0;
    const int i = hipBlockDim_x * hipBlockIdx_x + hipThreadIdx_x;
    a[i] = b[i] + scalar * c[i];
}


int main(int argc, char *argv[])
{
    std::ofstream FOUT;
    char fname[128];
    int ntasks,mpi_err;
    mpi_err=MPI_Init(&argc,&argv);
    mpi_err=MPI_Comm_size(MPI_COMM_WORLD,&ntasks);
    mpi_err=MPI_Comm_rank(MPI_COMM_WORLD,&myid);
    if (myid == 0 ) parseArguments(argc, argv);
MPI_Bcast(&deviceIndex,     1, MPI_UNSIGNED,       0, MPI_COMM_WORLD);
MPI_Bcast(&ARRAY_SIZE,      1, MPI_UNSIGNED,       0, MPI_COMM_WORLD);
MPI_Bcast(&ARRAY_PAD_BYTES, 1, MPI_UNSIGNED_LONG,  0, MPI_COMM_WORLD);
MPI_Bcast(&NTIMES,          1, MPI_UNSIGNED,       0, MPI_COMM_WORLD);
MPI_Bcast(&useFloat,        1, MPI_CXX_BOOL,       0, MPI_COMM_WORLD);
MPI_Bcast(&doexit,          1, MPI_CXX_BOOL,       0, MPI_COMM_WORLD);
MPI_Bcast(&groups,          1, MPI_UNSIGNED,       0, MPI_COMM_WORLD);
MPI_Bcast(&groupSize,       1, MPI_UNSIGNED,       0, MPI_COMM_WORLD);

if (doexit){
 MPI_Finalize();
 exit(0);
 }

    sprintf(fname,"strm.%4.4d",myid);
    FOUT.open(fname);
    //if (myid == 0 )printf("size_t %d unsigned long %d\n",sizeof(size_t),sizeof(unsigned long));

    // Print out run information
    FOUT
        << "GPU-STREAM" << std::endl
        << "Version: " << VERSION_STRING << std::endl
        << "Implementation: HIP" << std::endl;

    if (NTIMES < 2)
        NTIMES=2;

    // Config grid size and group size for kernel launching
    int gridSize;
    if (groups) {
        gridSize = groups * groupSize;
    } else  {
        gridSize = ARRAY_SIZE;
    }

    float operationsPerWorkitem = (float)ARRAY_SIZE / (float)gridSize;
    FOUT << "GridSize: " << gridSize << " work-items" << std::endl;
    FOUT << "GroupSize: " << groupSize << " work-items" << std::endl;
    FOUT << "Operations/Work-item: " << operationsPerWorkitem << std::endl;
    if (groups) FOUT << "Using looper kernels:" << std::endl;

    FOUT << "Precision: ";
    if (useFloat) FOUT << "float";
    else FOUT << "double";
    FOUT << std::endl << std::endl;

    FOUT << "Running kernels " << NTIMES << " times" << std::endl;

    if (ARRAY_SIZE % 1024 != 0)
    {
        unsigned int OLD_ARRAY_SIZE = ARRAY_SIZE;
        ARRAY_SIZE -= ARRAY_SIZE % 1024;
        FOUT
            << "Warning: array size must divide 1024" << std::endl
            << "Resizing array from " << OLD_ARRAY_SIZE
            << " to " << ARRAY_SIZE << std::endl;
        if (ARRAY_SIZE == 0)
            throw std::runtime_error("Array size must be >= 1024");
    }

    // Get precision (used to reset later)
    std::streamsize ss = std::cout.precision();

    size_t DATATYPE_SIZE;

    if (useFloat)
    {
        DATATYPE_SIZE = sizeof(float);
    }
    else
    {
        DATATYPE_SIZE = sizeof(double);
    }

    // Display number of bytes in array
    FOUT << std::setprecision(1) << std::fixed
        << "Array size: " << ARRAY_SIZE*DATATYPE_SIZE/1024.0/1024.0 << " MB"
        << " (=" << ARRAY_SIZE*DATATYPE_SIZE/1024.0/1024.0/1024.0 << " GB)"
		<< " " << ARRAY_PAD_BYTES << " bytes padding"
        << std::endl;
    FOUT << "Total size: " << 5.0*(ARRAY_SIZE*DATATYPE_SIZE + ARRAY_PAD_BYTES) /1024.0/1024.0 << " MB"
        << " (=" << 5.0*(ARRAY_SIZE*DATATYPE_SIZE + ARRAY_PAD_BYTES) /1024.0/1024.0/1024.0 << " GB)"
        << std::endl;

    // Reset precision
    FOUT.precision(ss);

    // Check device index is in range
    int count;
    hipGetDeviceCount(&count);
    check_cuda_error();
    deviceIndex=myid % count;
    if (deviceIndex >= count)
        throw std::runtime_error("Chosen device index is invalid");
    hipSetDevice(deviceIndex);
    check_cuda_error();


    hipDeviceProp_t props;
    hipGetDeviceProperties(&props, deviceIndex);

    // Print out device name
    FOUT << "Using HIP device " << getDeviceName(deviceIndex) <<  " (compute_units=" << props.multiProcessorCount << ")" << std::endl;

    // Print out device HIP driver version
    FOUT << "Driver: " << getDriver() << std::endl;




    // Check buffers fit on the device
    if (props.totalGlobalMem < 3*DATATYPE_SIZE*ARRAY_SIZE)
        throw std::runtime_error("Device does not have enough memory for all 3 buffers");

    //int cus = props.multiProcessorCount;

    // Create host vectors
    void * h_a = malloc(ARRAY_SIZE*DATATYPE_SIZE );
    void * h_b = malloc(ARRAY_SIZE*DATATYPE_SIZE );
    void * h_c = malloc(ARRAY_SIZE*DATATYPE_SIZE );
    void * h_d = malloc(ARRAY_SIZE*DATATYPE_SIZE );
    void * h_e = malloc(ARRAY_SIZE*DATATYPE_SIZE );

    // Initialise arrays
    for (unsigned int i = 0; i < ARRAY_SIZE; i++)
    {
        if (useFloat)
        { ((float*)h_a)[i] = 1.0f; ((float*)h_b)[i] = 2.0f;
            ((float*)h_c)[i] = 0.0f;
            ((float*)h_d)[i] = 1.0f;
            ((float*)h_e)[i] = 1.0f;
        }
        else
        {
            ((double*)h_a)[i] = 1.0;
            ((double*)h_b)[i] = 2.0;
            ((double*)h_c)[i] = 0.0;
            ((double*)h_d)[i] = 1.0;
            ((double*)h_e)[i] = 1.0;
        }
    }

    // Create device buffers
    char * d_a, * d_b, *d_c, *d_d, *d_e;
    hipMalloc(&d_a, ARRAY_SIZE*DATATYPE_SIZE + ARRAY_PAD_BYTES);
    check_cuda_error();
    hipMalloc(&d_b, ARRAY_SIZE*DATATYPE_SIZE + ARRAY_PAD_BYTES);
    d_b += ARRAY_PAD_BYTES;
    check_cuda_error();
    hipMalloc(&d_c, ARRAY_SIZE*DATATYPE_SIZE + ARRAY_PAD_BYTES);
    d_c += ARRAY_PAD_BYTES;
    check_cuda_error();
    hipMalloc(&d_d, ARRAY_SIZE*DATATYPE_SIZE + ARRAY_PAD_BYTES);
    d_d += ARRAY_PAD_BYTES;
    check_cuda_error();
    hipMalloc(&d_e, ARRAY_SIZE*DATATYPE_SIZE + ARRAY_PAD_BYTES);
    d_e += ARRAY_PAD_BYTES;
    check_cuda_error();

    // Copy host memory to device
    hipMemcpy(d_a, h_a, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyHostToDevice);
    check_cuda_error();
    hipMemcpy(d_b, h_b, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyHostToDevice);
    check_cuda_error();
    hipMemcpy(d_c, h_c, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyHostToDevice);
    check_cuda_error();
    hipMemcpy(d_d, h_d, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyHostToDevice);
    check_cuda_error();
    hipMemcpy(d_e, h_e, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyHostToDevice);
    check_cuda_error();


    FOUT << "d_a=" << (void*)d_a << std::endl;
	FOUT << "d_b=" << (void*)d_b << std::endl;
	FOUT << "d_c=" << (void*)d_c << std::endl;
    FOUT << "d_d=" << (void*)d_d << std::endl;
	FOUT << "d_e=" << (void*)d_e << std::endl;

    // Make sure the copies are finished
    hipDeviceSynchronize();
    check_cuda_error();


    // List of times
    std::vector< std::vector<double> > timings;

    // Declare timers
    std::chrono::high_resolution_clock::time_point t1, t2;

    // Main loop
    for (unsigned int k = 0; k < NTIMES; k++)
    {
        std::vector<double> times;
        t1 = std::chrono::high_resolution_clock::now();
        if (groups) {
            if (useFloat)
                hipLaunchKernelGGL((copy_looper<float,1>), dim3(gridSize), dim3(groupSize), 0, 0, (float*)d_a, (float*)d_c, ARRAY_SIZE);
            else
                hipLaunchKernelGGL((copy_looper<double,1>), dim3(gridSize), dim3(groupSize), 0, 0, (double*)d_a, (double*)d_c, ARRAY_SIZE);
        } else {
            if (useFloat)
                hipLaunchKernelGGL(copy<float>, dim3(ARRAY_SIZE/groupSize), dim3(groupSize), 0, 0, (float*)d_a, (float*)d_c);
            else
                hipLaunchKernelGGL(copy<double>, dim3(ARRAY_SIZE/groupSize), dim3(groupSize), 0, 0, (double*)d_a, (double*)d_c);
        }
        check_cuda_error();
        hipDeviceSynchronize();
        check_cuda_error();
        t2 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration_cast<std::chrono::duration<double> >(t2 - t1).count());


        t1 = std::chrono::high_resolution_clock::now();
        if (groups) {
            if (useFloat)
                hipLaunchKernelGGL(mul_looper<float>, dim3(gridSize), dim3(groupSize), 0, 0, (float*)d_b, (float*)d_c, ARRAY_SIZE);
            else
                hipLaunchKernelGGL(mul_looper<double>, dim3(gridSize), dim3(groupSize), 0, 0, (double*)d_b, (double*)d_c, ARRAY_SIZE);
        } else {
            if (useFloat)
                hipLaunchKernelGGL(mul<float>, dim3(ARRAY_SIZE/groupSize), dim3(groupSize), 0, 0, (float*)d_b, (float*)d_c);
            else
                hipLaunchKernelGGL(mul<double>, dim3(ARRAY_SIZE/groupSize), dim3(groupSize), 0, 0, (double*)d_b, (double*)d_c);
        }
        check_cuda_error();
        hipDeviceSynchronize();
        check_cuda_error();
        t2 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration_cast<std::chrono::duration<double> >(t2 - t1).count());


        t1 = std::chrono::high_resolution_clock::now();
        if (groups) {
            if (useFloat)
                hipLaunchKernelGGL(add_looper<float>, dim3(gridSize), dim3(groupSize), 0, 0, (float*)d_a, (float*)d_b,(float*)d_d, (float*)d_e,  (float*)d_c, ARRAY_SIZE);
            else
                hipLaunchKernelGGL(add_looper<double>, dim3(gridSize), dim3(groupSize), 0, 0, (double*)d_a, (double*)d_b, (double*)d_d, (double*)d_e,(double*)d_c, ARRAY_SIZE);
        } else {
            if (useFloat)
                hipLaunchKernelGGL(add<float>, dim3(ARRAY_SIZE/groupSize), dim3(groupSize), 0, 0, (float*)d_a, (float*)d_b, (float*)d_d,(float*)d_e,(float*)d_c);
            else
                hipLaunchKernelGGL(add<double>, dim3(ARRAY_SIZE/groupSize), dim3(groupSize), 0, 0, (double*)d_a, (double*)d_b, (double*)d_d,(double*)d_e,(double*)d_c);
        }
        check_cuda_error();
        hipDeviceSynchronize();
        check_cuda_error();
        t2 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration_cast<std::chrono::duration<double> >(t2 - t1).count());


        t1 = std::chrono::high_resolution_clock::now();
        if (groups) {
            if (useFloat)
                hipLaunchKernelGGL(triad_looper<float>, dim3(gridSize), dim3(groupSize), 0, 0, (float*)d_a, (float*)d_b, (float*)d_c, ARRAY_SIZE);
            else
                hipLaunchKernelGGL(triad_looper<double>, dim3(gridSize), dim3(groupSize), 0, 0, (double*)d_a, (double*)d_b, (double*)d_c, ARRAY_SIZE);
        } else {
            if (useFloat)
                hipLaunchKernelGGL(triad<float>, dim3(ARRAY_SIZE/groupSize), dim3(groupSize), 0, 0, (float*)d_a, (float*)d_b, (float*)d_c);
            else
                hipLaunchKernelGGL(triad<double>, dim3(ARRAY_SIZE/groupSize), dim3(groupSize), 0, 0, (double*)d_a, (double*)d_b, (double*)d_c);
        }

        check_cuda_error();
        hipDeviceSynchronize();
        check_cuda_error();
        t2 = std::chrono::high_resolution_clock::now();
        times.push_back(std::chrono::duration_cast<std::chrono::duration<double> >(t2 - t1).count());

        timings.push_back(times);

    }

    // Check solutions
    hipMemcpy(h_a, d_a, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyDeviceToHost);
    check_cuda_error();
    hipMemcpy(h_b, d_b, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyDeviceToHost);
    check_cuda_error();
    hipMemcpy(h_c, d_c, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyDeviceToHost);
    check_cuda_error();
    //hipMemcpy(h_d, d_d, ARRAY_SIZE*DATATYPE_SIZE, hipMemcpyDeviceToHost);
    //check_cuda_error();

    if (useFloat)
    {
        check_solution<float>(h_a, h_b, h_c);
    }
    else
    {
        check_solution<double>(h_a, h_b, h_c);
    }

    // Crunch results
    size_t sizes[4] = {
        2 * DATATYPE_SIZE * ARRAY_SIZE,
        2 * DATATYPE_SIZE * ARRAY_SIZE,
        5 * DATATYPE_SIZE * ARRAY_SIZE,
        3 * DATATYPE_SIZE * ARRAY_SIZE
    };
    double min[4] = {DBL_MAX, DBL_MAX, DBL_MAX, DBL_MAX};
    double max[4] = {0.0, 0.0, 0.0, 0.0};
    double avg[4] = {0.0, 0.0, 0.0, 0.0};

    // Ignore first result
    for (unsigned int i = 1; i < NTIMES; i++)
    {
        for (int j = 0; j < 4; j++)
        {
            avg[j] += timings[i][j];
            min[j] = std::min(min[j], timings[i][j]);
            max[j] = std::max(max[j], timings[i][j]);
        }
    }

    for (int j = 0; j < 4; j++) {
        avg[j] /= (double)(NTIMES-1);
    }

    double geomean = 1.0;
    for (int j = 0; j < 4; j++) {
        geomean *= (sizes[j]/min[j]);
    }
    geomean = pow(geomean, 0.25);

    // Display results
    std::string labels[] = {"Copy", "Mul", "Add4", "Triad"};
    FOUT
        << std::left << std::setw(12) << "Function"
        << std::left << std::setw(12) << "GBytes/sec"
        << std::left << std::setw(12) << "Min (sec)"
        << std::left << std::setw(12) << "Max"
        << std::left << std::setw(12) << "Average"
        << std::endl;

    for (int j = 0; j < 4; j++)
    {
        FOUT
            << std::left << std::setw(12) << labels[j]
            << std::left << std::setw(12) << std::setprecision(3) << 1.0E-09 * sizes[j]/min[j]
            << std::left << std::setw(12) << std::setprecision(5) << min[j]
            << std::left << std::setw(12) << std::setprecision(5) << max[j]
            << std::left << std::setw(12) << std::setprecision(5) << avg[j]
            << std::endl;
    }
    FOUT
        << std::left << std::setw(12) << "GEOMEAN"
        << std::left << std::setw(12) << std::setprecision(3) << 1.0E-09 * geomean
        << std::endl;

    // Free host vectors
    free(h_a);
    free(h_b);
    free(h_c);
    free(h_d);
    free(h_e);

    // Free cuda buffers
    hipFree(d_a);
    check_cuda_error();
    hipFree(d_b);
    check_cuda_error();
    hipFree(d_c);
    check_cuda_error();
    hipFree(d_d);
    check_cuda_error();
    hipFree(d_e);
    check_cuda_error();
        mpi_err = MPI_Finalize();
    return (mpi_err);


}

std::string getDeviceName(int device)
{
    struct hipDeviceProp_t prop;
    hipGetDeviceProperties(&prop, device);
    check_cuda_error();
    return std::string(prop.name);
}

int getDriver(void)
{
    int driver;
    hipDriverGetVersion(&driver);
    check_cuda_error();
    return driver;
}

void listDevices(void)
{
    // Get number of devices
    int count;
    hipGetDeviceCount(&count);
    check_cuda_error();

    // Print device names
    if (count == 0)
    {
        std::cout << "No devices found." << std::endl;
    }
    else
    {
        std::cout << std::endl;
        std::cout << "Devices:" << std::endl;
        for (int i = 0; i < count; i++)
        {
            std::cout << i << ": " << getDeviceName(i) << std::endl;
            check_cuda_error();
        }
        std::cout << std::endl;
    }
}


// From common.h
template < typename T >
void check_solution(void* a_in, void* b_in, void* c_in)
{
    // Generate correct solution
    T golda = 1.0;
    T goldb = 2.0;
    T goldc = 0.0;
    T goldd = 1.0;
    T golde = 1.0;
    T * a = static_cast<T*>(a_in);
    T * b = static_cast<T*>(b_in);
    T * c = static_cast<T*>(c_in);

    const T scalar = 3.0;

    for (unsigned int i = 0; i < NTIMES; i++)
    {
        // Double
        goldc = golda;
        goldb = scalar * goldc;
        goldc = golda + goldb + goldd + golde;
        golda = goldb + scalar * goldc;
    }
    // if(myid == 0)std::cout << golda << " "<< goldb <<" "<<goldc <<" "<< std::endl;

    // Calculate average error
    double erra = 0.0;
    double errb = 0.0;
    double errc = 0.0;

    for (unsigned int i = 0; i < ARRAY_SIZE; i++)
    {
        erra += fabs(a[i] - golda);
        errb += fabs(b[i] - goldb);
        errc += fabs(c[i] - goldc);
    }
    // if(myid == 0) std::cout << a[ARRAY_SIZE-1] << " "<< b[ARRAY_SIZE-1] <<" "<<c[ARRAY_SIZE-1] <<" "<< std::endl;
    // if(myid == 0) std::cout << erra/a[ARRAY_SIZE-1] << " "<< errb/b[ARRAY_SIZE-1] <<" "<<errc/c[ARRAY_SIZE-1] <<" "<< std::endl;


    erra /= ARRAY_SIZE;
    errb /= ARRAY_SIZE;
    errc /= ARRAY_SIZE;

// Make error relative    
    erra /= golda;
    errb /= goldb;
    errc /= goldc;

    double epsi = std::numeric_limits<T>::epsilon() * 100;
    // if(myid == 0)std::cout << erra << " "<< errb <<" "<<errc <<" "<< " " << epsi << std::endl;

    if (erra > epsi)
        std::cout
            << "Validation failed on a[]. Average error " << erra
            << std::endl;
    if (errb > epsi)
        std::cout
            << "Validation failed on b[]. Average error " << errb
            << std::endl;
    if (errc > epsi)
        std::cout
            << "Validation failed on c[]. Average error " << errc
            << std::endl;
}

