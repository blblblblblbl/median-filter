all: cuda cpp output

cuda:
	nvcc -c src/medianFilter.cu
cpp:
	g++ -c src/main.cpp EasyBMP/EasyBMP.cpp
	g++ -o result medianFilter.o EasyBMP.o main.o -L/usr/local/cuda/lib64 -lcudart
output:
	./result