//
//  WMShaders.metal
//  002--MetalRenderMOV
//
//  Created by   on 2021年5/7.
//  Copyright © 2021年  . All rights reserved.
//

#include <metal_stdlib>
#import "WMYUVShaderTypes.h"

using namespace metal;

//结构体(用于顶点函数输出/片元函数输入)
typedef struct
{
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
    
    float2 textureCoordinate; // 纹理坐标
    
} WMRasterizerDataYUV;

//RasterizerData 返回数据类型->片元函数
// vertex_id是顶点shader每次处理的index，用于定位当前的顶点
// buffer表明是缓存数据，0是索引
vertex WMRasterizerDataYUV
vertexShaderYUV(uint vertexID [[ vertex_id ]],
             constant WMVertexYUV *vertexArray [[ buffer(WMVertexInputIndexVertices) ]])
{
    WMRasterizerDataYUV out;
    //顶点坐标
    out.clipSpacePosition = vertexArray[vertexID].position;
    //纹理坐标
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}


//YUV->RGB 参考学习链接: https://mp.weixin.qq.com/s/KKfkS5QpwPAdYcEwFAN9VA
// stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
// texture表明是纹理数据，WMFragmentTextureIndexTextureY是索引
// texture表明是纹理数据，WMFragmentTextureIndexTextureUV是索引
// buffer表明是缓存数据， WMFragmentInputIndexMatrix是索引
fragment float4
samplingShaderYUV(WMRasterizerDataYUV input [[stage_in]],
               texture2d<float> textureY [[ texture(WMFragmentTextureIndexTextureY) ]],
               texture2d<float> textureUV [[ texture(WMFragmentTextureIndexTextureUV) ]],
               constant WMConvertMatrix *convertMatrix [[ buffer(WMFragmentInputIndexMatrix) ]])
{
    //1.获取纹理采样器
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    /*
     2. 读取YUV 颜色值
        textureY.sample(textureSampler, input.textureCoordinate).r
        从textureY中的纹理采集器中读取,纹理坐标对应上的R值.(Y)
        textureUV.sample(textureSampler, input.textureCoordinate).rg
        从textureUV中的纹理采集器中读取,纹理坐标对应上的RG值.(UV)
     */
    float3 yuv = float3(textureY.sample(textureSampler, input.textureCoordinate).r,
                        textureUV.sample(textureSampler, input.textureCoordinate).rg);
    
    //3.将YUV 转化为 RGB值.convertMatrix->matrix * (YUV + convertMatrix->offset)
    float3 rgb = convertMatrix->matrix * (yuv + convertMatrix->offset);
    
    //4.返回颜色值(RGBA)
    return float4(rgb, 1.0);
}

