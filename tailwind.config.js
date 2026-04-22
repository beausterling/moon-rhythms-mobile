/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}', './lib/**/*.{ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        background: '#0a0a1a',
        surface: '#12122a',
        border: '#2a2a4a',
        'text-primary': '#e8e8f0',
        'text-secondary': '#8888aa',
        accent: '#00ff41',
        destructive: '#ef4444',
      },
      fontFamily: {
        'josefin': ['JosefinSans-Regular'],
        'josefin-semibold': ['JosefinSans-SemiBold'],
      },
    },
  },
  plugins: [],
};
