import { View } from "react-native";
import { SafeAreaView, type Edge } from "react-native-safe-area-context";
import { NightSky } from "../NightSky";

interface ScreenProps {
  children: React.ReactNode;
  starfield?: boolean;
  edges?: Edge[];
}

export function Screen({
  children,
  starfield = false,
  edges = ["top", "left", "right"],
}: ScreenProps) {
  return (
    <View className="flex-1 bg-background">
      {starfield && <NightSky />}
      <SafeAreaView edges={edges} style={{ flex: 1 }}>
        {children}
      </SafeAreaView>
    </View>
  );
}
