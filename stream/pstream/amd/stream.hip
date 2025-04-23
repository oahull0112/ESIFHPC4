/*
// Shows how to write stream "hip" kernels in the style of the original "cuda".
// It is based on main.hip from the repo given below.  
// After downloading the repo copy this file to the
// directory shown, build and run.
// Timothy H. Kaiser tkaiser2@nrel.gov Apr 2025.

git clone https://github.com/ROCm/rocm-examples.git
cp stream.hip rocm-examples/HIP-Basic/saxpy
cd rocm-examples/HIP-Basic/saxpy
/opt/rocm/bin/hipcc -std=c++17 -Wall -Wextra -I ../../Common  -o hip_stream stream.hip 
./hip_stream
*/
// MIT License
//
// Copyright (c) 2022-2023 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include "example_utils.hpp"


#include <hip/hip_runtime.h>

#include <algorithm>
#include <iostream>
#include <numeric>
#include <vector>

#include <cstddef>

#include <sys/time.h>
double mysecond()
{
    struct timeval tp;
    struct timezone tzp;
    gettimeofday(&tp,&tzp);
    return ( (double) tp.tv_sec + (double) tp.tv_usec * 1.0-6 );
}


__global__ void set_kernel(const float a, float* d_y,  const unsigned int size)
{
    // Compute the current thread's index in the grid.
    const unsigned int global_idx = blockIdx.x * blockDim.x + threadIdx.x;

    // The grid can be larger than the number of items in the vectors. Avoid out-of-bounds addressing.
    if(global_idx < size)
    {
        d_y[global_idx] = a  ;
    }
}

__global__ void copy_kernel(const float* d_x, float* d_y, const unsigned int size)
{
    // Compute the current thread's index in the grid.
    const unsigned int global_idx = blockIdx.x * blockDim.x + threadIdx.x;

    // The grid can be larger than the number of items in the vectors. Avoid out-of-bounds addressing.
    if(global_idx < size)
    {
        d_y[global_idx] = d_x[global_idx] ;
    }
}

__global__ void scale_kernel(const float a, const float* d_x, float* d_y, const unsigned int size)
{
    // Compute the current thread's index in the grid.
    const unsigned int global_idx = blockIdx.x * blockDim.x + threadIdx.x;

    // The grid can be larger than the number of items in the vectors. Avoid out-of-bounds addressing.
    if(global_idx < size)
    {
        d_y[global_idx] = a * d_x[global_idx] ;
    }
}

__global__ void triad_kernel(const float a, const float* d_x, float* d_y, const unsigned int size)
{
    // Compute the current thread's index in the grid.
    const unsigned int global_idx = blockIdx.x * blockDim.x + threadIdx.x;

    // The grid can be larger than the number of items in the vectors. Avoid out-of-bounds addressing.
    if(global_idx < size)
    {
        d_y[global_idx] = a * d_x[global_idx] + d_y[global_idx];
    }
}

__global__ void add_kernel(const float* d_x, float* d_y, float* d_z, const unsigned int size)
{
    // Compute the current thread's index in the grid.
    const unsigned int global_idx = blockIdx.x * blockDim.x + threadIdx.x;

    // The grid can be larger than the number of items in the vectors. Avoid out-of-bounds addressing.
    if(global_idx < size)
    {
        d_z[global_idx] = d_x[global_idx] + d_y[global_idx];
    }
}



int main(int argc, char *argv[])

