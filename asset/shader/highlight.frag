extern vec4 FillColor;
extern vec4 OutlineColor;
extern int OutlineWidth;
extern vec2 TextureSize;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);

    if (texturecolor.a >= 0.999)
    {
        for (float x = -OutlineWidth; x <= OutlineWidth; x++)
        {
            for (float y = -OutlineWidth; y <= OutlineWidth; y++)
            {
                vec2 offset = vec2(x, y) / TextureSize;

                if (Texel(tex, texture_coords + offset).a < 0.001)
                {
                    return mix(texturecolor * color, OutlineColor, OutlineColor.a);
                }
            }
        }

        return mix(texturecolor * color, FillColor, FillColor.a);
    }

    return texturecolor * color;
}
