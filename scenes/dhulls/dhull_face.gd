class_name DhullFace
extends RefCounted
## Which eye and mouth images make a Dhull's face. Like Wind Waker's faces, the eyes and the mouth
## are separate images, swapped on their own. Each Dhull has an eye style for its everyday eyes;
## most emotions swap in eyes of their own. The mouth only shows when it's open. The frames in
## face/dhull_eyes.png and face/dhull_mouths.png follow the order of [enum Eyes] and [enum Mouth].

enum Emotion { NEUTRAL, HAPPY, SAD, ANGRY, DIZZY, SURPRISED, SLEEPY, TIRED, HUNGRY }
enum EyeStyle { ROUND, DROOPY, INTENSE, DUMB }
enum Eyes { ROUND, DROOPY, INTENSE, DUMB, HAPPY, SAD, ANGRY, SPIRAL, CLOSED, WIDE }
enum Mouth { OPEN, GRIN }

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
	Emotion.TIRED: Eyes.DROOPY,
}
## Emotions that open the mouth. In the others it stays shut, which doesn't show.
const OPEN_MOUTHS: Dictionary[Emotion, Mouth] = {
	Emotion.HAPPY: Mouth.OPEN,
	Emotion.ANGRY: Mouth.GRIN,
	Emotion.SURPRISED: Mouth.OPEN,
	Emotion.HUNGRY: Mouth.OPEN,
}
## What [method mouth_for] returns for a shut mouth.
const NO_MOUTH := -1


## The eyes to show. A blink shuts them, except happy eyes, which are drawn as closed arcs already.
static func eyes_for(emotion: Emotion, style: EyeStyle, blinking: bool) -> Eyes:
	var eyes: Eyes = EMOTION_EYES.get(emotion, EVERYDAY_EYES[style])
	if blinking and eyes != Eyes.HAPPY:
		return Eyes.CLOSED
	return eyes


## The open mouth to show, a [enum Mouth], or [constant NO_MOUTH] when it's shut.
static func mouth_for(emotion: Emotion) -> int:
	return OPEN_MOUTHS.get(emotion, NO_MOUTH)
