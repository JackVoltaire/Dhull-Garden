class_name FeedTuning
extends Resource
## The numbers behind the feed: how often Dhulls post, how many posts are kept, and how much a
## reaction moves a Dhull. The game's tuning is data/feed/feed.tres.

## The fewest real minutes between two posts by the same Dhull, so nobody floods the feed.
@export_range(0, 600) var minutes_between_posts := 45
## The oldest posts go once there are more than this many.
@export_range(10, 1000) var most_posts_kept := 150
## The local hours of the late-night and morning posts.
@export_range(0, 23) var late_night_hour := 3
@export_range(0, 23) var morning_hour := 8

@export_group("What Dhulls want from reactions")
## Boldness, from 0 to 1, from which a Dhull wants to get a rise out of people.
@export_range(0.0, 1.0, 0.01) var wants_a_rise_from_boldness := 0.65
## Friendliness, from 0 to 1, from which a Dhull wants sympathy, unless it wants a rise.
@export_range(0.0, 1.0, 0.01) var wants_sympathy_from_friendliness := 0.55

@export_group("How reactions land")
## How much happier and closer to you a reaction the Dhull loves makes it.
@export_range(0.0, 1.0, 0.01) var loved_cheers := 0.08
@export_range(0.0, 1.0, 0.01) var loved_bond := 0.04
## A reaction that's fine but not what it wanted still counts for a little.
@export_range(0.0, 1.0, 0.01) var meh_bond := 0.01
## How much a reaction that stings hurts.
@export_range(0.0, 1.0, 0.01) var stung_sadness := 0.06
@export_range(0.0, 1.0, 0.01) var stung_bond := 0.03
