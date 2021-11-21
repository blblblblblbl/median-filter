#include "stuff.h"

void writeResultImage(BMP *result_image, int isCpu, float* data, int height, int width) {
    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            RGBApixel pixel;
            pixel.Red = data[i * width + j];
            pixel.Blue = data[i * width + j];
            pixel.Green = data[i * width + j];
            result_image->SetPixel(j, i, pixel);
        }
    }
    result_image->SetBitDepth(32);

    if(isCpu) {
        result_image->WriteToFile(RESULT_NAME_CPU);
    } else {
        result_image->WriteToFile(RESULT_NAME_GPU);
    }
}

int main() {

    BMP original_image, result_image_gpu, result_image_cpu;

    original_image.ReadFromFile(FILE_NAME);
    result_image_gpu.ReadFromFile(FILE_NAME);
    result_image_cpu.ReadFromFile(FILE_NAME);

    int height = original_image.TellHeight();
    int width = original_image.TellWidth();

    auto *colours = (float *) malloc(sizeof(float) * width * height);
    auto *res_cpu = (float *) malloc(sizeof(float) * width * height);
    auto *res_gpu = (float *) malloc(sizeof(float) * width * height);
    for (int i = 0; i < height; i++)
        for (int j = 0; j < width; j++) {
            RGBApixel pixel = original_image.GetPixel(j, i);
            colours[i * width + j] =
                    (float) pixel.Red * 0.11f + (float) pixel.Green * 0.59f + (float) pixel.Blue * 0.3f;
        }

    for (int i = 0; i < iterations; i++) {
    //    MedianFilterCPU(res_cpu, colours, height, width);
    }
    for (int i = 0; i < iterations; i++) {
        MedianFilterGPU(res_gpu, colours, height, width);
    }

    writeResultImage(&result_image_cpu, 1, res_cpu, height, width);
    writeResultImage(&result_image_gpu, 0, res_gpu, height, width);
}


void MedianFilterCPU(float *res, float *colours, int height, int width) {

    float filter[offset_];
    pairs offset_range[offset_];

    for (int i = -offset; i <= offset; i++)
        for (int j = -offset; j <= offset; j++)
            offset_range[(i + offset) * (2*offset + 1) + j + offset] = {i, j};

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            int count = 0;
            float pixel;
            for (int k = 0; k < offset_; k++) {
                pairs p = offset_range[k];
                if (i + p.fi < height && i + p.fi >= 0 &&
                    j + p.se >= 0 && j + p.se < width) {
                    pixel = colours[(i + p.fi) * width + (j + p.se)];
                } else {
                    pixel = colours[i * width + j];
                }
                filter[count++] = pixel;
            }

            for (int k = 0; k < offset_; k++) {
                for (int k2 = k + 1; k2 < offset_; k2++) {
                    if (filter[k] > filter[k2]) {
                        auto tmp = filter[k];
                        filter[k] = filter[k2];
                        filter[k2] = tmp;
                    }
                }
            }
            res[i * width + j] = filter[offset_ / 2];
        }
    }
}