import { useEffect, useRef, useState, type MutableRefObject } from "react";
import { AppState } from "react-native";
import { fetchMoonPosition, type MoonPosition } from "../lib/api";

const POLL_MS = 30_000;
const STALE_MS = 5 * 60_000;
const FRAME_THROTTLE_MS = 200; // ~5fps re-render
const MAX_RATE = 1.0 / 3_600_000; // 1°/hour clamp

function normalize360(v: number) {
  return ((v % 360) + 360) % 360;
}

function normalizeAngleDelta(curr: number, prev: number) {
  let delta = curr - prev;
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return delta;
}

export type LiveDisplay = {
  lon: number;
  angle: number;
  illum: number;
};

export type Rate = {
  lon: number;
  angle: number;
  illum: number;
};

type Stamped = MoonPosition & { fetchedAt: number };

/**
 * Live moon-tick hook. Polls the server every 30s, derives angular velocity
 * between samples, and extrapolates locally on a ~5fps rAF loop so the
 * arcseconds display ticks continuously.
 *
 * The hook also takes a `scrubbingRef` so the rAF loop pauses while the user
 * is scrubbing — at that point the home screen reads from useTimeScrub instead.
 *
 * Mirrors `pages/index.deploy.js` (web), see `docs/MOON_LIVE_AND_SCRUB_IMPLEMENTATION.md`.
 */
export function useMoonLive(
  scrubbingRef: MutableRefObject<boolean>,
) {
  const [tick, setTick] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isStale, setIsStale] = useState(false);

  // Refs only — putting these in state would re-render on every poll/frame.
  const currentDataRef = useRef<Stamped | null>(null);
  const serverDataRef = useRef<MoonPosition | null>(null);
  const rateRef = useRef<Rate>({
    lon: 0.5 / 3_600_000, // seed at ~0.5°/hr so display moves before sample #2 lands
    angle: 0.5 / 3_600_000,
    illum: 0,
  });
  const displayRef = useRef<LiveDisplay | null>(null);
  const lastFetchRef = useRef(0);

  const refresh = useRef(async () => {
    try {
      const data = await fetchMoonPosition();
      const now = Date.now();
      const prev = currentDataRef.current;
      currentDataRef.current = { ...data, fetchedAt: now };
      serverDataRef.current = data;

      if (prev && now - prev.fetchedAt > 10_000) {
        const dt = now - prev.fetchedAt;
        const lonRate =
          normalizeAngleDelta(data.moonLongitude, prev.moonLongitude) / dt;
        const angleRate =
          normalizeAngleDelta(data.moonPhase.angle, prev.moonPhase.angle) / dt;
        rateRef.current = {
          lon: Math.max(-MAX_RATE, Math.min(MAX_RATE, lonRate)),
          angle: Math.max(-MAX_RATE, Math.min(MAX_RATE, angleRate)),
          illum:
            ((data.illuminationPercent ?? 0) - (prev.illuminationPercent ?? 0)) /
            dt,
        };
      }

      displayRef.current = {
        lon: data.moonLongitude,
        angle: data.moonPhase.angle,
        illum: data.illuminationPercent ?? 0,
      };
      lastFetchRef.current = now;
      setError(null);
      setIsStale(false);
      setIsLoading(false);
      setTick((t) => t + 1);
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Failed to fetch moon data";
      setError(msg);
      if (lastFetchRef.current > 0) setIsStale(true);
      setIsLoading(false);
    }
  }).current;

  // Initial fetch + polling
  useEffect(() => {
    void refresh();
    const id = setInterval(refresh, POLL_MS);
    return () => clearInterval(id);
  }, [refresh]);

  // Foreground refresh
  useEffect(() => {
    const sub = AppState.addEventListener("change", (state) => {
      if (state === "active") void refresh();
    });
    return () => sub.remove();
  }, [refresh]);

  // Stale check
  useEffect(() => {
    const id = setInterval(() => {
      if (
        lastFetchRef.current > 0 &&
        Date.now() - lastFetchRef.current > STALE_MS
      ) {
        setIsStale(true);
      }
    }, 30_000);
    return () => clearInterval(id);
  }, []);

  // rAF extrapolation loop — re-renders ~5×/s by bumping `tick`.
  useEffect(() => {
    let raf: number;
    let lastUpdate = 0;

    const frame = (timestamp: number) => {
      if (timestamp - lastUpdate >= FRAME_THROTTLE_MS) {
        if (!scrubbingRef.current) {
          const curr = currentDataRef.current;
          if (curr) {
            const elapsed = Date.now() - curr.fetchedAt;
            const r = rateRef.current;
            displayRef.current = {
              lon: normalize360(curr.moonLongitude + r.lon * elapsed),
              angle: normalize360(curr.moonPhase.angle + r.angle * elapsed),
              illum:
                (curr.illuminationPercent ?? 0) + r.illum * elapsed,
            };
            setTick((t) => t + 1);
          }
        }
        lastUpdate = timestamp;
      }
      raf = requestAnimationFrame(frame);
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [scrubbingRef]);

  return {
    display: displayRef.current,
    server: serverDataRef.current,
    isLoading,
    error,
    isStale,
    refresh,
    // tick is referenced so React re-renders when displayRef mutates
    tick,
  };
}
