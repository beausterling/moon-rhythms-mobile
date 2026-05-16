import EventSource from 'react-native-sse';
import { API_BASE } from './constants';
import { supabase } from './supabase';

// ─── Moon position (public) ──────────────────────────────────────────────

export type MoonAltitude = {
  apparentAltitude: number;
  azimuth: number;
};

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
  illuminationFraction?: number;
  phaseDaysPast?: number;
  zodiacSign: {
    name: string;
    symbol: string;
    degrees: number;
    minutes: number;
    seconds: number;
    degreesTotal: number;
  };
  altitude?: MoonAltitude;
  source: string;
};

export type MoonTimelinePoint = MoonPosition & {
  offsetMs: number;
};

export type LatLng = { latitude: number; longitude: number };

export async function fetchMoonPosition(
  location?: LatLng | null,
): Promise<MoonPosition> {
  const res = await fetch(`${API_BASE}/api/moon-position`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ location: location ?? null }),
  });
  if (!res.ok) throw new Error(`Moon API ${res.status}`);
  return res.json();
}

export async function fetchMoonTimeline(opts?: {
  location?: LatLng | null;
  rangeHours?: number;
  intervalHours?: number;
}): Promise<{ points: MoonTimelinePoint[]; generatedAt: string }> {
  const res = await fetch(`${API_BASE}/api/moon-timeline`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      location: opts?.location ?? null,
      rangeHours: opts?.rangeHours ?? 72,
      intervalHours: opts?.intervalHours ?? 2,
    }),
  });
  if (!res.ok) throw new Error(`Moon timeline ${res.status}`);
  return res.json();
}

// ─── Authed fetch ────────────────────────────────────────────────────────

async function authedFetch(path: string, init: RequestInit = {}) {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const token = session?.access_token;
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...((init.headers as Record<string, string>) || {}),
  };
  if (token) headers.Authorization = `Bearer ${token}`;
  return fetch(`${API_BASE}${path}`, { ...init, headers });
}

// ─── Timezone (public, but we go through web's endpoint to keep one source of truth) ──

export type TimezoneResult = {
  utcOffset: string; // e.g. "UTC-07:00"
  isoOffset: string; // e.g. "-07:00"
  timeZoneId: string; // e.g. "America/Los_Angeles"
  timeZoneName: string;
};

export async function fetchTimezone(
  lat: number,
  lng: number,
  birthdate: string,
): Promise<TimezoneResult> {
  const timestamp = Math.floor(
    new Date(`${birthdate}T12:00:00Z`).getTime() / 1000,
  );
  const url = `${API_BASE}/api/timezone?lat=${encodeURIComponent(
    String(lat),
  )}&lng=${encodeURIComponent(String(lng))}&timestamp=${timestamp}`;
  const res = await fetch(url);
  const json = await res.json();
  if (!res.ok) throw new Error(json.error || `Timezone API ${res.status}`);
  return json;
}

// ─── Chart generation + save ─────────────────────────────────────────────

export type ChartInput = {
  name: string;
  birthdate: string; // YYYY-MM-DD
  birthtime: string | null; // HH:MM:SS or null
  location: string;
  lat: number;
  lng: number;
  utc_offset: string; // "UTC±HH:MM"
};

export type ChartResult = Record<string, unknown> & {
  planets?: Array<{
    key: string;
    name: string;
    sign: string;
    position: number;
    positionDMS?: { degrees: number; minutes: number; seconds: number };
  }>;
  ascendant?: number;
  midheaven?: number;
  houses?: Array<{ house: number; sign: string }>;
};

export async function generateChart(input: ChartInput): Promise<ChartResult> {
  const res = await fetch(`${API_BASE}/api/SwissEphemerisChart`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: input.name,
      birthdate: input.birthdate,
      birthtime: input.birthtime ?? '12:00:00',
      location: input.location,
      lat: input.lat,
      lng: input.lng,
      utc_offset: input.utc_offset,
    }),
  });
  const json = await res.json();
  if (!res.ok || !json.success) {
    throw new Error(json.error || json.details || `Chart API ${res.status}`);
  }
  return json.data;
}

export type SavedReading = {
  id: string;
  user_id: string;
  type: 'birth_chart';
  input_data: {
    name?: string;
    birthdate?: string;
    birthtime?: string | null;
    location?: string;
    lat?: number;
    lng?: number;
    utc_offset?: string;
  };
  result_data: ChartResult;
  created_at: string;
};

export async function saveBirthChartReading(
  input: ChartInput,
  result: ChartResult,
): Promise<SavedReading | null> {
  const res = await authedFetch('/api/save-reading', {
    method: 'POST',
    body: JSON.stringify({
      type: 'birth_chart',
      input_data: input,
      result_data: result,
    }),
  });
  const json = await res.json();
  if (!res.ok || !json.success) {
    throw new Error(json.error || `Save reading ${res.status}`);
  }
  return json.reading;
}

export async function fetchReadings(type?: string): Promise<SavedReading[]> {
  const path = type ? `/api/readings?type=${encodeURIComponent(type)}` : '/api/readings';
  const res = await authedFetch(path);
  const json = await res.json();
  if (!res.ok || !json.success) {
    throw new Error(json.error || `Readings ${res.status}`);
  }
  return json.readings || [];
}

