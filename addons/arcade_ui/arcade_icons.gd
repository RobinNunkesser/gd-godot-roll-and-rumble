class_name ArcadeIcons
extends RefCounted

## Prozedurale, WASM-sichere 20x20-SVG-Icons (kein System-Emoji-Font nötig).

const _SVGS := {
	"play": '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="white"><polygon points="6,4 20,12 6,20"/></svg>',
	"players": '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="white"><circle cx="9" cy="8" r="3.5"/><path d="M2 19c0-3.3 3.1-5.5 7-5.5s7 2.2 7 5.5v1H2v-1z"/><circle cx="17" cy="9" r="2.6"/><path d="M16.5 14c2.8.3 5.5 1.9 5.5 4.8V20h-4.5v-1.2c0-1.9-.6-3.5-1.5-4.8z"/></svg>',
	"arena": '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2"><rect x="3" y="5" width="18" height="14" rx="2"/><line x1="12" y1="5" x2="12" y2="19"/><circle cx="12" cy="12" r="3"/></svg>',
	"trophy": '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2"><path d="M7 4h10v5a5 5 0 0 1-10 0V4z"/><path d="M7 6H4v2a3 3 0 0 0 3 3"/><path d="M17 6h3v2a3 3 0 0 1-3 3"/><line x1="12" y1="14" x2="12" y2="18"/><line x1="8" y1="20" x2="16" y2="20"/></svg>',
	"settings": '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2"><circle cx="12" cy="12" r="3.2"/><path d="M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1L7 17M17 7l2.1-2.1"/></svg>',
	"leaderboard": '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="white"><rect x="3" y="12" width="5" height="9" rx="1"/><rect x="9.5" y="5" width="5" height="16" rx="1"/><rect x="16" y="9" width="5" height="12" rx="1"/></svg>',
	"edit": '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2"><path d="M4 20h4l10.5-10.5a2 2 0 0 0-4-4L4 16v4z"/></svg>',
	"back": '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.4"><polyline points="15 18 9 12 15 6"/></svg>',
}

static var _cache: Dictionary = {}

static func get_icon(icon_name: String) -> ImageTexture:
	if _cache.has(icon_name):
		return _cache[icon_name]
	var svg: String = _SVGS.get(icon_name, "")
	if svg == "":
		return null
	var img := Image.new()
	if img.load_svg_from_string(svg) != OK:
		return null
	var tex := ImageTexture.create_from_image(img)
	_cache[icon_name] = tex
	return tex
