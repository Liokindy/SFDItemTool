extern vec3 PrimaryPalette[5];
extern vec3 SecondaryPalette[5];
extern vec3 TertiaryPalette[5];
float PaletteShades[5] = float[5](255.0f / 255.0f, 192.0f / 255.0f, 128.0f / 255.0f, 64.0f / 255.0f, 32.0f / 255.0f);

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);

    for(int channel = 0; channel < 3; channel++)
    {
        for(int shade = 0; shade < 5; shade++)
        {
            if (texturecolor[channel] == PaletteShades[shade])
            {
                vec3 palette;
                if (channel == 0) { palette = PrimaryPalette[shade]; }
                else if (channel == 1) { palette = SecondaryPalette[shade]; }
                else if (channel == 2) { palette = TertiaryPalette[shade]; }

                texturecolor[0] = palette[0];
                texturecolor[1] = palette[1];
                texturecolor[2] = palette[2];

                return texturecolor * color;
            }
        }
    }

    return texturecolor * color;
}