// ─── Profile ─────────────────────────────────────────────────────────────

export type ProfilePayload = {
  id: string;
  profile_id: string | null;
  name: string;
  birthdate: string | null;
  birthtime: string | null;
  birth_lat: number | null;
  birth_lng: number | null;
  birth_location: string | null;
  birth_utc_offset: string | null;
};

export async function fetchProfile(): Promise<ProfilePayload> {
  const res = await authedFetch('/api/profile');
  const json = await res.json();
  if (!res.ok || !json.success) {
    throw new Error(json.error || `Profile ${res.status}`);
  }
  return json.profile;
}

// ─── Chat sessions ───────────────────────────────────────────────────────

export type ChatSession = {
  id: string;
  session_type: 'solo' | 'relationship';
  profile_id: string | null;
  relationship_id: string | null;
  title: string | null;
  last_message_at: string | null;
  created_at: string;
};

export async function fetchChatSessions(): Promise<ChatSession[]> {
  const res = await authedFetch('/api/chat-sessions');
  const json = await res.json();
  if (!res.ok) throw new Error(json.error || `Sessions ${res.status}`);
  return json.sessions || [];
}

export type CreateSessionResult =
  | { ok: true; session: ChatSession }
  | { ok: false; status: number; error: string; code?: string };

export async function createChatSession(
  profileId: string,
  title?: string,
): Promise<CreateSessionResult> {
  const res = await authedFetch('/api/chat-sessions', {
    method: 'POST',
    body: JSON.stringify({ profile_id: profileId, title: title || null }),
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    return {
      ok: false,
      status: res.status,
      error: json.message || json.error || `Create session ${res.status}`,
      code: json.error,
    };
  }
  return { ok: true, session: json.session };
}

export async function synthesizeProfileSummary(
  profileId: string,
): Promise<void> {
  const res = await authedFetch('/api/synthesize-profile-summary', {
    method: 'POST',
    body: JSON.stringify({ profile_id: profileId }),
  });
  if (!res.ok) {
    const json = await res.json().catch(() => ({}));
    throw new Error(json.error || `Synthesize ${res.status}`);
  }
}

// ─── Chat messages ───────────────────────────────────────────────────────

export type ChatMessage = {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  ai_response_id: string | null;
  created_at: string;
};

export async function fetchChatMessages(
  sessionId: string,
): Promise<ChatMessage[]> {
  const res = await authedFetch(
    `/api/chat-messages?session_id=${encodeURIComponent(sessionId)}`,
  );
  const json = await res.json();
  if (!res.ok) throw new Error(json.error || `Messages ${res.status}`);
  return json.messages || [];
}

// ─── Chat streaming (SSE) ────────────────────────────────────────────────

type StreamHandlers = {
  onStart?: (data: { session_id: string; user_message_id: string }) => void;
  onToken: (text: string) => void;
  onDone: (data: {
    message_id: string | null;
    ai_response_id: string | null;
    cost_cents: number;
  }) => void;
  onError: (err: { message: string; status?: number; code?: string }) => void;
};

export type StreamController = { cancel: () => void };

type SseEvents = 'start' | 'token' | 'done';

export async function streamChatResponse(
  sessionId: string,
  message: string,
  handlers: StreamHandlers,
): Promise<StreamController> {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const token = session?.access_token;

  const url = `${API_BASE}/api/chat-respond`;

  const es = new EventSource<SseEvents>(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'text/event-stream',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ session_id: sessionId, message }),
    pollingInterval: 0, // do not reconnect; this is one-shot
  });

  let done = false;

  es.addEventListener('start', (ev) => {
    if (ev.type !== 'start') return;
    try {
      const data = JSON.parse(ev.data ?? '{}');
      handlers.onStart?.(data);
    } catch {
      /* noop */
    }
  });

  es.addEventListener('token', (ev) => {
    if (ev.type !== 'token') return;
    try {
      const data = JSON.parse(ev.data ?? '{}');
      if (typeof data.content === 'string') handlers.onToken(data.content);
    } catch {
      /* noop */
    }
  });

  es.addEventListener('done', (ev) => {
    if (ev.type !== 'done') return;
    done = true;
    try {
      const data = JSON.parse(ev.data ?? '{}');
      handlers.onDone(data);
    } catch {
      handlers.onDone({
        message_id: null,
        ai_response_id: null,
        cost_cents: 0,
      });
    }
    es.close();
  });

  es.addEventListener('error', (ev) => {
    if (done) return;
    // react-native-sse error events expose either a JS-level error or an HTTP error.
    // Type definitions vary; cast to any for the optional fields.
    const e = ev as unknown as {
      type: string;
      message?: string;
      xhrStatus?: number;
      xhrState?: number;
      data?: string;
    };
    let status: number | undefined = e.xhrStatus;
    let bodyMessage: string | undefined;
    let code: string | undefined;
    if (typeof e.data === 'string') {
      try {
        const parsed = JSON.parse(e.data);
        bodyMessage = parsed.message || parsed.error;
        code = parsed.error;
      } catch {
        bodyMessage = e.data;
      }
    }
    handlers.onError({
      message: bodyMessage || e.message || 'Stream error',
      status,
      code,
    });
    es.close();
  });

  return {
    cancel: () => {
      if (!done) es.close();
    },
  };
}
