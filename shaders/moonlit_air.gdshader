shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
uniform vec3 mist_tint : source_color = vec3(0.48,0.64,0.76);
uniform float mist_amount = 0.055;
uniform float rays_amount = 0.045;
uniform vec2 drift = vec2(0.0);
float noise(vec2 p) { return sin(p.x*3.3+sin(p.y*2.1))*0.5+0.5; }
void fragment() {
    vec2 p=UV+drift;
    float veil=noise(vec2(p.x*4.0+clock*0.023,p.y*3.0-clock*0.011));
    veil*=noise(vec2(p.x*7.0-clock*0.017,p.y*5.0));
    float ray=0.0;
    for(int i=0;i<3;i++) {
        float origin=0.13+float(i)*0.36;
        float axis=p.x+p.y*0.28-origin-sin(clock*0.06+float(i))*0.012;
        float width=0.025+p.y*0.045;
        ray+=exp(-axis*axis/(width*width))*0.65;
    }
    ray*=1.0-smoothstep(0.05,0.9,UV.y);
    ray*=0.72+veil*0.28;
    float edge=smoothstep(0.22,0.77,length((UV-0.5)*vec2(1.0,0.78)));
    float alpha=veil*mist_amount+ray*rays_amount+edge*0.12;
    vec3 tint=mix(mist_tint,vec3(0.018,0.029,0.055),edge*0.85);
    tint=mix(tint,vec3(0.92,0.91,0.75),clamp(ray*0.35,0.0,0.3));
    COLOR=vec4(tint,alpha);
}
