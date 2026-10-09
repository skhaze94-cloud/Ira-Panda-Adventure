shader_type canvas_item;
// Subtle relief reconstructed from the existing textile/paint texture.
// Alpha boundaries are excluded so silhouettes do not acquire dark fringes.
uniform float relief : hint_range(0.0, 1.0) = 0.22;
void fragment() {
    vec4 base = COLOR;
    vec2 px = TEXTURE_PIXEL_SIZE;
    vec4 left = texture(TEXTURE, UV - vec2(px.x, 0.0));
    vec4 right = texture(TEXTURE, UV + vec2(px.x, 0.0));
    vec4 above = texture(TEXTURE, UV - vec2(0.0, px.y));
    vec4 below = texture(TEXTURE, UV + vec2(0.0, px.y));
    vec3 weights = vec3(0.299, 0.587, 0.114);
    vec2 gradient = vec2(dot(left.rgb-right.rgb, weights), dot(above.rgb-below.rgb, weights));
    float interior = min(min(left.a,right.a),min(above.a,below.a));
    vec3 normal = normalize(vec3(gradient * relief * interior * 3.0, 1.0));
    NORMAL_MAP = normal * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = 0.65;
    LIGHT_VERTEX.z = 14.0;
    COLOR = base;
}
