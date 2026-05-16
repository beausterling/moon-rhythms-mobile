import { View, type ViewStyle } from "react-native";

interface CardProps {
  children: React.ReactNode;
  padding?: number;
  style?: ViewStyle;
}

export function Card({ children, padding = 16, style }: CardProps) {
  return (
    <View
      className="bg-surface-1"
      style={[
        {
          padding,
          borderRadius: 20,
          borderWidth: 1,
          borderColor: "rgba(255,255,255,0.10)",
        },
        style,
      ]}
    >
      {children}
    </View>
  );
}
