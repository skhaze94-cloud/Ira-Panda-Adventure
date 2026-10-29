extends RefCounted
## Forty-five playful encounters, saved separately from quest and crown progress.
var game: Control
var items: Array=[]
const JOKES=["The pumpkin whispers BOO! Then it giggles so much its leaf hat wobbles.","The purple pumpkin tries a spooky voice. Its mushroom hat is much too ticklish!", "This pumpkin wore spectacles so it could see who to frighten. It decides to say hello instead.","Abraca-pumpkin! This wizard knows one spell: making everybody giggle.","This pumpkin says boo very politely, then offers everybody a biscuit."]
const TOYS=["Biscuit Boo is guarding one biscuit. It is an extremely important ghost job.","Postmaster Mushroom has a letter for Ira. The snail insists on delivering it personally.","Captain Quack sails the tiniest ship in the brook. His spoon is also his emergency lunch paddle.","Professor Flap is looking for the Biscuit Constellation. Apparently it is delicious.","Teapot Tilly is a haunted cottage with excellent manners. The little ghost waves hello!"]
func build(g: Control) -> void:
	game=g;items.clear()
	for branch in game.beauty.paths:
		var points: Array=branch.points
		for data in [{"pos":game.living.safe_spot(points[0]+Vector2(-.5,.9)),"kind":"sign"},{"pos":game.living.safe_spot(points[1]+Vector2(.8,-.5)),"kind":"pumpkin"},{"pos":game.living.safe_spot(points[2]+Vector2(-.9,.7)),"kind":"prop"}]:
			data.merge({"index":items.size(),"found":false,"response":0.0,"branch":branch.index});items.append(data)
func nearest() -> int:
	var best:=-1;var distance: float=game.INTERACT_RADIUS
	for item in items:
		var d: float=game.player.distance_to(item.pos)
		if d<distance:best=item.index;distance=d
	return best
func caption(item: Dictionary) -> String:
	match str(item.kind):
		"pumpkin":return JOKES[game.level_index]
		"prop":return TOYS[game.level_index]
		_:return "A little side trail! Follow the stars to a treasure chest. Shine to see the clasp; press E or OPEN CHEST to peek inside."
func interact() -> bool:
	var index:=nearest()
	if index<0:return false
	var item: Dictionary=items[index];item.found=true;item.response=1.6
	game.personality.react("celebrate",.65);game.soundscape.play("pickup",.85,-20)
	game.show_toast(caption(item),3.8);game.journal.checkpoint();return true
func glow() -> void:
	var closest:=-1;var distance:=4.5
	for item in items:
		var d: float=game.player.distance_to(item.pos)
		if d<4.5:item.response=1.6
		if d<distance and item.kind!="sign":closest=item.index;distance=d
	if closest>=0:
		var item: Dictionary=items[closest]
		if not item.found:item.found=true;game.show_toast(caption(item),3.8)
func update(dt: float) -> void:
	if game.state!="play":return
	for item in items:item.response=maxf(0,item.response-dt)
func saved() -> Array:
	var flags: Array=[]
	for item in items:flags.append(item.found)
	return flags
func restore(data: Array) -> void:
	for i in range(mini(data.size(),items.size())):items[i].found=bool(data[i])
