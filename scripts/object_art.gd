extends RefCounted
## Original illustrations sampled unchanged; four current-chapter textures in memory.
var textures: Array=[]
var regions: Dictionary={}
var loaded_chapter:=-1
const CHAPTERS=["woods","glade","brook","hollow","garden"]
const TINTS=[Color("#bca77b"),Color("#b8a1cf"),Color("#a8c5bd"),Color("#adb6d7"),Color("#dcc0ba")]
func load_assets() -> void:
	regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/objects/regions.json"))
	for chapter in CHAPTERS:textures.append({})
func ensure_chapter(index: int) -> void:
	if loaded_chapter==index:return
	if loaded_chapter>=0:textures[loaded_chapter].clear()
	for kind in ["bridge","pumpkin","sign","prop"]:textures[index][kind]=load("res://assets/objects/"+CHAPTERS[index]+"-"+kind+".png")
	loaded_chapter=index
func rect(g: Control, kind: String) -> Rect2:
	var r: Array=regions[CHAPTERS[g.level_index]+"-"+kind]
	return Rect2(r[0],r[1],r[2],r[3])
func prop(g: Control, data: Dictionary) -> void:
	var kind: String=data.kind;var at: Vector2=g._project(data.pos)
	var h: float=g.tile*(1.75 if kind=="sign" else 1.40 if kind=="pumpkin" else 1.65)
	var src:=rect(g,kind);var w:=h*src.size.x/src.size.y
	var response: float=data.response
	var squash: float=0 if g.quieter_motion else sin(response*11)*response*.025
	var lift: float=0 if g.quieter_motion else maxf(0,sin(response*7))*response*3
	g._shadow(at,w*.3)
	if kind=="pumpkin":g._draw_halo(at-Vector2(0,h*.42),h*.55,Color("#ffce91"),.6+response*.5)
	if response>0:g._draw_halo(at-Vector2(0,h*.5),h*.6,TINTS[g.level_index],response*.75)
	g.draw_set_transform(at-Vector2(0,lift),squash*.3,Vector2(1+squash,1-squash))
	g.draw_texture_rect_region(textures[g.level_index][kind],Rect2(Vector2(-w*.5,-h),Vector2(w,h)),src)
	g.draw_set_transform(Vector2.ZERO)
	if response>0:
		var clock: float=0 if g.quieter_motion else g.living.clock
		for i in range(4):
			g._disc(at+Vector2(cos(clock+float(i)*1.6)*w*.4,-h*.65+sin(clock*.8+i)*12),1.6,Color(1,.91,.74,response*.35))
func point(g: Control, c: Dictionary, t: float, lane: float) -> Vector2:
	var x: float=c.x+lerpf(-c.width-.32,c.width+.32,t)
	return g._project(Vector2(x,g.pathways.crossing_y(c,x)+c.offset+lane))
func panel(g: Control, c: Dictionary, lo: float, hi: float) -> void:
	var vertices:=PackedVector2Array([point(g,c,lo,-2),point(g,c,hi,-2),point(g,c,hi,2),point(g,c,lo,2)])
	var texture: Texture2D=textures[g.level_index].bridge;var source:=rect(g,"bridge");var dimensions:=texture.get_size()
	var uv:=PackedVector2Array([(source.position+Vector2(0,source.size.y*lo))/dimensions,(source.position+Vector2(0,source.size.y*hi))/dimensions,(source.position+Vector2(source.size.x,source.size.y*hi))/dimensions,(source.position+Vector2(source.size.x,source.size.y*lo))/dimensions])
	g.draw_polygon(vertices,PackedColorArray([Color.WHITE,Color.WHITE,Color.WHITE,Color.WHITE]),uv,texture)
	g.draw_colored_polygon(PackedVector2Array([vertices[3],vertices[2],vertices[2]+Vector2(0,9),vertices[3]+Vector2(0,9)]),Color("#665342").lerp(TINTS[g.level_index],.2))
	g.draw_line(vertices[3],vertices[2],TINTS[g.level_index].lightened(.15),2,true)
func crossing(g: Control, c: Dictionary) -> void:
	var open: bool=c.kind!="repair" or g.quest_done
	var progress: float=1 if c.kind!="repair" else g.personality.repair if open else 0
	if not open:panel(g,c,0,.25);panel(g,c,.75,1)
	elif progress<1:
		panel(g,c,0,maxf(.25,progress))
		if progress<.75:panel(g,c,.75,1)
	else:panel(g,c,0,1)
	for side in [-1.0,1.0]:
		var bank:=Vector2(c.x+side*(c.width+.48),g.pathways.crossing_y(c,c.x+side*(c.width+.48))+c.offset)
		for lane in [-2.5,2.5]:
			var edge: Vector2=bank+Vector2(0,lane)
			g.PATHWAY_ART._stone(g,edge,Vector2(.20,.30),int(bank.x));g._storybook_fern(g._project(edge),bank.x+lane)
	rail(g,c,-1)
func wood_strip(g: Control, a: Vector2, b: Vector2, width: float) -> void:
	var normal: Vector2=(b-a).normalized().orthogonal()*width*.5
	var texture: Texture2D=textures[g.level_index].bridge;var region:=rect(g,"bridge");var size:=texture.get_size()
	var source:=Rect2(region.position+region.size*Vector2(.3,.14),region.size*Vector2(.4,.07))
	g.draw_polygon(PackedVector2Array([a-normal,b-normal,b+normal,a+normal]),PackedColorArray([Color.WHITE,Color.WHITE,Color.WHITE,Color.WHITE]),PackedVector2Array([source.position/size,(source.position+Vector2(source.size.x,0))/size,source.end/size,(source.position+Vector2(0,source.size.y))/size]),texture)
func rail(g: Control, c: Dictionary, side: int) -> void:
	if c.kind=="repair" and (not g.quest_done or g.personality.repair<.99):return
	var points:=PackedVector2Array()
	for i in range(17):
		var t:=float(i)/16;var foot:=point(g,c,t,side*2.02)
		points.append(foot-Vector2(0,34-5*sin(t*PI)))
		if i in [0,8,16]:
			wood_strip(g,foot+Vector2(0,5),foot-Vector2(0,46),8)
			g.draw_line(foot+Vector2(-2,0),foot-Vector2(2,43),TINTS[g.level_index],2,true)
			g._disc(foot-Vector2(0,47),5,TINTS[g.level_index].lightened(.3))
			g._draw_halo(foot-Vector2(0,46),24,TINTS[g.level_index],.8)
	for i in range(points.size()-1):wood_strip(g,points[i],points[i+1],4.5)
	for i in [4,12]:
		var pin: Vector2=points[i];g.draw_line(pin,pin+Vector2(0,10),TINTS[g.level_index],1.3,true);g._disc(pin+Vector2(0,13),3,Color("#eace9b"))
