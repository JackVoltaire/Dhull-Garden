class_name DhullNeedRates
extends Resource
## How fast a Dhull's needs change at one life stage, in real-world hours. The young get hungry
## and tired much faster than adults, so they nap a lot more.

## How much hungrier it gets per hour, from 0 (full) towards 1 (starving).
@export_range(0.0, 1.0, 0.01) var hunger_per_hour := 0.08
## How much more tired it gets per hour awake, towards 1 (exhausted).
@export_range(0.0, 2.0, 0.01) var tiring_per_hour := 0.2
## How much tiredness a nap takes away per hour.
@export_range(0.0, 4.0, 0.01) var resting_per_hour := 0.8
