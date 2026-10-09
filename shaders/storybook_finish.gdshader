shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene : hint_screen_texture, repeat_disable, filter_linear;
uniform float quality = 1.0;
uniform vec3 palette : source_color = vec3(1.0,0.91,0.78);
void fragment() {
    vec3 c=texture(scene,SCREEN_UV).rgb;
    if(quality>1.5) {
        vec2 p=SCREEN_PIXEL_SIZE*3.0;
        vec3 blur=(texture(scene,SCREEN_UV+vec2(p.x,p.y)).rgb+
                   texture(scene,SCREEN_UV+vec2(-p.x,p.y)).rgb+
                   texture(scene,SCREEN_UV+vec2(p.x,-p.y)).rgb+
                   texture(scene,SCREEN_UV-vec2(p.x,p.y)).rgb)*0.25;
        c+=max(blur-vec3(0.68),vec3(0.0))*0.16;
    }
    float lum=dot(c,vec3(0.2126,0.7152,0.0722));
    c=mix(vec3(lum),c,1.04);
    c+=palette*pow(max(lum-0.35,0.0),2.0)*0.025;
    float edge=smoothstep(0.33,0.80,length((UV-0.5)*vec2(1.0,0.78)));
    c*=1.0-edge*0.055;
    COLOR=vec4(clamp(c,vec3(0.0),vec3(1.0)),1.0);
}
