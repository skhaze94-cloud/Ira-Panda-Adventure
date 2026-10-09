shader_type canvas_item;
render_mode unshaded;
uniform sampler2D atlas : source_color, filter_linear;
uniform vec4 crops[20];
uniform vec2 atlas_size = vec2(1120.0,1400.0);
uniform vec2 viewport_size = vec2(1280.0,720.0);
uniform vec2 camera_offset = vec2(0.0);
uniform float tile_size = 58.0;
uniform int chapter = 0;
uniform float map_size = 65.0;
uniform vec3 ambient_tint : source_color = vec3(0.64,0.72,0.83);
uniform vec2 player_world = vec2(2.0,2.0);
uniform float pulse = 0.0;
uniform float clock = 0.0;
uniform float water_center = 40.0;
uniform float detail = 1.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float grain(vec2 p) {
    vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
uniform vec4 pools[6];
uniform vec3 pool_colors[6];
uniform int pool_count = 0;
float path_y(float x) {
    float e = smoothstep(3.0,12.0,x)*(1.0-smoothstep(map_size-12.0,map_size-3.0,x));
    float c = sin(x*0.24)*2.2;
    if(chapter==1) c=sin(x*0.15)*3.5+sin(x*0.39)*0.7;
    if(chapter==2) c=sin(x*0.10+0.5)*4.0;
    if(chapter==3) c=sin(x*0.12)*2.8;
    if(chapter==4) c=sin(x*0.19)*2.0;
    return x+c*e;
}
float segment_distance(vec2 p, vec2 a, vec2 b) {
    vec2 d=b-a;
    float u=clamp(dot(p-a,d)/max(dot(d,d),0.001),0.0,1.0);
    return length(p-(a+d*u));
}
vec3 sample_tile(int index,vec2 f) {
    vec4 crop=crops[index];
    return texture(atlas,(crop.xy+vec2(1.0)+f*(crop.zw-vec2(2.0)))/atlas_size).rgb;
}
void fragment() {
    vec2 projected=(UV*viewport_size-camera_offset)/tile_size;
    vec2 world=vec2((projected.x+projected.y/0.49)*0.5,(projected.y/0.49-projected.x)*0.5);
    vec2 cell=floor(world+vec2(0.5));
    vec2 local=fract(world+vec2(0.5));
    float distance_to_trail=abs(world.y-path_y(world.x));
    if(chapter==0) {
        vec2 a=vec2(24.0,path_y(24.0));
        vec2 b=vec2(26.0,path_y(26.0)+3.0);
        vec2 c=vec2(29.0,path_y(29.0)+6.0);
        distance_to_trail=min(distance_to_trail,min(segment_distance(world,a,b),segment_distance(world,b,c))+0.7);
    }
    int parity=int(mod(cell.x+cell.y,2.0));
    float organic=grain(world*1.7);
    float edge=smoothstep(1.65,2.8,distance_to_trail+(organic-0.5)*0.55);
    vec3 trail=sample_tile(chapter*4+parity,local);
    vec3 grass=sample_tile(chapter*4+2+parity,local);
    float variation=fract(sin(dot(cell,vec2(13.0,37.0))+float(chapter)*83.0)*43758.5453);
    vec3 base=mix(trail,grass,edge)*(0.91+variation*0.09);
    // Continuous world-space variation breaks the atlas grid and adds textile grain.
    float moss=grain(world*0.44);
    base*=0.92+0.14*moss;
    base=mix(base,base*vec3(0.88,1.07,0.97),edge*moss*0.28);
    if(detail>0.5) {
        float fibers=grain(world*29.0);
        base*=0.96+fibers*0.08;
    }
    float water=0.0;
    float shore=0.0;
    if(chapter==2) {
        vec2 river=world-vec2(water_center,path_y(water_center));
        float bank=max(abs(river.x)-0.8,abs(river.y)-5.0);
        water=1.0-smoothstep(-0.08,0.08,bank);
        shore=1.0-smoothstep(0.0,0.24,abs(bank));
        for(int j=0;j<4;j++) {
            float x=16.0; if(j==1)x=29.0; if(j==2)x=43.0; if(j==3)x=55.0;
            vec2 pool=(world-vec2(x,path_y(x)+5.8))/vec2(2.55,1.5);
            float d=length(pool);
            water=max(water,1.0-smoothstep(0.96,1.02,d));
            shore=max(shore,1.0-smoothstep(0.02,0.13,abs(d-1.0)));
        }
        float wave=sin(world.x*8.0+world.y*4.0+clock*1.5);
        float crosswave=sin(world.x*3.0-world.y*9.0-clock*0.8);
        float glint=pow(max(0.0,wave*0.5+crosswave*0.5),12.0);
        vec3 liquid=mix(vec3(0.07,0.22,0.30),vec3(0.19,0.43,0.48),grain(world*0.8+vec2(clock*0.015)));
        liquid+=vec3(0.51,0.76,0.78)*glint*(detail>0.5 ? 0.32 : 0.12);
        liquid+=vec3(0.08,0.17,0.20)*(wave+crosswave)*0.12;
        base=mix(base,liquid,water);
        base+=vec3(0.34,0.46,0.41)*shore*0.22;
    }
    vec3 lighting=ambient_tint;
    float personal=exp(-dot(world-player_world,world-player_world)/6.0);
    lighting+=vec3(0.24,0.16,0.06)*personal*(1.0+pulse*0.6);
    for(int i=0;i<6;i++) {
        if(i>=pool_count) break;
        vec2 delta=world-pools[i].xy;
        float glow=exp(-dot(delta,delta)/max(pools[i].w,0.1))*pools[i].z;
        lighting+=pool_colors[i]*glow*0.18;
    }
    COLOR=vec4(base*lighting,1.0);
}
