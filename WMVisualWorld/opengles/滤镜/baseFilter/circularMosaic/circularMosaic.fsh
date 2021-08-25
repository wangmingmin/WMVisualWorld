precision highp float;
uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;
const float radiusSize = 0.03;

void main (void) {
    
    float x = TextureCoordsVarying.x;
    float y = TextureCoordsVarying.y;

    float diameter = radiusSize*2.0;
    float centreX = floor(x/diameter)*diameter+radiusSize;
    float centreY = floor(y/diameter)*diameter+radiusSize;

    float s = sqrt(pow(x - centreX, 2.0) + pow(y - centreY, 2.0));
    
    vec2 new = TextureCoordsVarying;
    if (s<=radiusSize) {
        new = vec2(centreX, centreY);
    }
    vec4 mask = texture2D(Texture, new);
    gl_FragColor = mask;
}
