@tool
extends Node2D

## Procedural Zelda/Pokémon-dungeon room visuals.
## Place as a Node2D inside the Background CanvasLayer (layer = -10).
## Draws stone-tile floor, brick walls, crystal accents, entry arch,
## exit glow, and corner vignette — all fully parameterised per level.

@export var floor_color     : Color = Color(0.08, 0.12, 0.18, 1.0)
@export var wall_color      : Color = Color(0.14, 0.22, 0.32, 1.0)
@export var crystal_hue     : float = 0.55    # 0 = red  0.55 = teal  0.75 = purple
@export var show_entry_arch : bool  = true
@export var show_exit_glow  : bool  = true

const RW        : float = 1920.0
const RH        : float = 1080.0
const WALL_T    : float = 48.0
const TILE      : float = 64.0
const TILE_DISP : float = 480.0   # on-screen size of one texture tile (px)

var _t         : float    = 0.0
var _floor_tex : Texture2D = null

func _ready() -> void:
	const TEX_PATH := "res://echoveil/backgrounds/floor_tile.png"
	if ResourceLoader.exists(TEX_PATH):
		# Standard path — works after Godot has run its importer
		_floor_tex = load(TEX_PATH) as Texture2D
	else:
		# Fallback: load raw PNG bytes directly (no .import file required)
		var global_path : String = ProjectSettings.globalize_path(TEX_PATH)
		var img : Image = Image.load_from_file(global_path)
		if img != null:
			_floor_tex = ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	_t += delta * 1.6
	queue_redraw()

func _draw() -> void:
	_draw_floor()
	_draw_walls()
	if show_entry_arch:
		_draw_entry_arch()
	if show_exit_glow:
		_draw_exit_glow()
	_draw_crystals()
	_draw_vignette()

# ── Floor ──────────────────────────────────────────────────────────────────────
func _draw_floor() -> void:
	# Black base fills the full room (covers wall band area)
	draw_rect(Rect2(0.0, 0.0, RW, RH), Color(0.0, 0.0, 0.0, 1.0))

	var x0 : float = WALL_T
	var y0 : float = WALL_T
	var x1 : float = RW - WALL_T
	var y1 : float = RH - WALL_T

	if _floor_tex != null:
		_draw_floor_textured(x0, y0, x1, y1)
		# Per-level colour-theme tint over the texture
		var tint : Color = Color(floor_color.r, floor_color.g, floor_color.b, 0.30)
		draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), tint)
	else:
		_draw_floor_procedural(x0, y0, x1, y1)

## Tile the stone floor texture across the inner floor rect.
func _draw_floor_textured(x0: float, y0: float, x1: float, y1: float) -> void:
	var tex_w : float = float(_floor_tex.get_width())
	var tex_h : float = float(_floor_tex.get_height())
	var tx    : float = x0
	while tx < x1:
		var ty : float = y0
		while ty < y1:
			var dw : float = minf(TILE_DISP, x1 - tx)
			var dh : float = minf(TILE_DISP, y1 - ty)
			# Source rect proportional to the drawn fraction of a tile
			var sw : float = (dw / TILE_DISP) * tex_w
			var sh : float = (dh / TILE_DISP) * tex_h
			draw_texture_rect_region(
				_floor_tex,
				Rect2(tx, ty, dw, dh),
				Rect2(0.0, 0.0, sw, sh))
			ty += TILE_DISP
		tx += TILE_DISP

## Procedural checkerboard — used as fallback before the texture is imported.
func _draw_floor_procedural(x0: float, y0: float, x1: float, y1: float) -> void:
	draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), floor_color)
	var alt  : Color = floor_color.lightened(0.055)
	var ci   : int   = 0
	var tx   : float = x0
	while tx < x1:
		var ri : int   = 0
		var ty : float = y0
		while ty < y1:
			if (ci + ri) % 2 == 1:
				var tw : float = minf(TILE, x1 - tx)
				var th : float = minf(TILE, y1 - ty)
				draw_rect(Rect2(tx, ty, tw, th), alt)
			ty += TILE
			ri += 1
		tx += TILE
		ci += 1
	var mort : Color = Color(0.0, 0.0, 0.0, 0.22)
	var gx   : float = x0
	while gx <= x1:
		draw_line(Vector2(gx, y0), Vector2(gx, y1), mort, 1.0)
		gx += TILE
	var gy : float = y0
	while gy <= y1:
		draw_line(Vector2(x0, gy), Vector2(x1, gy), mort, 1.0)
		gy += TILE

