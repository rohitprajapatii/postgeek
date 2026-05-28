import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["var(--font-inter)", "system-ui", "sans-serif"],
        mono: ["var(--font-mono)", "ui-monospace", "monospace"],
      },
      colors: {
        ink: {
          DEFAULT: "#0b1120",
          soft: "#1e293b",
          muted: "#64748b",
        },
        surface: {
          DEFAULT: "#ffffff",
          subtle: "#f8fafc",
          sunken: "#f1f5f9",
        },
        brand: {
          50: "#eef4ff",
          100: "#dbe6ff",
          200: "#bccfff",
          300: "#8eaeff",
          400: "#5a82ff",
          500: "#3358f4",
          600: "#2440d9",
          700: "#1f33af",
          800: "#1f2f8a",
          900: "#1f2c6e",
        },
        accent: {
          teal: "#0fb6a8",
          amber: "#f59e0b",
          rose: "#f43f5e",
          violet: "#8b5cf6",
        },
      },
      boxShadow: {
        soft: "0 1px 2px rgba(15,23,42,0.04), 0 8px 24px -12px rgba(15,23,42,0.12)",
        card: "0 1px 0 rgba(15,23,42,0.03), 0 12px 32px -16px rgba(15,23,42,0.18)",
        glow: "0 0 0 1px rgba(51,88,244,0.12), 0 20px 48px -24px rgba(51,88,244,0.45)",
      },
      borderRadius: {
        xl: "0.875rem",
        "2xl": "1.25rem",
      },
      keyframes: {
        "fade-in": {
          from: { opacity: "0", transform: "translateY(6px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        shimmer: {
          "100%": { transform: "translateX(100%)" },
        },
        "pulse-ring": {
          "0%": { boxShadow: "0 0 0 0 rgba(15,182,168,0.5)" },
          "70%": { boxShadow: "0 0 0 8px rgba(15,182,168,0)" },
          "100%": { boxShadow: "0 0 0 0 rgba(15,182,168,0)" },
        },
      },
      animation: {
        "fade-in": "fade-in 0.4s ease-out both",
        "pulse-ring": "pulse-ring 2s infinite",
      },
    },
  },
  plugins: [],
};

export default config;
