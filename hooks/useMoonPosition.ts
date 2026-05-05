import { useState, useEffect, useRef, useCallback } from 'react';
import { AppState } from 'react-native';
import { fetchMoonPosition, MoonPosition } from '../lib/api';

const POLL_INTERVAL = 60_000; // 1 minute
const STALE_THRESHOLD = 5 * 60_000; // 5 minutes without refresh = stale

export function useMoonPosition() {
  const [data, setData] = useState<MoonPosition | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isStale, setIsStale] = useState(false);
  const lastFetchTime = useRef(0);
  const intervalRef = useRef<ReturnType<typeof setInterval>>(undefined);

  const refresh = useCallback(async () => {
    try {
      const result = await fetchMoonPosition();
      setData(result);
      setError(null);
      setIsStale(false);
      lastFetchTime.current = Date.now();
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Failed to fetch moon data';
      setError(msg);
      // If we have cached data, mark stale instead of clearing
      if (lastFetchTime.current > 0) {
        setIsStale(true);
      }
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Initial fetch + polling
  useEffect(() => {
    refresh();
    intervalRef.current = setInterval(refresh, POLL_INTERVAL);
    return () => clearInterval(intervalRef.current);
  }, [refresh]);

  // Refresh when app comes back to foreground
  useEffect(() => {
    const sub = AppState.addEventListener('change', (state) => {
      if (state === 'active') refresh();
    });
    return () => sub.remove();
  }, [refresh]);

  // Periodic stale check (catches network loss between polls)
  useEffect(() => {
    const check = setInterval(() => {
      if (
        lastFetchTime.current > 0 &&
        Date.now() - lastFetchTime.current > STALE_THRESHOLD
      ) {
        setIsStale(true);
      }
    }, 30_000);
    return () => clearInterval(check);
  }, []);

  return { data, isLoading, error, isStale, refresh };
}
