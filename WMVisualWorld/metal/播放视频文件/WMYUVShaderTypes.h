//
//  CCShaderTypes.h
//  002--MetalRenderMOV
//
//  Created by   on 2021年5/7.
//  Copyright © 2021年  . All rights reserved.
//

#ifndef CCShaderTypes_h
#define CCShaderTypes_h
#include <simd/simd.h>

//顶点数据结构
typedef struct
{
    //顶点坐标(x,y,z,w)
    vector_float4 position;
    //纹理坐标(s,t)
    vector_float2 textureCoordinate;
} WMVertexYUV;

//转换矩阵
typedef struct {
    //三维矩阵
    matrix_float3x3 matrix;
    //偏移量
    vector_float3 offset;
} WMConvertMatrix;

//顶点函数输入索引
typedef enum CCVertexInputIndex
{
    WMVertexInputIndexVertices     = 0,
} WMVertexInputIndex;

//片元函数缓存区索引
typedef enum CCFragmentBufferIndex
{
    WMFragmentInputIndexMatrix     = 0,
} WMFragmentBufferIndex;

//片元函数纹理索引
typedef enum CCFragmentTextureIndex
{
    //Y纹理
    WMFragmentTextureIndexTextureY     = 0,
    //UV纹理
    WMFragmentTextureIndexTextureUV     = 1,
} WMFragmentTextureIndex;


#endif /* CCShaderTypes_h */
