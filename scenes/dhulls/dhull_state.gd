class_name DhullState
extends RefCounted
## What a Dhull is doing and how it feels, and the animation and face that show it. Animations are
## never picked at random: every activity and mood has its own, so a glance tells how a Dhull is.
## The animations are in dhull_animations.tres.

enum Activity { STANDING, WALKING, SITTING, SLEEPING }
enum Mood { CONTENT, HAPPY, PLAYFUL, SLEEPY, HUNGRY, SAD, GRUMPY }

## The animation for each activity, by mood. A sleeping Dhull only shows whether it sleeps soundly.
const ANIMATIONS: Dictionary[Activity, Dictionary] = {
	Activity.STANDING:
	{
		Mood.CONTENT: &"idle_content",
		Mood.HAPPY: &"idle_happy",
		Mood.PLAYFUL: &"idle_playful",
		Mood.SLEEPY: &"idle_sleepy",
		Mood.HUNGRY: &"idle_hungry",
		Mood.SAD: &"idle_sad",
		Mood.GRUMPY: &"idle_grumpy",
	},
	Activity.WALKING:
	{
		Mood.CONTENT: &"walk_content",
		Mood.HAPPY: &"walk_happy",
		Mood.PLAYFUL: &"walk_playful",
		Mood.SLEEPY: &"walk_sleepy",
		Mood.HUNGRY: &"walk_hungry",
		Mood.SAD: &"walk_sad",
		Mood.GRUMPY: &"walk_grumpy",
	},
	Activity.SITTING:
	{
		Mood.CONTENT: &"sit_content",
		Mood.HAPPY: &"sit_happy",
		Mood.PLAYFUL: &"sit_playful",
		Mood.SLEEPY: &"sit_sleepy",
		Mood.HUNGRY: &"sit_hungry",
		Mood.SAD: &"sit_sad",
		Mood.GRUMPY: &"sit_grumpy",
	},
	Activity.SLEEPING:
	{
		Mood.CONTENT: &"sleep",
		Mood.HAPPY: &"sleep",
		Mood.PLAYFUL: &"sleep",
		Mood.SLEEPY: &"sleep",
		Mood.HUNGRY: &"sleep_restless",
		Mood.SAD: &"sleep_restless",
		Mood.GRUMPY: &"sleep_restless",
	},
}
## The face each mood shows while awake. Asleep, the eyes are always closed.
const FACES: Dictionary[Mood, DhullFace.Emotion] = {
	Mood.CONTENT: DhullFace.Emotion.NEUTRAL,
	Mood.HAPPY: DhullFace.Emotion.HAPPY,
	Mood.PLAYFUL: DhullFace.Emotion.HAPPY,
	Mood.SLEEPY: DhullFace.Emotion.TIRED,
	Mood.HUNGRY: DhullFace.Emotion.HUNGRY,
	Mood.SAD: DhullFace.Emotion.SAD,
	Mood.GRUMPY: DhullFace.Emotion.ANGRY,
}
## How fast a Dhull moves at the lowest and the highest energy, as a playback speed.
const SPEED_RANGE := Vector2(0.8, 1.2)


static func animation_for(activity: Activity, mood: Mood) -> StringName:
	return ANIMATIONS[activity][mood]


static func emotion_for(activity: Activity, mood: Mood) -> DhullFace.Emotion:
	if activity == Activity.SLEEPING:
		return DhullFace.Emotion.SLEEPY
	return FACES[mood]


## How fast a Dhull's animations play: energetic Dhulls move faster, so the same mood looks a bit
## different on each Dhull.
static func speed_scale(genome: DhullGenome) -> float:
	return lerpf(SPEED_RANGE.x, SPEED_RANGE.y, genome.level(DhullGenome.Gene.ENERGY))
