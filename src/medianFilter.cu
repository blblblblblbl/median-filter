#include "stuff.h"

#define TILE_SIZE 16

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }

inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort = true) {
    if (code != cudaSuccess) {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

//Texture memory utilization
texture<float, 2, cudaReadModeElementType> imageTextureRef;

__global__ void medianFilterTrueGPU(float *res, int height, int width) {
    float filter[offset_];
    pairs offset_range[offset_];

    for (int i = -offset; i <= offset; i++) {
        for (int j = -offset; j <= offset; j++) {
            offset_range[(i + offset) * (2 * offset + 1) + j + offset] = {i, j};
        }
    }

    //Parallelized processing for each pixel
    unsigned int row = blockIdx.y * blockDim.y + threadIdx.y;
    unsigned int col = blockIdx.x * blockDim.x + threadIdx.x;

    float u = 0, v= 0, pixel;
    int count = 0;

    //Choose whether if on the edge of the image
    for (int k = 0; k < offset_; k++) {
        pairs p = offset_range[k];
        if (row + p.fi < height && row + p.fi >= 0&&
            col + p.se >= 0 && col + p.se < width) {
            u = (row + p.fi);
            v = (col + p.se);
        } else {
            u = row;
            v = col;
        }
        pixel = tex2D(imageTextureRef, v / (float) width, u / (float) height) ;
        //    printf("%i\n", pixel);
        filter[count++] = pixel;
    }

    //Choose median() for 3x3 matrix around each pixel
    for (int k = 0; k < offset_; k++) {
        for (int k2 = k + 1; k2 < offset_; k2++) {
            if (filter[k] > filter[k2]) {
                auto tmp = filter[k];
                filter[k] = filter[k2];
                filter[k2] = tmp;
            }
        }
    }

    res[row * width + col] = filter[offset_ / 2];

    __syncthreads();
}

static int iterCount = 1;

void MedianFilterGPU(float *res, float *pixel_colors, int height, int width) {
    printf("Iteration :: %i\n", iterCount++);
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Allocate CUDA array in device memory
    cudaChannelFormatDesc channelDesc =
            cudaCreateChannelDesc(32, 0, 0, 0,
                                  cudaChannelFormatKindFloat);
    cudaArray *cuArray;
    gpuErrchk(cudaMallocArray(&cuArray, &channelDesc, width, height));

    // Copy to device memory some data located at address h_data
    // in host memory
    int sizeBMP = width * height * sizeof(float);
    gpuErrchk(cudaMemcpy2DToArray(cuArray, 0, 0, pixel_colors, width * sizeof(float),
                                  width * sizeof(float), height, cudaMemcpyHostToDevice));

    // Set texture parameters
//    imageTextureRef.normalized = 0;
    imageTextureRef.addressMode[0] = cudaAddressModeWrap;
    imageTextureRef.addressMode[1] = cudaAddressModeWrap;
    imageTextureRef.filterMode = cudaFilterModeLinear;
    imageTextureRef.normalized = true;

    // Bind the array to the texture reference
    gpuErrchk(cudaBindTextureToArray(imageTextureRef, cuArray, channelDesc));

    float *result_device;
    gpuErrchk(cudaMalloc(&result_device, sizeBMP));

    dim3 dimBlock(TILE_SIZE, TILE_SIZE);
    dim3 dimGrid((int) ceil(width / (float) TILE_SIZE),
                 (int) ceil((height / (float) TILE_SIZE)));

    gpuErrchk(cudaEventRecord(start, 0));
    medianFilterTrueGPU<<<dimGrid, dimBlock>>>(result_device, height, width);

    gpuErrchk(cudaMemcpy(res, result_device, sizeBMP, cudaMemcpyDeviceToHost));

    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);

    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    printf("Time consumed for current kernel call :: %3.1f ms \n", milliseconds);

    // Free device memory
    cudaFreeArray(cuArray);
    cudaFree(result_device);
    cudaDeviceSynchronize();
}