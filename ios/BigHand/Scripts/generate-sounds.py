#!/usr/bin/env python3
"""Original arcade Foley: tuned rubber pops, wood cracks and short metal crunches."""
from pathlib import Path
import math, random, struct, wave
sounds = Path(__file__).resolve().parent.parent / 'Resources/Sounds'
cues = {
    'crush': (510, 150, .10, .08), 'mediumCrush': (195, 66, .16, .22),
    'largeCrush': (100, 36, .23, .35), 'metalCrush': (78, 25, .30, .48),
    'gate': (430, 860, .22, 0), 'shrink': (320, 105, .18, .04),
    'coin': (1250, 1600, .09, 0), 'fail': (155, 32, .32, .15),
    'upgrade': (490, 980, .26, 0), 'highScore': (520, 1040, .46, 0)
}
for name, (start, end, duration, grit) in cues.items():
    rng = random.Random(name)
    rate = 22050
    count = int(rate * duration)
    phase = 0
    samples = []
    for i in range(count):
        t = i / rate
        p = i / count
        phase += 2 * math.pi * (end + (start - end) * math.exp(-p * 7)) / rate
        envelope = min(1, t / .003) * (1 - p) ** 2
        body = math.sin(phase) * .58 + math.sin(phase * 2.03) * .10
        crack = rng.uniform(-1, 1) * grit * math.exp(-p * 12)
        if name == 'metalCrush':
            body += math.sin(phase * 3.73) * .10 * math.exp(-p * 4)
        if name in ('gate', 'upgrade', 'highScore'):
            note = [1, 1.25, 1.5, 2][min(3, int(p * 4))]
            body = math.sin(2 * math.pi * start * note * t) * .5 + math.sin(2 * math.pi * start * note * 2 * t) * .08
        samples.append(struct.pack('<h', int(max(-1, min(1, (body + crack) * envelope)) * 25000)))
    with wave.open(str(sounds / (name + '.wav')), 'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(rate)
        out.writeframes(b''.join(samples))
print('Generated 10 original cues (including four crush weights).')
