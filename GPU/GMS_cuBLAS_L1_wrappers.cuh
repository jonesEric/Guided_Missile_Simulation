

#ifndef __GMS_CUBLAS_L1_WRAPPERS_CUH__
#define __GMS_CUBLAS_L1_WRAPPERS_CUH__


/*
     cuBLAS Level-1 wrappers 
*/

#include <stdint>

#include "GMS_config.h"

extern "C"
void
cuBLAS_Isamax_iface(const float * __restrict,
                    const int32_t,
                    const int32_t,
                    int32_t *     __restrict,
                    cudaError_t * __restrict,
                    int32_t * __restrict,
                    uint64_t * __restrict) 
                                       __ATTR_HOT__
                                       __ATTR_ALIGN__(32);
extern "C"
void
cuBLAS_Icamax_iface(const cuComplex * __restrict,
                    const int32_t,
                    const int32_t,
                    int32_t *  __restrict,
                    cudaError_t * __restrict,
                    int32_t * __restrict,
                    uint64_t * __restrict)  
                                       __ATTR_HOT__
                                       __ATTR_ALIGN__(32);


extern "C"
void
cuBLAS_Isamin_iface(const float * __restrict,
                    const int32_t,
                    const int32_t,
                    int32_t *     __restrict,
                    cudaError_t * __restrict,
                    int32_t * __restrict,
                    uint64_t * __restrict) 
                                       __ATTR_HOT__
                                       __ATTR_ALIGN__(32);

extern "C"
void
cuBLAS_Icamin_iface(const cuComplex * __restrict,
                    const int32_t,
                    const int32_t,
                    int32_t *  __restrict,
                    cudaError_t * __restrict,
                    int32_t * __restrict,
                    uint64_t * __restrict)  
                                       __ATTR_HOT__
                                       __ATTR_ALIGN__(32);

extern "C"
void
cuBLAS_Sasum_iface(const float * __restrict,
                   const int32_t,
                   const int32_t,
                   float * __restrict,
                   cudaError_t * __restrict,
                   int32_t * __restrict,
                   uint64_t * __restrict) 
                                        __ATTR_HOT__
                                       __ATTR_ALIGN__(32);


extern "C"
void
cuBLAS_Scasum_iface(const cuComplex * __restrict,
                   const int32_t,
                   const int32_t,
                   cuComplex * __restrict,
                   cudaError_t * __restrict,
                   int32_t * __restrict,
                   uint64_t * __restrict) 
                                        __ATTR_HOT__
                                       __ATTR_ALIGN__(32);

extern "C"
void
cuBLAS_Sgemm_iface(cublasOperation_t,
                   cublasOperation_t,
                   const int32_t,
                   const int32_t,
                   const int32_t,
                   const float,
                   const float * __restrict,
                   const int32_t,
                   const float * __restrict,
                   const int32_t,
                   float,
                   float * __restrict,
                   const int32_t,
                   cudaError_t * __restrict,
                   int32_t * __restrict,
                   uint64_t * __restrict) 
                                       __ATTR_HOT__
                                       __ATTR_ALIGN__(32);

extern "C"
void
cuBLAS_Cgemm_iface(cublasOperation_t,
                   cublasOperation_t,
                   const int32_t,
                   const int32_t,
                   const int32_t,
                   const cuComplex,
                   const cuComplex * __restrict,
                   const int32_t,
                   const cuComplex * __restrict,
                   const int32_t,
                   cuComplex,
                   cuComplex * __restrict,
                   const int32_t,
                   cudaError_t * __restrict,
                   int32_t * __restrict,
                   uint64_t * __restrict) 
                                       __ATTR_HOT__
                                       __ATTR_ALIGN__(32);


extern "C"
void
cuBLAS_Cgemm3m_iface(cublasOperation_t,
                   cublasOperation_t,
                   const int32_t,
                   const int32_t,
                   const int32_t,
                   const cuComplex,
                   const cuComplex * __restrict,
                   const int32_t,
                   const cuComplex * __restrict,
                   const int32_t,
                   cuComplex,
                   cuComplex * __restrict,
                   const int32_t,
                   cudaError_t * __restrict,
                   int32_t * __restrict,
                   uint64_t * __restrict) 
                                       __ATTR_HOT__
                                       __ATTR_ALIGN__(32);






#endif /*__GMS_CUBLAS_L1_WRAPPERS_CUH__*/
