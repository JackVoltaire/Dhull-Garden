class_name DhullFace
extends RefCounted
## Which eye and mouth images make the face for each emotion a Dhull shows. Like Wind Waker's
## faces, the eyes and the mouth are separate images, swapped on their own. The frames in
## face/dhull_eyes.svg and face/dhull_mouths.svg follow the order of [enum Eyes] and [enum Mouth].

enum Emotion { NEUTRAL, HAPPY, SAD, ANGRY, DIZZY, SURPRISED, SLEEPY }
enum Eyes { OPEN, HAPPY, SAD, ANGRY, SPIRAL, CLOSED, WIDE }
enum Mouth { SMILE, GRIN, OPEN, FROWN, WAVY, FLAT }

const EYES_FOR: Dictionary[Emotion, Eyes] = {
	Emotion.NEUTRAL: Eyes.OPEN,
	Emotion.HAPPY: Eyes.HAPPY,
	Emotion.SAD: Eyes.SAD,
	Emotion.ANGRY: Eyes.ANGRY,
	Emotion.DIZZY: Eyes.SPIRAL,
	Emotion.SURPRISED: Eyes.WIDE,
	Emotion.SLEEPY: Eyes.CLOSED,
}
const MOUTH_FOR: Dictionary[Emotion, Mouth] = {
	Emotion.NEUTRAL: Mouth.SMILE,
	Emotion.HAPPY: Mouth.OPEN,
	Emotion.SAD: Mouth.FROWN,
	Emotion.ANGRY: Mouth.GRIN,
	Emotion.DIZZY: Mouth.WAVY,
	Emotion.SURPRISED: Mouth.OPEN,
	Emotion.SLEEPY: Mouth.FLAT,
}


## The eyes to show. A blink shuts them, except happy eyes, which are drawn as closed arcs already.
static func eyes_for(emotion: Emotion, blinking: bool) -> Eyes:
	var eyes := EYES_FOR[emotion]
	if blinking and eyes != Eyes.HAPPY:
		return Eyes.CLOSED
	return eyes


static func mouth_for(emotion: Emotion) -> Mouth:
	return MOUTH_FOR[emotion]
