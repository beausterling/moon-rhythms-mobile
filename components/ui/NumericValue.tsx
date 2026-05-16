import { Text, type TextStyle } from "react-native";

type Size = "sm" | "md" | "lg" | "xl";

interface NumericValueProps {
  children: React.ReactNode;
  size?: Size;
  emphasis?: boolean;
  className?: string;
  style?: TextStyle;
}

const SIZES: Record<Size, { fontSize: number; lineHeight: number }> = {
  sm: { fontSize: 14, lineHeight: 21 }, // 14 × 1.5
  md: { fontSize: 18, lineHeight: 27 }, // 18 × 1.5
  lg: { fontSize: 28, lineHeight: 35 }, // 28 × 1.25
  xl: { fontSize: 44, lineHeight: 49 }, // 44 × 1.1 = 48.4 → 49 (ceil)
};

export function NumericValue({
  children,
  size = "md",
  emphasis = false,
  className,
  style,
}: NumericValueProps) {
  const dims = SIZES[size];
  return (
    <Text
      className={`font-inter text-white ${className ?? ""}`}
      style={[
        {
          fontSize: dims.fontSize,
          lineHeight: dims.lineHeight,
          fontVariant: ["tabular-nums"],
          textShadowColor: emphasis
            ? "rgba(255,255,255,0.6)"
            : "rgba(255,255,255,0.25)",
          textShadowOffset: { width: 0, height: 0 },
          textShadowRadius: emphasis ? 12 : 8,
        },
        style,
      ]}
    >
      {children}
    </Text>
  );
}
