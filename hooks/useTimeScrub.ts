import { useCallback, useEffect, useRef, useState } from "react";
import { fetchMoonTimeline, type MoonTimelinePoint } from "../lib/api";

const TIMELINE_FRESHNESS_MS = 15 * 60_000;

function normalize360(v: number) {
  return ((v % 360) + 360) % 360;
}

function lerpAngle(a: number, b: number, t: number) {
  let delta = normalize360(b - a);
  if (delta > 180) delta -= 360;
  return normalize360(a + delta * t);
}

function lerp<T extends number | null | undefined>(
  a: T,
  b: T,
  t: number,
): T | number {
  if (a == null || b == null) return t < 0.5 ? a : (b as T);
  return (a as number) + ((b as number) - (a as number)) * t;
}

export type ScrubDisplay = MoonTimelinePoint;

/**
 * Time-scrub hook. Mirrors web `lib/useTimeScrub.js`.
 *
 *  1. Fetches ±N hour timeline once per 30min (with 15min freshness check).
 *  2. Exposes start / update / snap-to-live mutators.
 *  3. Updates are written to a ref by the gesture; a separate rAF flush
 *     converts the ref into React state at ~20fps to avoid render thrash.
 */
export function useTimeScrub(opts?: { rangeHours?: number; intervalHours?: number }) {
  const rangeHours = opts?.rangeHours ?? 72;
  const intervalHours = opts?.intervalHours ?? 2;

  const [timelineData, setTimelineData] = useState<MoonTimelinePoint[] | null>(
    null,
  );
  const [isScrubbing, setIsScrubbing] = useState(false);
  const [scrubOffsetMs, setScrubOffsetMs] = useState(0);
  const [scrubDisplayData, setScrubDisplayData] =
    useState<ScrubDisplay | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const isScrubbingRef = useRef(false);
  const timelineRef = useRef<MoonTimelinePoint[] | null>(null);
  const fetchedAtRef = useRef(0);
  const pendingOffsetRef = useRef<number | null>(null);
  const lastFlushRef = useRef(0);

  const fetchTimeline = useCallback(async () => {
    if (
      timelineRef.current &&
      Date.now() - fetchedAtRef.current < TIMELINE_FRESHNESS_MS
    ) {
      return;
    }
    setIsLoading(true);
    try {
      const data = await fetchMoonTimeline({ rangeHours, intervalHours });
      if (data?.points?.length) {
        setTimelineData(data.points);
        timelineRef.current = data.points;
        fetchedAtRef.current = Date.now();
      }
    } catch (err) {
      // Non-fatal — scrubber simply won't work until next attempt.
      console.warn("Failed to fetch moon timeline:", err);
    } finally {
      setIsLoading(false);
    }
  }, [rangeHours, intervalHours]);

  // Auto-fetch on mount + every 30min.
  useEffect(() => {
    void fetchTimeline();
    const id = setInterval(fetchTimeline, 30 * 60_000);
    return () => clearInterval(id);
  }, [fetchTimeline]);

  const getInterpolatedData = useCallback(
    (offsetMs: number): ScrubDisplay | null => {
      const points = timelineRef.current;
      if (!points || points.length === 0) return null;

      const minOffset = points[0].offsetMs;
      const maxOffset = points[points.length - 1].offsetMs;
      const clamped = Math.max(minOffset, Math.min(maxOffset, offsetMs));

      // Binary search
      let lo = 0;
      let hi = points.length - 1;
      while (lo < hi - 1) {
        const mid = (lo + hi) >> 1;
        if (points[mid].offsetMs <= clamped) lo = mid;
        else hi = mid;
      }

      const a = points[lo];
      const b = points[hi];
      if (a.offsetMs === b.offsetMs) return a;

      const t = (clamped - a.offsetMs) / (b.offsetMs - a.offsetMs);

      const moonLongitude = lerpAngle(a.moonLongitude, b.moonLongitude, t);
      const phaseAngle = lerpAngle(a.moonPhase.angle, b.moonPhase.angle, t);
      const sunLongitude = lerpAngle(a.sunLongitude, b.sunLongitude, t);
      const moonLatitude = lerp(a.moonLatitude, b.moonLatitude, t) as number;
      const moonDistanceKm = lerp(a.moonDistanceKm, b.moonDistanceKm, t) as number;
      const illuminationPercent = lerp(
        a.illuminationPercent,
        b.illuminationPercent,
        t,
      ) as number;
      const phaseDaysPast = lerp(
        a.phaseDaysPast,
        b.phaseDaysPast,
        t,
      ) as number | undefined;

      const nearest = t < 0.5 ? a : b;

      const tsA = new Date(a.timestamp).getTime();
      const tsB = new Date(b.timestamp).getTime();
      const interpolatedTs = new Date(tsA + (tsB - tsA) * t);

      return {
        timestamp: interpolatedTs.toISOString(),
        moonLongitude,
        moonLatitude,
        moonDistanceKm,
        sunLongitude,
        moonPhase: {
          name: nearest.moonPhase.name,
          angle: phaseAngle,
        },
        illuminationPercent,
        illuminationFraction:
          illuminationPercent != null ? illuminationPercent / 100 : undefined,
        phaseDaysPast,
        zodiacSign: nearest.zodiacSign,
        altitude: nearest.altitude,
        source: "Moshier Ephemeris",
        offsetMs: clamped,
      };
    },
    [],
  );

  // Keep a stable ref to getInterpolatedData for the flush loop.
  const getInterpolatedDataRef = useRef(getInterpolatedData);
  getInterpolatedDataRef.current = getInterpolatedData;

  // rAF flush — converts pendingOffsetRef writes into state at ~20fps.
  useEffect(() => {
    let raf: number;
    const flush = (timestamp: number) => {
      if (
        pendingOffsetRef.current !== null &&
        timestamp - lastFlushRef.current >= 50
      ) {
        const offset = pendingOffsetRef.current;
        pendingOffsetRef.current = null;
        lastFlushRef.current = timestamp;
        setScrubOffsetMs(offset);
        const data = getInterpolatedDataRef.current(offset);
        if (data) setScrubDisplayData(data);
      }
      raf = requestAnimationFrame(flush);
    };
    raf = requestAnimationFrame(flush);
    return () => cancelAnimationFrame(raf);
  }, []);

  const startScrub = useCallback(() => {
    setIsScrubbing(true);
    isScrubbingRef.current = true;
  }, []);

  const updateScrubOffset = useCallback((offsetMs: number) => {
    pendingOffsetRef.current = offsetMs;
  }, []);

  const snapToLive = useCallback(() => {
    pendingOffsetRef.current = null;
    setScrubOffsetMs(0);
    setIsScrubbing(false);
    isScrubbingRef.current = false;
    setScrubDisplayData(null);
  }, []);

  return {
    timelineData,
    isScrubbing,
    isScrubbingRef,
    scrubOffsetMs,
    scrubDisplayData,
    isLoading,
    fetchTimeline,
    startScrub,
    updateScrubOffset,
    snapToLive,
  };
}
