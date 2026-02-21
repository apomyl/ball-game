extends Node
## Sources: NASA Solar System Exploration (solarsystem.nasa.gov)
## solarsystem.nasa.gov/solar-system/sun/by-the-numbers
	
class_name SolarSystemData

## Each planet dict contains:
##  name        : display name
##  radius_re   : radius in Earth rad        (Earth = 1.0)
##  mass_me     : mass in Earth mas         (Earth = 1.0)
##  period_days : orbital period in Earth days
##  temp_k      : mean surface/cloud temperature 
##  description : flavour text shown in selection screen

const PLANETS: Array = [
	{
		"name": "The Sun",
		"radius_re": 109.076,
		"mass_me": 333000.0,
		"period_days": 25.38,    
		"temp_k": 5778,          
		"description": "The star at the heart of our solar system.",
		"is_star": true,

	},
	{
		"name": "Mercury",
		"radius_re": 0.383,
		"mass_me": 0.055,
		"period_days": 88.0,
		"temp_k": 440,
		"description": "The fastest planet in the Solar System\nDashes periodically\nIt's damage increases with it's speed.",
	},
	{
		"name": "Venus",
		"radius_re": 0.949,
		"mass_me": 0.815,
		"period_days": 224.7,
		"temp_k": 737,
		"description": "Hell wrapped in clouds of sulfuric acids that deal damage over time.",
	},
	{
		"name": "Earth",
		"radius_re": 1.0,
		"mass_me": 1.0,
		"period_days": 365.25,
		"temp_k": 288,
		"description": "The only known home of life.\nPerfectly balanced a true all rounder.\nComes with the Moon as an orbiting weapon.",
		"has_orbital_weapon": true,
		"orbital_weapon": "The Moon",
	},
	{
		"name": "The Moon",
		"radius_re": 0.273,
		"mass_me": 0.0123,
		"period_days": 27.3,
		"temp_k": 250,
		"description": "Earth's loyal companion.\nOrbit radius: 180 px  |  Orbit speed: 90 deg/s\nHits anything that strays too close.",
		"is_orbital_weapon": true,
		"orbit_radius_px": 180.0,
		"orbit_speed_deg": 90.0,
		"weapon_damage_mult": 1.4,
	},
	{
		"name": "Mars",
		"radius_re": 0.532,
		"mass_me": 0.107,
		"period_days": 687.0,
		"temp_k": 210,
		"description": "The Red Planet. Cold, thin-aired, and battered.\nHits with errupting volcanic projectiles",
	},
	{
		"name": "Jupiter",
		"radius_re": 11.21,
		"mass_me": 317.8,
		"period_days": 4333.0,
		"temp_k": 165,
		"description": "Enormous. Deals damage with it's presence.\nPushes enemies with strong winds and blocks with it's astroid wall.",
	},
	{
		"name": "Saturn",
		"radius_re": 9.45,
		"mass_me": 95.2,
		"period_days": 10759.0,
		"temp_k": 134,
		"description": "The ringed giant. Less dense than water.\nHuge target, deals damage with its rings.",
	},
	{
		"name": "Uranus",
		"radius_re": 4.01,
		"mass_me": 14.54,
		"period_days": 30589.0,
		"temp_k": 76,
		"description": "An ice giant rolling on its side.\nMedium size, freexes on hit.",
	},
	{
		"name": "Neptune",
		"radius_re": 3.88,
		"mass_me": 17.15,
		"period_days": 59800.0,
		"temp_k": 72,
		"description": "Slowest in the arena. Iron fist, frozen glove.",
	},
	{
		"name": "Pluto",
		"radius_re": 0.187,
		"mass_me": 0.0022,
		"period_days": 90560.0,
		"temp_k": 44,
		"description": "The dwarf planet that refused to give up.\nWhenever Pluto takes damage it increases it's own.",
	},
]


static func remap(value: float, src_min: float, src_max: float,
				   dst_min: float, dst_max: float) -> float:
	var t = clamp((value - src_min) / (src_max - src_min), 0.0, 1.0)
	return lerp(dst_min, dst_max, t)


static func compute_stats(p: Dictionary) -> Dictionary:
	var r      = p["radius_re"]
	var m      = p["mass_me"]
	var period = p["period_days"]
	var temp   = p["temp_k"]
	var is_star: bool = p.get("is_star", false)


	# Density relative to Earth (Earth = 1.0)
	var density_rel: float = m / (r * r * r)

	# Arena radius: Pluto (0.187) → ~12 px, Jupiter (11.21) → ~160 px
	var arena_radius: float
	if is_star:
		arena_radius = 210.0
	else:
		arena_radius = remap(r, 0.1, 12.0, 12.0, 160.0)

	# Max health: dense rocky worlds are tough, gas giants are squishy
	var max_health: float = remap(density_rel, 0.005, 4.0, 40.0, 320.0)
	if is_star:
		max_health = 9999.0  


	# Speed: shorter period → faster
	var speed: float = remap(period, 25.0, 60000.0, 420.0, 45.0)

	# Damage multiplier: mass drives impact force
	var damage_mult: float
	if is_star:
		damage_mult = 8.0   
	else:
		damage_mult = remap(m, 0.01, 320.0, 0.3, 3.0)



	return {
		"arena_radius": arena_radius,
		"max_health":   max_health,
		"speed":        speed,
		"damage_mult":  damage_mult,
		"density_rel":  density_rel,
	}

static func get_orbital_weapon(planet: Dictionary) -> Variant:
	if not planet.get("has_orbital_weapon", false):
		return null
	var weapon_name: String = planet["orbital_weapon"]
	for p in PLANETS:
		if p["name"] == weapon_name:
			return p
	return null
