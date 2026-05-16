// Palette tokens used outside Tailwind (inline `style={{ color: ... }}`).
// Mirrors MOBILE-DESIGN.md v1. Tailwind class names live in tailwind.config.js.
export const COLORS = {
  background: "#000000",
  surface1: "#0A0A0F",
  surface2: "#14141C",
  textPrimary: "#FFFFFF",
  textSecondary: "#D4D4D8",
  textTertiary: "#8A8A90",
  textDisabled: "#5A5A60",
  hairline: "rgba(255,255,255,0.10)",
  strong: "rgba(255,255,255,0.35)",
  destructive: "#EF4444",
} as const;

export const API_BASE =
  process.env.EXPO_PUBLIC_API_URL || "https://moonrhythms.io";

export const MOON_FRAME_BASE_URL = "https://moonrhythms.io/images/moon-cycle";
export const MOON_FRAME_START = 649;
export const MOON_FRAME_END = 1360;
