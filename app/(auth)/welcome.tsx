import { useEffect, useRef, useState } from "react";
import { View, Text } from "react-native";
import { useRouter } from "expo-router";
import { Image } from "expo-image";
import {
  MOON_FRAME_BASE_URL,
  MOON_FRAME_START,
  MOON_FRAME_END,
} from "../../lib/constants";
import { NightSky } from "../../components/NightSky";
import { GhostPillButton } from "../../components/ui/GhostPillButton";
import { TextLink } from "../../components/ui/TextLink";

const FRAME_INTERVAL = 1000 / 24; // 24fps = ~42ms per frame

export default function WelcomeScreen() {
  const router = useRouter();
  const frameIndex = useRef(MOON_FRAME_START);
  const [currentFrame, setCurrentFrame] = useState(MOON_FRAME_START);

  useEffect(() => {
    const interval = setInterval(() => {
      frameIndex.current += 1;
      if (frameIndex.current > MOON_FRAME_END) {
        frameIndex.current = MOON_FRAME_START;
      }
      setCurrentFrame(frameIndex.current);
    }, FRAME_INTERVAL);

    return () => clearInterval(interval);
  }, []);

  const moonImageUri = `${MOON_FRAME_BASE_URL}/moon.${String(currentFrame).padStart(4, "0")}.webp`;

  return (
    <View className="flex-1 bg-black items-center justify-center">
      <NightSky />

      <View className="items-center px-8 w-full">
        {/* Moon loop — 240px diameter circle */}
        <View
          className="overflow-hidden"
          style={{
            width: 240,
            height: 240,
            borderRadius: 120,
            backgroundColor: "transparent",
          }}
        >
          <Image
            source={{ uri: moonImageUri }}
            style={{
              width: 280,
              height: 280,
              left: -20,
              top: -20,
              backgroundColor: "transparent",
            }}
            contentFit="cover"
            cachePolicy="memory-disk"
            placeholder={{
              uri: `${MOON_FRAME_BASE_URL}/moon.${String(MOON_FRAME_START).padStart(4, "0")}.webp`,
            }}
          />
        </View>

        <Text
          className="font-josefin-semibold mt-8"
          style={{ fontSize: 32, lineHeight: 38, color: "#ffffff" }}
        >
          Moon Rhythms
        </Text>

        <Text className="text-slate-300 text-lg font-josefin mt-2">
          live in tune with the sky
        </Text>

        <View className="w-full mt-12">
          <GhostPillButton
            label="Begin"
            onPress={() => router.push("/(auth)/sign-up")}
          />

          <View className="mt-4">
            <TextLink
              prefix="Already have an account? "
              linkText="Sign in"
              onPress={() => router.push("/(auth)/sign-in")}
            />
          </View>
        </View>
      </View>
    </View>
  );
}
