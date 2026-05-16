/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
  ],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        // MOBILE-DESIGN.md v1 — the entire palette.
        background: "#000000",
        "surface-1": "#0A0A0F",
        "surface-2": "#14141C",
        "text-tertiary": "#8A8A90",
        "text-disabled": "#5A5A60",
        destructive: "#EF4444",
      },
      borderColor: {
        hairline: "rgba(255,255,255,0.10)",
        strong: "rgba(255,255,255,0.35)",
      },
      fontFamily: {
        josefin: ["JosefinSans-Regular"],
        "josefin-semibold": ["JosefinSans-SemiBold"],
        inter: ["Inter-Regular"],
      },
    },
  },
  plugins: [],
};
