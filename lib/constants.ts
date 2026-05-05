export const COLORS = {
  background: "#000000",
  surface: "#12122a",
  border: "#2a2a4a",
  textPrimary: "#e8e8f0",
  textSecondary: "#8888aa",
  accent: "#7BA5FF",
  destructive: "#ef4444",
} as const;

export const API_BASE =
  process.env.EXPO_PUBLIC_API_URL || "https://moonrhythms.io";

export const MOON_FRAME_BASE_URL = "https://moonrhythms.io/images/moon-cycle";
export const MOON_FRAME_START = 649;
export const MOON_FRAME_END = 1360;
