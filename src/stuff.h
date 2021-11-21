//
// Created by yudjin on 11/13/20.
//

#ifndef CUDAMEDIANFILTER_STUFF_H
#define CUDAMEDIANFILTER_STUFF_H

#include <stdio.h>
#include <stdlib.h>
#include <string>

#include "../EasyBMP/EasyBMP.h"


#define FILE_NAME "2.bmp"
#define RESULT_NAME_CPU "result_cpu.bmp"
#define RESULT_NAME_GPU "result_gpu.bmp"

const int iterations = 20;
const int offset = 3;
const int offset_ = (2 * offset + 1) * (2 * offset + 1);


struct pairs {
    int fi;
    int se;
};

using namespace std;

//    //CPU Median Filtering
void MedianFilterCPU(float *res, float *pixel_colors, int height, int width);
//
//    //GPU Median Filtering
void MedianFilterGPU(float *res, float *pixel_colors, int height, int width);
//



#endif //CUDAMEDIANFILTER_STUFF_H
