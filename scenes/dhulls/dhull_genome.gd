class_name DhullGenome
extends Resource
## A Dhull's genes. They're hidden: the game never shows them, but they decide how a Dhull looks
## and what it's like, and Dhulls pass them on when they breed.
##
## Every gene is a pair of alleles, one from each parent. Genes with set variants (head shape,
## body shape, eye style, eye color) show the more dominant of the two, so a recessive variant can
## skip a generation. Personality genes are levels from 0 to 100 and show the average of the two.

enum Gene {HEAD_SHAPE, BODY_SHAPE, EYE_STYLE, ENERGY, BOLDNESS, CURIOSITY, FRIENDLINESS, EYE_COLOR}
enum HeadShape { MOON, MOONCAT, BEAN }
enum BodyShape { BELL, BEAN }
## Numbered as the rows of scenes/dhulls/face/dhull_eyes.png.
enum EyeColor { TEAL, VIOLET, AMBER, ROSE, MINT, SILVER }

## For each gene with set variants, how dominant each variant is, in variant order: when a Dhull
## carries two different variants, the higher number shows. Other genes are personality levels.
const DOMINANCE: Dictionary[Gene, Array] = {
	Gene.HEAD_SHAPE: [2, 0, 1],
	Gene.BODY_SHAPE: [1, 0],
	Gene.EYE_STYLE: [3, 1, 2, 0],
	Gene.EYE_COLOR: [5, 3, 4, 1, 2, 0],
}
## How common each variant is in Dhulls made from scratch, in variant order. Need not add to 1.
const COMMONNESS: Dictionary[Gene, Array] = {
	Gene.HEAD_SHAPE: [0.5, 0.15, 0.35],
	Gene.BODY_SHAPE: [0.6, 0.4],
	Gene.EYE_STYLE: [0.4, 0.25, 0.25, 0.1],
	Gene.EYE_COLOR: [0.3, 0.2, 0.2, 0.12, 0.12, 0.06],
}
const MAX_LEVEL := 100
## Spread of personality levels in Dhulls made from scratch, around the middle.
const LEVEL_SPREAD := 18.0
## Chance that an allele mutates when passed on: a variant turns into a random one, a level
## jumps by a lot.
const MUTATION_CHANCE := 0.03
const MUTATION_JUMP := 25.0
## Every personality level passed on also drifts a little, so families slowly change.
const LEVEL_DRIFT := 3.0

## The pair of alleles for each gene: x from one parent, y from the other.
@export var alleles: Dictionary[Gene, Vector2i] = {}


## A Dhull's genes made from scratch, as for a wild or newly hatched Dhull.
static func random(rng: RandomNumberGenerator) -> DhullGenome:
	var genome := DhullGenome.new()
	for gene: Gene in Gene.values():
		genome.alleles[gene] = Vector2i(_random_allele(gene, rng), _random_allele(gene, rng))
	return genome


## A child's genes: one allele of each gene from each parent, at random, some of them mutated.
static func bred(
	parent_a: DhullGenome,
	parent_b: DhullGenome,
	rng: RandomNumberGenerator,
	mutation_chance := MUTATION_CHANCE,
	level_drift := LEVEL_DRIFT
) -> DhullGenome:
	var child := DhullGenome.new()
	for gene: Gene in Gene.values():
		child.alleles[gene] = Vector2i(
			_passed_on(gene, parent_a.alleles[gene], rng, mutation_chance, level_drift),
			_passed_on(gene, parent_b.alleles[gene], rng, mutation_chance, level_drift)
		)
	return child


## Genes as saved: each gene's pair of alleles under its name, so saves survive genes being added
## or reordered.
func to_dict() -> Dictionary:
	var data := {}
	for gene: Gene in alleles:
		data[Gene.keys()[gene]] = [alleles[gene].x, alleles[gene].y]
	return data


## Genes from [method to_dict]. Genes missing or broken in the data are made from scratch, so
## Dhulls saved before a gene existed get one.
static func from_dict(data: Dictionary, rng: RandomNumberGenerator) -> DhullGenome:
	var genome := DhullGenome.random(rng)
	for gene: Gene in Gene.values():
		var pair: Variant = data.get(Gene.keys()[gene])
		if pair is Array and pair.size() == 2 and is_valid_allele(gene, pair[0]):
			if is_valid_allele(gene, pair[1]):
				genome.alleles[gene] = Vector2i(pair[0], pair[1])
	return genome


static func is_level(gene: Gene) -> bool:
	return not DOMINANCE.has(gene)


## Whether an allele can belong to a gene: one of its variants, or a level from 0 to
## [constant MAX_LEVEL].
static func is_valid_allele(gene: Gene, allele: Variant) -> bool:
	if not (allele is int or allele is float) or allele != roundi(allele):
		return false
	var highest := MAX_LEVEL if is_level(gene) else DOMINANCE[gene].size() - 1
	return allele >= 0 and allele <= highest


## The variant a gene with set variants shows: the more dominant of its two alleles.
func expressed_variant(gene: Gene) -> int:
	var pair := alleles[gene]
	var dominance: Array = DOMINANCE[gene]
	return pair.x if dominance[pair.x] >= dominance[pair.y] else pair.y


## How strong a personality gene is, from 0 to 1: the average of its two alleles.
func level(gene: Gene) -> float:
	var pair := alleles[gene]
	return (pair.x + pair.y) / (2.0 * MAX_LEVEL)


func head_shape() -> HeadShape:
	return expressed_variant(Gene.HEAD_SHAPE) as HeadShape


func body_shape() -> BodyShape:
	return expressed_variant(Gene.BODY_SHAPE) as BodyShape


func eye_style() -> DhullFace.EyeStyle:
	return expressed_variant(Gene.EYE_STYLE) as DhullFace.EyeStyle


func eye_color() -> EyeColor:
	return expressed_variant(Gene.EYE_COLOR) as EyeColor


static func _random_allele(gene: Gene, rng: RandomNumberGenerator) -> int:
	if is_level(gene):
		return clampi(roundi(rng.randfn(MAX_LEVEL / 2.0, LEVEL_SPREAD)), 0, MAX_LEVEL)
	return rng.rand_weighted(PackedFloat32Array(COMMONNESS[gene]))


static func _passed_on(
	gene: Gene,
	pair: Vector2i,
	rng: RandomNumberGenerator,
	mutation_chance: float,
	level_drift: float
) -> int:
	var allele := pair.x if rng.randf() < 0.5 else pair.y
	var mutates := rng.randf() < mutation_chance
	if not is_level(gene):
		return _random_allele(gene, rng) if mutates else allele
	var change := rng.randfn(0.0, level_drift) if level_drift > 0.0 else 0.0
	if mutates:
		change += rng.randfn(0.0, MUTATION_JUMP)
	return clampi(roundi(allele + change), 0, MAX_LEVEL)
