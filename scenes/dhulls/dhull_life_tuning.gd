class_name DhullLifeTuning
extends Resource
## The numbers behind how Dhulls live: how fast their needs change, how adults look after the
## young, and at what levels each mood shows. Needs run from 0 to 1; see DhullRecord. The tuning
## the game uses is data/dhulls/life.tres.

@export_group("Needs")
@export var adult_rates: DhullNeedRates
@export var young_rates: DhullNeedRates
## A Dhull falls asleep for a nap once it's this tired, like a cat dozing off.
@export_range(0.0, 1.0, 0.01) var nap_at := 0.7
## And wakes up again once it's rested down to this.
@export_range(0.0, 1.0, 0.01) var wake_at := 0.1
## Adults forage for themselves, so they get peckish but never hungrier than this.
@export_range(0.0, 1.0, 0.01) var forage_hunger := 0.75
## Hunger past which a Dhull grows unhappy, as a young Dhull without an adult does.
@export_range(0.0, 1.0, 0.01) var starving_at := 0.9
## How much happiness a starving Dhull loses per hour.
@export_range(0.0, 1.0, 0.01) var starving_sadness_per_hour := 0.1
## How much happiness a young Dhull with no adult around loses per hour.
@export_range(0.0, 1.0, 0.01) var lonely_sadness_per_hour := 0.06
## Happiness drifts back towards this when nothing is wrong.
@export_range(0.0, 1.0, 0.01) var resting_happiness := 0.5
## How fast happiness drifts back, per hour.
@export_range(0.0, 1.0, 0.01) var settling_per_hour := 0.05

@export_group("Adults caring for the young")
## The young are fed at least this well by the least nurturing adult: the bare minimum.
@export_range(0.0, 1.0, 0.01) var bare_minimum_hunger := 0.8
## And this well by the most nurturing one.
@export_range(0.0, 1.0, 0.01) var nurtured_hunger := 0.35
## The most nurturing adults also keep the young at least this happy. Less nurturing ones keep
## them less happy, down to not at all.
@export_range(0.0, 1.0, 0.01) var nurtured_happiness := 0.6

@export_group("Moods")
## Happiness at or below which a Dhull is sad, or grumpy if it's bold.
@export_range(0.0, 1.0, 0.01) var unhappy_at := 0.3
## Hunger from which a Dhull looks hungry.
@export_range(0.0, 1.0, 0.01) var hungry_at := 0.7
## Tiredness from which a Dhull looks sleepy, a while before it naps.
@export_range(0.0, 1.0, 0.01) var sleepy_at := 0.55
## Happiness from which a Dhull is happy.
@export_range(0.0, 1.0, 0.01) var happy_at := 0.7
## A happy Dhull this rested or better is playful.
@export_range(0.0, 1.0, 0.01) var playful_below_tiredness := 0.3
## Boldness, from 0 to 1, from which an unhappy Dhull turns grumpy instead of sad.
@export_range(0.0, 1.0, 0.01) var grumpy_from_boldness := 0.5

@export_group("Care from the player")
## How much happier petting makes a Dhull that welcomes it, and how much closer it grows to you.
@export_range(0.0, 1.0, 0.01) var pet_cheers := 0.08
@export_range(0.0, 1.0, 0.01) var pet_bond := 0.03
## How much happiness a Dhull loses when it's petted and didn't want to be.
@export_range(0.0, 1.0, 0.01) var annoyed_sadness := 0.05
## Pets in a short while that a Dhull puts up with before it's had enough.
@export_range(1.0, 20.0, 0.5) var fussing_limit := 3.0
## How fast being fussed over wears off, in pets per hour.
@export_range(0.0, 20.0, 0.1) var fussing_fades_per_hour := 1.0
## Bond from which a sad Dhull takes comfort in being petted by you.
@export_range(0.0, 1.0, 0.01) var trusted_from_bond := 0.5
## Hunger below which a Dhull is too full to eat.
@export_range(0.0, 1.0, 0.01) var full_below := 0.1
