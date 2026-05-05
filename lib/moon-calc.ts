import { MOON_FRAME_START, MOON_FRAME_END, MOON_FRAME_BASE_URL } from './constants';
import type { MoonPosition } from './api';

const TOTAL_FRAMES = MOON_FRAME_END - MOON_FRAME_START + 1; // 712

// Moon ~0.5507°/hr ecliptic longitude, Sun ~0.0411°/hr
const MOON_DEG_PER_HOUR = 0.5507;
const SUN_DEG_PER_HOUR = 0.0411;

const ZODIAC_SIGNS = [
  { name: 'Aries', symbol: '\u2648' },
  { name: 'Taurus', symbol: '\u2649' },
  { name: 'Gemini', symbol: '\u264A' },
  { name: 'Cancer', symbol: '\u264B' },
  { name: 'Leo', symbol: '\u264C' },
  { name: 'Virgo', symbol: '\u264D' },
  { name: 'Libra', symbol: '\u264E' },
  { name: 'Scorpio', symbol: '\u264F' },
  { name: 'Sagittarius', symbol: '\u2650' },
  { name: 'Capricorn', symbol: '\u2651' },
  { name: 'Aquarius', symbol: '\u2652' },
  { name: 'Pisces', symbol: '\u2653' },
] as const;

/** CDN URL for a given frame index (649-1360) */
export function getMoonFrameUri(frameIndex: number): string {
  return `${MOON_FRAME_BASE_URL}/moon.${String(frameIndex).padStart(4, '0')}.webp`;
}

/** Map phase angle (0-360) to frame index (649-1360) */
export function getFrameFromAngle(phaseAngle: number): number {
  const normalized = ((phaseAngle % 360) + 360) % 360;
  return MOON_FRAME_START + Math.round((normalized / 360) * (TOTAL_FRAMES - 1));
}

/** Phase name from elongation angle */
export function getPhaseName(angle: number): string {
  const a = ((angle % 360) + 360) % 360;
  if (a < 1 || a > 359) return 'New Moon';
  if (a < 89) return 'Waxing Crescent';
  if (a <= 91) return 'First Quarter';
  if (a < 179) return 'Waxing Gibbous';
  if (a <= 181) return 'Full Moon';
  if (a < 269) return 'Waning Gibbous';
  if (a <= 271) return 'Last Quarter';
  return 'Waning Crescent';
}

/** Zodiac sign from ecliptic longitude (0-360) */
export function getZodiacFromLongitude(longitude: number) {
  const normalized = ((longitude % 360) + 360) % 360;
  const signIndex = Math.floor(normalized / 30);
  const withinSign = normalized - signIndex * 30;
  const degrees = Math.floor(withinSign);
  const minutesRaw = (withinSign - degrees) * 60;
  const minutes = Math.floor(minutesRaw);
  const seconds = Math.round((minutesRaw - minutes) * 60);

  return {
    ...ZODIAC_SIGNS[signIndex],
    degrees,
    minutes,
    seconds,
  };
}

/** Illumination % from phase angle */
export function getIllumination(phaseAngle: number): number {
  const rad = ((phaseAngle % 360) * Math.PI) / 180;
  return ((1 - Math.cos(rad)) / 2) * 100;
}

export type InterpolatedPosition = {
  moonLongitude: number;
  sunLongitude: number;
  phaseAngle: number;
  phaseName: string;
  illuminationPercent: number;
  zodiac: ReturnType<typeof getZodiacFromLongitude>;
  frameIndex: number;
  frameUri: string;
};

/**
 * Interpolate moon position from a known anchor point.
 * Accurate to ~1° over +-36 hours (good enough for scrubber UX).
 */
export function interpolatePosition(
  anchor: MoonPosition,
  offsetHours: number,
): InterpolatedPosition {
  const moonLong = anchor.moonLongitude + offsetHours * MOON_DEG_PER_HOUR;
  const sunLong = anchor.sunLongitude + offsetHours * SUN_DEG_PER_HOUR;
  const phaseAngle = ((moonLong - sunLong) % 360 + 360) % 360;
  const frameIndex = getFrameFromAngle(phaseAngle);

  return {
    moonLongitude: moonLong,
    sunLongitude: sunLong,
    phaseAngle,
    phaseName: getPhaseName(phaseAngle),
    illuminationPercent: getIllumination(phaseAngle),
    zodiac: getZodiacFromLongitude(moonLong),
    frameIndex,
    frameUri: getMoonFrameUri(frameIndex),
  };
}

/** Format degree display: "20° 45'" */
export function formatDegrees(degrees: number, minutes: number): string {
  return `${degrees}\u00B0 ${String(minutes).padStart(2, '0')}\u2032`;
}

/** Format time offset as relative label: "-12h", "Now", "+12h" */
export function formatOffsetLabel(hours: number): string {
  if (Math.abs(hours) < 0.5) return 'Now';
  const sign = hours > 0 ? '+' : '';
  const h = Math.round(hours);
  return `${sign}${h}h`;
}
