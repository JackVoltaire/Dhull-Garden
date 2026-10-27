extends TestCase

const VARIANT_COUNTS := {
	DhullGenome.Gene.HEAD_SHAPE: DhullGenome.HeadShape,
	DhullGenome.Gene.BODY_SHAPE: DhullGenome.BodyShape,
	DhullGenome.Gene.EYE_STYLE: DhullFace.EyeStyle,
	DhullGenome.Gene.EYE_COLOR: DhullGenome.EyeColor,
}

var _rng: RandomNumberGenerator


func before_each() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42


func test_every_gene_with_variants_has_a_dominance_and_commonness_per_variant() -> void:
	for gene: DhullGenome.Gene in VARIANT_COUNTS:
		var count: int = VARIANT_COUNTS[gene].size()
		assert_eq(
			DhullGenome.DOMINANCE[gene].size(),
			count,
			"dominance of %s" % DhullGenome.Gene.keys()[gene]
		)
		assert_eq(
			DhullGenome.COMMONNESS[gene].size(),
			count,
			"commonness of %s" % DhullGenome.Gene.keys()[gene]
		)


func test_dominant_variant_shows() -> void:
	var moon := DhullGenome.HeadShape.MOON
	var genome := _genome(
		{DhullGenome.Gene.HEAD_SHAPE: Vector2i(DhullGenome.HeadShape.MOONCAT, moon)}
	)
	# MOON dominates MOONCAT, whichever parent it came from.
	assert_eq(genome.head_shape(), DhullGenome.HeadShape.MOON)
	genome.alleles[DhullGenome.Gene.HEAD_SHAPE] = Vector2i(moon, DhullGenome.HeadShape.MOONCAT)
	assert_eq(genome.head_shape(), DhullGenome.HeadShape.MOON)


func test_recessive_variant_shows_when_carried_twice() -> void:
	var mooncat := DhullGenome.HeadShape.MOONCAT
	var genome := _genome({DhullGenome.Gene.HEAD_SHAPE: Vector2i(mooncat, mooncat)})
	assert_eq(genome.head_shape(), mooncat)


func test_personality_is_the_average_of_both_alleles() -> void:
	var genome := _genome({DhullGenome.Gene.ENERGY: Vector2i(20, 60)})
	assert_eq(genome.level(DhullGenome.Gene.ENERGY), 0.4)


func test_random_genomes_have_every_gene_in_range() -> void:
	for i in 50:
		var genome := DhullGenome.random(_rng)
		for gene: DhullGenome.Gene in DhullGenome.Gene.values():
			assert_true(genome.alleles.has(gene), "has %s" % DhullGenome.Gene.keys()[gene])
			for allele in [genome.alleles[gene].x, genome.alleles[gene].y]:
				var highest: int = (
					DhullGenome.MAX_LEVEL
					if DhullGenome.is_level(gene)
					else VARIANT_COUNTS[gene].size() - 1
				)
				assert_true(
					allele >= 0 and allele <= highest, "%s in range" % DhullGenome.Gene.keys()[gene]
				)


func test_children_get_one_allele_from_each_parent() -> void:
	var mother := _genome(
		{DhullGenome.Gene.HEAD_SHAPE: Vector2i(0, 0), DhullGenome.Gene.ENERGY: Vector2i(10, 20)}
	)
	var father := _genome(
		{DhullGenome.Gene.HEAD_SHAPE: Vector2i(2, 2), DhullGenome.Gene.ENERGY: Vector2i(80, 90)}
	)
	for i in 20:
		var child := DhullGenome.bred(mother, father, _rng, 0.0, 0.0)
		assert_eq(child.alleles[DhullGenome.Gene.HEAD_SHAPE], Vector2i(0, 2))
		assert_true(child.alleles[DhullGenome.Gene.ENERGY].x in [10, 20], "energy from the mother")
		assert_true(child.alleles[DhullGenome.Gene.ENERGY].y in [80, 90], "energy from the father")


func test_a_recessive_variant_can_skip_a_generation() -> void:
	# Two moon-headed parents that both carry mooncat have some mooncat-headed children.
	var mooncat := DhullGenome.HeadShape.MOONCAT
	var carrier := _genome(
		{DhullGenome.Gene.HEAD_SHAPE: Vector2i(DhullGenome.HeadShape.MOON, mooncat)}
	)
	assert_eq(carrier.head_shape(), DhullGenome.HeadShape.MOON)
	var mooncat_children := 0
	for i in 200:
		if DhullGenome.bred(carrier, carrier, _rng, 0.0, 0.0).head_shape() == mooncat:
			mooncat_children += 1
	assert_true(mooncat_children > 20 and mooncat_children < 80, "about a quarter")


func test_mutations_stay_in_range() -> void:
	var parent := _genome({DhullGenome.Gene.ENERGY: Vector2i(100, 100)})
	for i in 50:
		var child := DhullGenome.bred(parent, parent, _rng, 1.0)
		for gene: DhullGenome.Gene in DhullGenome.Gene.values():
			var pair: Vector2i = child.alleles[gene]
			assert_true(DhullGenome.is_valid_allele(gene, pair.x), DhullGenome.Gene.keys()[gene])
			assert_true(DhullGenome.is_valid_allele(gene, pair.y), DhullGenome.Gene.keys()[gene])


func test_saved_genes_load_back_the_same() -> void:
	var genome := DhullGenome.random(_rng)
	var loaded := DhullGenome.from_dict(genome.to_dict(), _rng)
	assert_eq(loaded.alleles, genome.alleles)


func test_loading_fills_in_missing_and_broken_genes() -> void:
	var data := {"HEAD_SHAPE": [2, 2], "ENERGY": [50, 999], "NOT_A_GENE": [1, 1]}
	var loaded := DhullGenome.from_dict(data, _rng)
	assert_eq(loaded.alleles[DhullGenome.Gene.HEAD_SHAPE], Vector2i(2, 2))
	assert_eq(loaded.alleles.size(), DhullGenome.Gene.size())
	assert_true(
		DhullGenome.is_valid_allele(
			DhullGenome.Gene.ENERGY, loaded.alleles[DhullGenome.Gene.ENERGY].y
		)
	)


func test_every_shape_has_a_model() -> void:
	for shape: DhullGenome.HeadShape in DhullGenome.HeadShape.values():
		assert_true(Dhull.HEAD_MODELS.has(shape), "head %s" % DhullGenome.HeadShape.keys()[shape])
	for shape: DhullGenome.BodyShape in DhullGenome.BodyShape.values():
		assert_true(Dhull.BODY_MODELS.has(shape), "body %s" % DhullGenome.BodyShape.keys()[shape])


## A random genome with some genes set.
func _genome(genes: Dictionary) -> DhullGenome:
	var genome := DhullGenome.random(_rng)
	for gene: DhullGenome.Gene in genes:
		genome.alleles[gene] = genes[gene]
	return genome