# ── Walls ──────────────────────────────────────────────────────────────────────
func _draw_walls() -> void:
	var wc   : Color = wall_color
	var hi   : Color = wc.lightened(0.12)
	var mort : Color = wc.darkened(0.30)
	var sh   : Color = Color(0.0, 0.0, 0.0, 0.45)

	draw_rect(Rect2(0.0,          0.0,          RW,     WALL_T), wc)
	draw_rect(Rect2(0.0,          RH - WALL_T,  RW,     WALL_T), wc)
	draw_rect(Rect2(0.0,          0.0,          WALL_T, RH    ), wc)
	draw_rect(Rect2(RW - WALL_T,  0.0,          WALL_T, RH    ), wc)

	_bricks(0.0,          0.0,          RW,     WALL_T, 72.0, 24.0, mort, hi)
	_bricks(0.0,          RH - WALL_T,  RW,     WALL_T, 72.0, 24.0, mort, hi)
	_bricks(0.0,          0.0,          WALL_T, RH,     24.0, 64.0, mort, hi)
	_bricks(RW - WALL_T,  0.0,          WALL_T, RH,     24.0, 64.0, mort, hi)

	# Inner shadow edge
	draw_line(Vector2(WALL_T,      WALL_T),      Vector2(RW - WALL_T, WALL_T),      sh, 3.0)
	draw_line(Vector2(WALL_T,      RH - WALL_T), Vector2(RW - WALL_T, RH - WALL_T), sh, 3.0)
	draw_line(Vector2(WALL_T,      WALL_T),      Vector2(WALL_T,      RH - WALL_T), sh, 3.0)
	draw_line(Vector2(RW - WALL_T, WALL_T),      Vector2(RW - WALL_T, RH - WALL_T), sh, 3.0)

## Brick pattern inside the given axis-aligned rect.
func _bricks(rx: float, ry: float, rw: float, rh: float,
			 brick_w: float, brick_h: float,
			 mort: Color, hi: Color) -> void:
	var rows : int = int(ceil(rh / brick_h))
	for row in range(rows):
		var ry0 : float = ry + float(row) * brick_h
		var ry1 : float = minf(ry0 + brick_h, ry + rh)
		if ry0 >= ry + rh:
			break
		if row > 0 and ry0 > ry:
			draw_line(Vector2(rx, ry0), Vector2(rx + rw, ry0), mort, 1.5)
		var off : float = (brick_w * 0.5) if (row % 2 == 1) else 0.0
		var cx  : float = rx - off
		while cx < rx + rw:
			var bx0 : float = maxf(cx, rx)
			var bx1 : float = minf(cx + brick_w, rx + rw)
			# Vertical mortar
			if cx > rx and bx0 > rx:
				draw_line(Vector2(bx0, ry0), Vector2(bx0, ry1), mort, 1.5)
			# Brick highlight
			if bx1 > bx0 + 6.0:
				var hly : float = ry0 + 3.0
				if hly < ry1 - 1.0 and hly > ry:
					draw_line(Vector2(bx0 + 3.0, hly), Vector2(bx1 - 3.0, hly), hi, 0.9)
			cx += brick_w

# ── Entry arch (left wall) ─────────────────────────────────────────────────────
func _draw_entry_arch() -> void:
	var cx  : float = WALL_T * 0.5
	var cy  : float = RH * 0.5
	var ah  : float = 80.0    # half-height of door opening
	var aw  : float = 20.0    # arch radius (fits within WALL_T=48)
	var ga  : float = 0.14 + sin(_t) * 0.06
	var gc  : Color = Color.from_hsv(crystal_hue, 0.55, 1.0,          ga)
	var ac  : Color = Color.from_hsv(crystal_hue, 0.52, 0.88,         0.82)
	var pc  : Color = Color.from_hsv(crystal_hue, 0.38, 0.62,         0.90)
	var dfc : Color = floor_color.lightened(0.07)

	# Door-opening patch (slightly brighter floor colour)
	draw_rect(Rect2(0.0, cy - ah, WALL_T, ah * 2.0), dfc)
	# Pulsing crystal glow overlay
	draw_rect(Rect2(0.0, cy - ah, WALL_T, ah * 2.0), gc)
	# Arch cap — semicircle spanning the top of the opening (PI → TAU = top arc)
	draw_arc(Vector2(cx, cy - ah + aw), aw + 1.0, PI, TAU, 20, ac, 3.5, true)
	# Side pillar slabs — height spans from arch base down to door bottom
	var slab_h : float = 2.0 * ah - aw - 2.0
	draw_rect(Rect2(2.0,          cy - ah + aw, 6.0, slab_h), pc)
	draw_rect(Rect2(WALL_T - 8.0, cy - ah + aw, 6.0, slab_h), pc)

