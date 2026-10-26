class_name DhullFace
extends RefCounted
## Which eye and mouth images make a Dhull's face. Like Wind Waker's faces, the eyes and the mouth
## are separate images, swapped on their own. Each Dhull has an eye style for its everyday eyes;
## most emotions swap in eyes of their own. The frames in face/dhull_eyes.svg and
## face/dhull_mouths.svg follow the order of [enum Eyes] and [enum Mouth].

enum Emotion { NEUTRAL, HAPPY, SAD, ANGRY, DIZZY, SURPRISED, SLEEPY }
enum EyeStyle { ROUND, DROOPY, INTENSE, DUMB }
enum Eyes { ROUND, DROOPY, INTENSE, DUMB, HAPPY, SAD, ANGRY, SPIRAL, CLOSED, WIDE }
enum Mouth { SMILE, GRIN, OPEN, FROWN, WAVY, FLAT }

const EVERYDAY_EYES: Dictionary[EyeStyle, Eyes] = {
	EyeStyle.ROUND: Eyes.ROUND,
	EyeStyle.DROOPY: Eyes.DROOPY,
	EyeStyle.INTENSE: Eyes.INTENSE,
	EyeStyle.DUMB: Eyes.DUMB,
}
## Eyes that show an emotion whatever the eye style. Emotions left out show the everyday eyes.
const EMOTION_EYES: Dictionary[Emotion, Eyes] = {
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
static func eyes_for(emotion: Emotion, style: EyeStyle, blinking: bool) -> Eyes:
	var eyes: Eyes = EMOTION_EYES.get(emotion, EVERYDAY_EYES[style])
	if blinking and eyes != Eyes.HAPPY:
		return Eyes.CLOSED
	return eyes


static func mouth_for(emotion: Emotion) -> Mouth:
	return MOUTH_FOR[emotion]
