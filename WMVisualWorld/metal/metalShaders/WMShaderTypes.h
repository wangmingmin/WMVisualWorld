//
//  WMShaderTypes.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/6.
//

#ifndef WMShaderTypes_h
#define WMShaderTypes_h
// 缓存区索引值 共享与 shader 和 C 代码 为了确保Metal Shader缓存区索引能够匹配 Metal API Buffer 设置的集合调用
typedef enum WMVertexInputIndex
{
    //顶点
    WMVertexInputIndexVertices     = 0,
    //视图大小
    WMVertexInputIndexViewportSize = 1,
} WMVertexInputIndex;

//纹理索引
typedef enum WMTextureIndex
{
    WMTextureIndexBaseColor = 0
}WMTextureIndex;

//结构体: 顶点/颜色值
typedef struct
{
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float4 position;

    // RGBA颜色
    vector_float4 color;
    
} WMVertex;

//结构体: 顶点/颜色值
typedef struct
{
    // 像素空间的位置
    // 像素中心点(100,100)
    vector_float2 position;
    // 2D 纹理
    vector_float2 textureCoordinate;
} WMTextureVertex;

#endif

