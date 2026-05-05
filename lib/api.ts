import { API_BASE } from './constants';

export type MoonPosition = {
  timestamp: string;
  moonLongitude: number;
  moonLatitude: number;
  moonDistanceKm: number;
  sunLongitude: number;
  moonPhase: {
    name: string;
    angle: number;
  };
  illuminationPercent: number;
  zodiacSign: {
    name: string;
    symbol: string;
    degrees: number;
    minutes: number;
    seconds: number;
    degreesTotal: number;
  };
  source: string;
};

export async function fetchMoonPosition(): Promise<MoonPosition> {
  const res = await fetch(`${API_BASE}/api/moon-position`);
  if (!res.ok) throw new Error(`Moon API ${res.status}`);
  return res.json();
}
