class_name PixelArtLibrary
extends RefCounted

const Palette := preload("res://scripts/systems/pixel_palette.gd")

const PALETTE := {
	"O": Color("241713"),
	"W": Color("fffbe8"),
	"K": Color("100b09"),
	"R": Color("e0574f"),
	"r": Color("a4353b"),
	"G": Color("58b34a"),
	"g": Color("8ed45a"),
	"d": Color("2f7a34"),
	"Y": Color("ffe066"),
	"y": Color("fff3b0"),
	"B": Color("3a6fd8"),
	"b": Color("215ccf"),
	"P": Color("7673b6"),
	"p": Color("4c4f80"),
	"C": Color("7ff4c9"),
	"c": Color("22564e"),
	"T": Color("a9713f"),
	"t": Color("5b4029"),
	"S": Color("b6bfc7"),
	"s": Color("5f6870"),
	"A": Color("ffcf4d"),
	"H": Color("a9713f"),
	"h": Color("5b4029"),
	"L": Color("61d6ff"),
	"l": Color("8cdfff"),
}

static func enemy_texture(kind: String) -> ImageTexture:
	var art := _enemy_art(kind)
	return _texture(art["rows"], art["palette"])

static func boss_texture(region_id: String) -> ImageTexture:
	var art := _boss_art(region_id)
	return _texture(art["rows"], art["palette"])

static func equipment_texture(id: String) -> ImageTexture:
	var art := _equipment_art(id)
	return _texture(art["rows"], art["palette"])