{
    int count;
    int deviceIndex;
    deviceIndex=0;
    if (argc > 1 ) {
     deviceIndex=std::stoi(argv[1]);
    }
    HIP_CHECK(hipGetDeviceCount(&count));
    if (deviceIndex >= count || deviceIndex < 0)
        throw std::runtime_error("Chosen device index is invalid");
    std::cout <<"Running on GPU " << deviceIndex << std::endl;
    double ts[5],te[5];
// The number of float elements in each vector.
    constexpr unsigned int size = 1000000;

    // Bytes to allocate for each device vector.
    constexpr size_t size_bytes = size * sizeof(float);

    // Number of threads per kernel block.
    constexpr unsigned int block_size = 256;

    // Number of blocks per kernel grid. The expression below calculates ceil(size/block_size).
    constexpr unsigned int grid_size = ceiling_div(size, block_size);

    // The constant value to use in the a*x+y formula.
    constexpr float a = 2.f;

    // Allocate x vector and fill it with an increasing sequence (i.e. 1, 2, 3, 4...)
    std::vector<float> x(size);
    std::iota(x.begin(), x.end(), 1.f);

    // Allocate y vector and fill it with a constant of 1.
    std::vector<float> y(size);
    std::fill(y.begin(), y.end(), 1.f);
    
    // Allocate and copy vectors to device memory.
    float* d_x{};
    float* d_y{};
    HIP_CHECK(hipMalloc(&d_x, size_bytes));
    HIP_CHECK(hipMalloc(&d_y, size_bytes));
    HIP_CHECK(hipMemcpy(d_x, x.data(), size_bytes, hipMemcpyHostToDevice));
    HIP_CHECK(hipMemcpy(d_y, y.data(), size_bytes, hipMemcpyHostToDevice));


    std::cout << "Calculating over " << size << " elements." << std::endl;

    constexpr size_t elements_to_print = 10;
    std::cout <<"\nLaunch the triad kernel on the default stream.\n";
ts[0]=mysecond();
    triad_kernel<<<dim3(grid_size), dim3(block_size), 0, hipStreamDefault>>>(a, d_x, d_y, size);
te[0]=mysecond();

    // Check if the kernel launch was successful.
    HIP_CHECK(hipGetLastError());
    // Copy the results back to the host. This call blocks the host's execution until the copy is finished.
    HIP_CHECK(hipMemcpy(y.data(), d_y, size_bytes, hipMemcpyDeviceToHost));
    std::cout << "First " << elements_to_print << " elements of the results: "
              << format_range(y.begin(), y.begin() + elements_to_print) << std::endl;
    std::cout << "dt=" << te[0]-ts[0] << std::endl;  

    // Allocate z vector and fill it with a constant of -1.
    std::vector<float> z(size);
    std::fill(z.begin(), z.end(), -1.f);
    float* d_z{};
    HIP_CHECK(hipMalloc(&d_z, size_bytes));

    std::cout <<"\nLaunch the add kernel on the default stream.\n";
ts[1]=mysecond();
    add_kernel<<<dim3(grid_size), dim3(block_size), 0, hipStreamDefault>>>( d_x, d_y, d_z, size);
te[1]=mysecond();
    // Check if the kernel launch was successful.
    HIP_CHECK(hipGetLastError());
    // Copy the results back to the host. This call blocks the host's execution until the copy is finished.
    HIP_CHECK(hipMemcpy(z.data(), d_z, size_bytes, hipMemcpyDeviceToHost));
    // Print the first few elements of the results:
    std::cout << "First " << elements_to_print << " elements of the results: "
              << format_range(z.begin(), z.begin() + elements_to_print) << std::endl;
    std::cout << "dt=" << te[1]-ts[1] << std::endl;  

    std::cout <<"\nLaunch the set kernel on the default stream.\n";
ts[2]=mysecond();
set_kernel<<<dim3(grid_size), dim3(block_size), 0, hipStreamDefault>>>( 1.0, d_y, size);
te[2]=mysecond();
    // Check if the kernel launch was successful.
    HIP_CHECK(hipGetLastError());
    // Copy the results back to the host. This call blocks the host's execution until the copy is finished.
    HIP_CHECK(hipMemcpy(y.data(), d_y, size_bytes, hipMemcpyDeviceToHost));
    std::cout << "First " << elements_to_print << " elements of the results: "
              << format_range(y.begin(), y.begin() + elements_to_print) << std::endl;
    std::cout << "dt=" << te[2]-ts[2] << std::endl;  

    std::cout <<"\nLaunch the copy kernel on the default stream.\n";
ts[3]=mysecond();
copy_kernel<<<dim3(grid_size), dim3(block_size), 0, hipStreamDefault>>>( d_x, d_y, size);
te[3]=mysecond();
    // Check if the kernel launch was successful.
    HIP_CHECK(hipGetLastError());
    // Copy the results back to the host. This call blocks the host's execution until the copy is finished.
    HIP_CHECK(hipMemcpy(y.data(), d_y, size_bytes, hipMemcpyDeviceToHost));
    std::cout << "First " << elements_to_print << " elements of the results: "
              << format_range(y.begin(), y.begin() + elements_to_print) << std::endl;
    std::cout << "dt=" << te[3]-ts[3] << std::endl;  

    std::cout << "\nLaunch the scale kernel on the default stream.\n";
ts[4]=mysecond();
scale_kernel<<<dim3(grid_size), dim3(block_size), 0, hipStreamDefault>>>( 10.0,d_x, d_y, size);
te[4]=mysecond();
    // Check if the kernel launch was successful.
    HIP_CHECK(hipGetLastError());
    // Copy the results back to the host. This call blocks the host's execution until the copy is finished.
    HIP_CHECK(hipMemcpy(y.data(), d_y, size_bytes, hipMemcpyDeviceToHost));
    std::cout << "First " << elements_to_print << " elements of the results: "
              << format_range(y.begin(), y.begin() + elements_to_print) << std::endl;
    std::cout << "dt=" << te[4]-ts[4] << std::endl;  
    // Free device memory.
    HIP_CHECK(hipFree(d_x));
    HIP_CHECK(hipFree(d_y));
    HIP_CHECK(hipFree(d_z));

}