# ── Exit glow (right wall) ─────────────────────────────────────────────────────
func _draw_exit_glow() -> void:
	var gx : float = RW - WALL_T * 0.5
	var gy : float = RH * 0.5
	var pa : float = 0.22 + sin(_t * 1.2) * 0.09
	var gc : Color = Color.from_hsv(crystal_hue, 0.72, 1.0, pa)
	for layer in range(7):
		var r : float = 28.0 + float(layer) * 34.0
		var a : float = pa * (1.0 - float(layer) / 7.0)
		draw_circle(Vector2(gx, gy), r, Color(gc.r, gc.g, gc.b, a))

# ── Crystal clusters ───────────────────────────────────────────────────────────
func _draw_crystals() -> void:
	# Four corners
	_crystal_cluster(Vector2(WALL_T + 10.0,       WALL_T + 10.0),       crystal_hue, 5)
	_crystal_cluster(Vector2(RW - WALL_T - 10.0,  WALL_T + 10.0),       crystal_hue, 5)
	_crystal_cluster(Vector2(WALL_T + 10.0,       RH - WALL_T - 10.0),  crystal_hue, 5)
	_crystal_cluster(Vector2(RW - WALL_T - 10.0,  RH - WALL_T - 10.0),  crystal_hue, 5)
	# Wall mid-points
	_crystal_cluster(Vector2(RW * 0.5,  WALL_T + 6.0),      crystal_hue, 3)
	_crystal_cluster(Vector2(RW * 0.5,  RH - WALL_T - 6.0), crystal_hue, 3)
	_crystal_cluster(Vector2(WALL_T + 6.0,      RH * 0.5),  crystal_hue, 3)
	_crystal_cluster(Vector2(RW - WALL_T - 6.0, RH * 0.5),  crystal_hue, 3)

func _crystal_cluster(pos: Vector2, hue: float, count: int) -> void:
	var sv  : int  = (int(pos.x) * 7 + int(pos.y) * 13) & 0x7FFFFFFF
	var rng : RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = sv
	var pb  : float = sin(_t + float(sv % 100) * 0.06) * 0.5 + 0.5
	for i in range(count):
		var angle : float = (float(i) / float(count)) * TAU + float(sv & 63) * 0.10
		var dist  : float = rng.randf_range(4.0, 14.0)
		var ht    : float = rng.randf_range(7.0, 20.0)
		var wd    : float = rng.randf_range(3.0, 6.0)
		var sat   : float = rng.randf_range(0.55, 0.85)
		var bri   : float = clampf(rng.randf_range(0.50, 0.88) + pb * 0.12, 0.0, 1.0)
		var col   : Color = Color.from_hsv(
				hue + rng.randf_range(-0.06, 0.06), sat, bri, 0.88)
		var tip   : Vector2 = pos + Vector2(cos(angle), sin(angle)) * dist
		var base  : Vector2 = tip + Vector2(cos(angle), sin(angle)) * ht
		var perp  : Vector2 = Vector2(-sin(angle), cos(angle)) * wd * 0.5
		var pts   : PackedVector2Array = PackedVector2Array([tip, base - perp, base + perp])
		var cols  : PackedColorArray   = PackedColorArray([
				col, col.darkened(0.35), col.darkened(0.35)])
		draw_polygon(pts, cols)
		draw_line(tip, base - perp, col.lightened(0.30), 0.8)

# ── Corner vignette ────────────────────────────────────────────────────────────
func _draw_vignette() -> void:
	var corners : Array[Vector2] = [
		Vector2(0.0, 0.0), Vector2(RW, 0.0),
		Vector2(0.0, RH),  Vector2(RW, RH),
	]
	for corner : Vector2 in corners:
		for k in range(6):
			var r : float = 100.0 + float(k) * 90.0
			var a : float = 0.20 * (1.0 - float(k) / 6.0)
			draw_circle(corner, r, Color(0.0, 0.0, 0.0, a))