static func _texture(rows: PackedStringArray, palette: Dictionary) -> ImageTexture:
	var width := 1
	for row in rows:
		width = maxi(width, row.length())
	var image := Image.create(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in range(rows.size()):
		var row: String = rows[y]
		for x in range(row.length()):
			var key := row[x]
			if palette.has(key):
				image.set_pixel(x, y, palette[key])
	return ImageTexture.create_from_image(image)

static func _art(rows: Array) -> Dictionary:
	var packed := PackedStringArray()
	for row in rows:
		packed.append(str(row))
	return {"rows": packed, "palette": PALETTE}

static func _enemy_art(kind: String) -> Dictionary:
	match kind:
		"pollen_bee":
			return _art([
				"....................",
				"......WW....WW......",
				".....WWWW..WWWW.....",
				"......OOOOOOOO......",
				".....OYYYYYYYYO.....",
				"....OYKKYYKKYYO....",
				"....OYYYYYYYYYYO...",
				"....OYKKYYKKYYO....",
				".....OYYYYYYYYO....",
				"......OOOOOOOO......",
				"........O..O........",
				"........O..O........",
				".........OO........."
			])
		"thorn_roller":
			return _art([
				"........AA..........",
				"......AAOOOOAA......",
				"....OOHHHHHHHHOO....",
				"...OHtttttttttHO...",
				"..OHthhtWWhthtHO...",
				".AAHthhHKKHHthtHAA.",
				"..OHthhtWWhthtHO...",
				"...OHtttttttttHO...",
				"....OOHtttttHOO....",
				"......AHHHHHA......",
				".....OOOOOOOOOO....."
			])
		"spore_lobber":
			return _art([
				"......OOOOOOO.......",
				"....OOGGGGGGGOO.....",
				"...OGGGWWGGGGGGO....",
				"..OGGGGGGGGGGGGGO...",
				"..OdOWWdOOWWdOdo....",
				"...OdTTTTTTTTdO.....",
				"...OTtTGGGGTtTO.....",
				"...OTTTTGGTTTTO.....",
				"...OdTTTTTTTTdO.....",
				"....OOTT..TTOO......",
				".....OO....OO......."
			])
		"spore_puppet":
			return _art([
				".....OOOOOOOOO......",
				"...OORRRWWRRRROO....",
				"..ORRRRWWWWRRRRRO...",
				".ORRRWWRRRRWWRRRRO..",
				".ORRRRRRRRRRRRRRRO..",
				"..OOORRROOORRROOO...",
				"....OTTWOTTWOTTO....",
				"....OTTTOTTTOTTO....",
				"....OTtTOTtTOTTO....",
				".....OOOTTTOOOO.....",
				".......OO.OO........"
			])
		"root_ambusher":
			return _art([
				"....................",
				".....OOOOOOOOO......",
				"....OddddddddO......",
				"...OdCCWddWCCdO.....",
				"...OddddddddddO.....",
				"...OdCCdddddCdO.....",
				"....OdddddddO.......",
				"...O.T.Odd.O.TO.....",
				"...T.T.Odd.O.T.T....",
				"....T..Otd..T......."
			])
		"glow_bat":
			return _art([
				"..OO............OO..",
				".OCCO..........OCCO.",
				"OCCCCCOOOOOOOOCCCCO.",
				"OCCCCCCCCCCCCCCCCCO.",
				".OCCCCOOKKOOCCCCCO..",
				"..OOOCCCCCCCOOOO....",
				"....OCCKWWKCCO......",
				".....OCCCCCCO.......",
				"......OOOOOO........",
				".......O..O........."
			])
		"wind_falcon":
			return _art([
				"..OO...........OO...",
				".OYYO.........OYYO..",
				".OYYYOOOOOOOOOYYO...",
				"..OYYYYYYYYYYYYYO...",
				"...OYYWWKKWWYYYO....",
				"....OYYYYYYYYYO.....",
				".....OYYAAAAYO......",
				"......OYAAAAYO......",
				".......OYAAO........",
				"........OO.........."
			])
		"rock_thrower":
			return _art([
				".......OOOOOO.......",
				"......OSSSSSSO......",
				".....OSSWWSSSSO.....",
				".....OSSSSSSSSO.....",
				"....OOsSSSSSSsOO....",
				"...OTTOSSSSSOTTO....",
				"...OTTOSSSSSOTTO....",
				"....O.sTTTTs.O......",
				"......OTSSSTO.......",
				".....OOTSSSTOO......",
				"......OOOOOO........"
			])
		"moss_guard":
			return _art([
				".....OOOOOOOOOO.....",
				"....OSSSSSSSSSSO....",
				"...OSSGGSSGGSSSSO...",
				"...OSWWSSWWSSSSSO...",
				"...OSSSSSSSSSSSSO...",
				"...OSSGSSGGSSSSSO...",
				"....OSSSSSSSSSSO....",
				"...OOOOSSSSOOOOO....",
				"..OSSSSSSSSSSSSSO...",
				"..OSsSSSSSSSSsSO....",
				"...OOOOOOOOOOOOO...."
			])
		"rune_weaver":
			return _art([
				".......AAAA.........",
				"......O.OPPPO.......",
				".....OPPPWWPPPO.....",
				".....OPPWKKWPPPO....",
				".....OPPPWWPPPO.....",
				"....OPPPPPPPPPPO....",
				"...OPPAAAAAAAPPPO...",
				"...OPPPPWWWWPPPP...",
				"...OPPPPWWWWPPPP...",
				"....OPPPPPPPPPPO....",
				"....OPP.PPPP.PPO....",
				".....OO..OO..OO....."
			])
		"star_wisp":
			return _art([
				".........OO.........",
				"....O...OLLO...O....",
				"....OO.OLLLLO.OO....",
				".....OLLLLLLLLO.....",
				"....OLLLWKKWLLLO....",
				".....OLLLLLLLLO.....",
				"....OO.OLLLLO.OO....",
				"....O...OLLO...O....",
				".........OO.........",
				"........O..O........"
			])
		"sky_knight":
			return _art([
				"........AAAA........",
				".......OBBBBO.......",
				"......OBWWWWBO......",
				"......OBWKKWBO......",
				".......OBBBBO.......",
				"....OOOBBBBBBOOO....",
				"...OBBLBBBBBBLBBO...",
				"...OBBBLLLLLBBBBO...",
				"...OBBOBLLLBOBBO....",
				"....OO.OBBBBO.OO....",
				".......OB.BO........",
				"......OO...OO......."
			])
	return _enemy_art("mushroom")

static func _boss_art(region_id: String) -> Dictionary:
	match region_id:
		"meadow":
			return _art([
				"........OOOOOOOO........",
				".......OAAAAAAAAO.......",
				"......OAAWWWWWWAAO......",
				".....OWWAAAAAAAAWOW.....",
				"....OWWAOOOOOOAAWWO.....",
				"....OWAOYYYYYYAOWO......",
				".....OAYAKKKKAYAO.......",
				".....OAYAKWWKAYAO.......",
				"....OAYYAKKKKAYYAO......",
				"....OAYYYYYYYYYYAO......",
				"...OAYAKKYYKKAYYAO......",
				"...OAYYYYYYYYYYAYO......",
				"...OAAYAKKYYKAAYAO......",
				"...OAAAYYYYYYYAAAO......",
				"....OAAOOOOOOOAAO.......",
				".....OOTT....TTOO.......",
				"....OTT........TTO......"
			])
		"forest":
			return _art([
				"........OOOOOOOO........",
				"......OORRRRRRRROO......",
				"....ORRRRWWWWRRRRRO.....",
				"...ORRWWRRRRRRWWRRRO....",
				"..ORRRRRRRRRRRRRRRRRO...",
				"..ORRRWWRRRRRRWWRRRO....",
				"...ORRRRRRKKRRRRRRO.....",
				"...ORRWKRRWWRRKWRRO.....",
				"....OORRRRRRRRRROO......",
				".....OOTTTTTTTTOO.......",
				"....OTtTWWTTWWtTTO......",
				"...OTTtTTTTTTTTtTTO.....",
				"...OTTTTGGGGTTTTTTO.....",
				"...OTTTGGGGGGTTTTTO.....",
				"...OTTTTTGGTTTTTTTO.....",
				"....OTTTTTTTTTTTO.......",
				".....OOTTT..TTOO........"
			])
		"grove":
			return _art([
				".....O..OOOOOO..O.......",
				"....OT.OCCCCCCO.TO......",
				"...OT.OCCWWWWCCO.TO.....",
				"..OT.OCCCWKKWCCCO.T.....",
				"...O.OCCCWWWWCCCO.O.....",
				"...O.OCCCCCCCCCCO.O.....",
				"....OOCCdCCCCdCCOO......",
				"....OCCdddddddCCCO......",
				"....OCdddddddddCCO......",
				"....OCdCCdddCCdCCO......",
				"....OCdCCCCCCCdCCO......",
				".....OCdCCCCCdCO........",
				"....O.TddCCddT.O........",
				"...OT.TddCCCCdT.TO......",
				"...T..OTdCCddTO..T......",
				"......OOTTTTTOO........."
			])
		"canyon":
			return _art([
				"..........OOOO..........",
				".....OO..OAAAAO..OO.....",
				"....OYYOOAAWWAAOOYYO....",
				"...OYYYYOAWKKWAOYYYYO...",
				"...OYYYOAAWWWWAAOYYO....",
				"....OYOAAAAAAAAAAOYO....",
				".....OOASSWWSSAAOO......",
				"......OSSSSSSSSSO.......",
				".....OSSWSSSSWSSSO......",
				"....OSSSSSSSSSSSSSO.....",
				"....OSSTTSSSSTTSSSO.....",
				"....OSSTTSSSSTTSSSO.....",
				".....OSSSSSSSSSSO.......",
				"....OOTTTSSSSTTTO.......",
				"...OYYOTTT..TTTOYYO.....",
				"..OYY..OO....OO..YYO...."
			])
		"ruins":
			return _art([
				".......OOOOOOOO.........",
				"......OSSSSSSSSO........",
				".....OSSWWSSWWSSO.......",
				".....OSSWKSSWKSSO.......",
				".....OSSSSSSSSSSO.......",
				"....OSSGGSSSSGGSSO......",
				"...OSSSGGGGGGGSSSSO.....",
				"...OSSSAAAAAAASSSSO.....",
				"...OSSSAAAAAAAASSSO.....",
				"....OSSSSAAAASSSSO......",
				"....OSSSSSSSSSSSSO......",
				"...OSSSSSSSSSSSSSSO.....",
				"..OSSS.SSSSSSS.SSSO.....",
				"..OSSS.SSSSSSS.SSSO.....",
				"..OssO.sSSSSSs.OssO.....",
				"..OOOO..OOOO..OOOOO....."
			])
		"gate":
			return _art([
				"........AAAAAAA.........",
				".......OBBBBBBBO........",
				"......OBBLLLLLBBO.......",
				".....OBLLWKKWLLBO.......",
				".....OBLWWWWWWLBO.......",
				"....OBBLLLLLLLLBBO......",
				"...OBBBLAAAAAALBBBO.....",
				"...OBBBAAAAAAAABBBO.....",
				"..OBBBBAALLLAABBBBBO....",
				"..OBBBBBAALLAABBBBBO....",
				"..OBBBBBBBBBBBBBBBBO....",
				"..OBBBBOOBBBBOOBBBBO....",
				"...OBB.OOBLBOO.BBO......",
				"...OBB.OOBLBOO.BBO......",
				"....OO...OOO...OO.......",
				"........OO.OO..........."
			])
	return _boss_art("meadow")

static func _equipment_art(id: String) -> Dictionary:
	match id:
		"grass_blade":
			return _art([
				"..........GG....",
				".........GggG...",
				"........GgggG...",
				".......GgggG....",
				"......GgggG.....",
				".....GgggG......",
				"....GgggG.......",
				"...OGggGO.......",
				"...OTTTTO.......",
				"....OTTO........",
				"....OTTO........"
			])
		"petal_blade":
			return _art([
				".........R......",
				"........ORrO....",
				".......ORrrrO...",
				"......ORrrrO....",
				".....ORrrrO.....",
				"....ORrrO.......",
				"...OWWrO........",
				"...OTTTTO.......",
				"....OTTO........",
				"....OTTO........"
			])
		"spore_edge":
			return _art([
				"........GG......",
				".......OGRRO....",
				"......OGRRrO....",
				".....OGRRrO.....",
				"....OGRRrO......",
				"...OGGRrO.......",
				"..OWWWRRO.......",
				"...OTTTTO.......",
				"....OTTO........",
				"....OTTO........"
			])
		"glow_hook":
			return _art([
				".....OOOO....",
				"....OCCCCO...",
				"...OCWCCCO...",
				"...OCCCCO....",
				"....OCCCO....",
				".....OCCCO...",
				"......OCCCO..",
				"......OTTO...",
				"......OTTO..."
			])
		"gale_rock":
			return _art([
				"....OOOOOOO..",
				"...OAAWWAAO..",
				"..OAATTAAAO..",
				"..OATTTAAAO..",
				"..OAAATTAAO..",
				"...OAAATTTO..",
				"....OTTTTO...",
				"....OTTTTO...",
				".....OTTO...."
			])
		"rune_blade":
			return _art([
				"........AA.....",
				".......OAAO....",
				"......OAWAO....",
				".....OAWAAO....",
				"....OAWAAO.....",
				"...OAWAAO......",
				"..OWWAAO.......",
				"...OTTAO.......",
				"....OTTO.......",
				"....OTTO......."
			])
		"star_edge":
			return _art([
				".........L.....",
				"........OLL....",
				".......OLLO....",
				"......OLLLLO...",
				".....OLWWLO....",
				"....OLLLLO.....",
				"...OLLLO.......",
				"..OWWLO........",
				"...OTTO........",
				"...OTTO........"
			])
		"none_armor":
			return _art([
				"....OOOOOO....",
				"...Os......O..",
				"...O........O.",
				"...O........O.",
				"...O........O.",
				"....OOOOOO...."
			])
		"moss_light":
			return _art([
				"...OOOOOOOO...",
				"..OGGO..OGGO..",
				".OGGGGOOGGGGO.",
				".OGWWGGGGWWGO.",
				".OGGGGddGGGGO.",
				".OdddGGGGdddO.",
				"..OOOOOOOOOO.."
			])
		"mushroom_shell":
			return _art([
				"...OOOOOOOO...",
				"..ORRO..ORRO..",
				".ORRRROORRRRO.",
				".ORWWRRRRWWR O",
				".ORRRRTTRRRRO.",
				".OrttRRRRttro.",
				"..OOOOOOOOOO.."
			])
		"root_weave":
			return _art([
				"...OOOOOOOO...",
				"..OCCO..OCCO..",
				".OCCCCOOCCCCO.",
				".OCWWCCCCWWCO.",
				".OCCddCCddCCO.",
				".OddCCCCdddo..",
				"..OOOOOOOOOO.."
			])
		"gale_plate":
			return _art([
				"...OOOOOOOO...",
				"..ORRO..ORRO..",
				".ORRRROORRRRO.",
				".ORWWRRRRWWR O",
				".ORRRAAAARRRO.",
				".OrttRRRRttro.",
				"..OOOOOOOOOO.."
			])
		"rune_armor":
			return _art([
				"...OOOOOOOO...",
				"..OSSO..OSSO..",
				".OSSSSOOSSSSO.",
				".OSWWSSSSWWS O",
				".OSSAAAAASSSO.",
				".OsssSSSSssso.",
				"..OOOOOOOOOO.."
			])
		"sky_armor":
			return _art([
				"...OOOOOOOO...",
				"..OBBO..OBBO..",
				".OBBBBOOBBBBO.",
				".OBWWBLLBWWBO.",
				".OBLLLWWLLLBO.",
				".ObbbLLLbbbbO.",
				"..OOOOOOOOOO.."
			])
	return _equipment_art("grass_blade")
