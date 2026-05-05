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
        background: "#000000",
        surface: "#12122a",
        border: "#2a2a4a",
        "text-primary": "#e8e8f0",
        "text-secondary": "#8888aa",
        accent: "#7BA5FF",
        destructive: "#ef4444",
      },
      fontFamily: {
        josefin: ["JosefinSans-Regular"],
        "josefin-semibold": ["JosefinSans-SemiBold"],
      },
    },
  },
  plugins: [],
};
