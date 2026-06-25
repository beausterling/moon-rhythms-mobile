import { useCallback, useEffect, useRef, useState } from "react";
import { View, Text } from "react-native";
import { useFocusEffect, useRouter } from "expo-router";
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
const FRAME_COUNT = MOON_FRAME_END - MOON_FRAME_START + 1; // 712 frames

// Precompute every frame URL once (module scope, not per render).
const FRAME_URIS = Array.from(
  { length: FRAME_COUNT },
  (_, i) =>
    `${MOON_FRAME_BASE_URL}/moon.${String(MOON_FRAME_START + i).padStart(4, "0")}.webp`,
);

export default function WelcomeScreen() {
  const router = useRouter();
  const frameIndex = useRef(0);
  const [currentFrame, setCurrentFrame] = useState(0);

  // Prefetch every frame to DISK ONLY. The encoded webps total ~2MB, but each
  // decoded 730x730 frame is ~2.1MB in memory — holding all 712 (the old
  // cachePolicy="memory-disk" behavior) ballooned to ~1.5GB and iOS jetsam-killed
  // the app after ~15s. Disk cache keeps memory flat: only the visible frame is
  // ever decoded in RAM.
  useEffect(() => {
    Image.clearMemoryCache();
    Image.prefetch(FRAME_URIS, "disk");
  }, []);

  // Advance frames only while the welcome screen is focused. On blur (navigating
  // to Sign in/up) or unmount the interval is cleared, so the loop never decodes
  // frames off-screen.
  useFocusEffect(
    useCallback(() => {
      const interval = setInterval(() => {
        frameIndex.current = (frameIndex.current + 1) % FRAME_COUNT;
        setCurrentFrame(frameIndex.current);
      }, FRAME_INTERVAL);
      return () => clearInterval(interval);
    }, []),
  );

  const moonImageUri = FRAME_URIS[currentFrame];

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
            cachePolicy="disk"
            recyclingKey="moon-loop"
            transition={0}
            priority="high"
            placeholder={{ uri: FRAME_URIS[0] }}
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
