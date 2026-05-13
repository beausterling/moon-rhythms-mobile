import { useEffect, useRef, useState } from "react";
import { View, Text, Pressable, Dimensions, StyleSheet } from "react-native";
import { useRouter } from "expo-router";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  withSequence,
  withDelay,
  Easing,
  interpolate,
} from "react-native-reanimated";
import {
  MOON_FRAME_BASE_URL,
  MOON_FRAME_START,
  MOON_FRAME_END,
} from "../../lib/constants";
import { NightSky } from "../../components/NightSky";

const { width: SCREEN_WIDTH } = Dimensions.get("window");
const FRAME_INTERVAL = 1000 / 24; // 24fps = ~42ms per frame

export default function WelcomeScreen() {
  const router = useRouter();
  const frameIndex = useRef(MOON_FRAME_START);
  const [currentFrame, setCurrentFrame] = useState(MOON_FRAME_START);

  // Shimmer sweep across the Begin button.
  // Button = w-full inside a px-8 container, so width = SCREEN_WIDTH - 64.
  const BUTTON_WIDTH = SCREEN_WIDTH - 64;
  const SHIMMER_WIDTH = 24;
  const shimmerProgress = useSharedValue(0);

  useEffect(() => {
    shimmerProgress.value = withRepeat(
      withSequence(
        withDelay(7500, withTiming(1, { duration: 900, easing: Easing.linear })),
        withTiming(0, { duration: 0 }),
      ),
      -1,
      false,
    );
  }, []);

  const shimmerStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateX: interpolate(
          shimmerProgress.value,
          [0, 1],
          [-SHIMMER_WIDTH * 2, BUTTON_WIDTH + SHIMMER_WIDTH],
        ),
      },
      { rotate: "22.5deg" },
    ],
  }));

  // Moon loop animation at 24fps
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

  // CDN WebP URL pattern: moon.0649.webp, moon.0650.webp, ...
  const moonImageUri = `${MOON_FRAME_BASE_URL}/moon.${String(currentFrame).padStart(4, "0")}.webp`;

  return (
    <View className="flex-1 bg-black items-center justify-center">
      <NightSky />

      {/* Content */}
      <View className="items-center px-8">
        {/* Moon loop -- 240px diameter circle */}
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

        {/* Branding */}
        <Text
          className="font-josefin-semibold mt-8"
          style={{ fontSize: 32, lineHeight: 38, color: "#ffffff" }}
        >
          Moon Rhythms
        </Text>

        {/* Tagline */}
        <Text className="text-slate-300 text-lg font-josefin mt-2">
          live in tune with the sky
        </Text>

        {/* CTA section -- 48px gap from tagline */}
        <View className="w-full mt-12">
          {/* Begin button -- transparent ghost pill with bright shimmer */}
          <Pressable
            onPress={() => router.push("/(auth)/sign-up")}
            style={({ pressed }) => ({
              height: 56,
              borderRadius: 28,
              overflow: "hidden",
              opacity: pressed ? 0.85 : 1,
              transform: [{ scale: pressed ? 0.98 : 1 }],
            })}
          >
            {/* Crisp hairline border */}
            <View
              style={[
                StyleSheet.absoluteFill,
                {
                  borderRadius: 28,
                  borderWidth: 1,
                  borderColor: "rgba(255,255,255,0.35)",
                },
              ]}
              pointerEvents="none"
            />

            {/* Faint inner glow toward the top -- adds dimensionality without grayness */}
            <LinearGradient
              colors={["rgba(255,255,255,0.08)", "rgba(255,255,255,0)"]}
              style={[StyleSheet.absoluteFill, { borderRadius: 28 }]}
              pointerEvents="none"
            />

            {/* Shimmer -- wrapped in a dedicated clipper that masks to the pill shape */}
            <View
              style={[
                StyleSheet.absoluteFill,
                { borderRadius: 28, overflow: "hidden" },
              ]}
              pointerEvents="none"
            >
              <Animated.View
                style={[
                  {
                    position: "absolute",
                    top: -32,
                    bottom: -32,
                    width: SHIMMER_WIDTH,
                    opacity: 0.5,
                  },
                  shimmerStyle,
                ]}
                pointerEvents="none"
              >
                <LinearGradient
                  colors={[
                    "rgba(255,255,255,0)",
                    "rgba(255,255,255,0.28)",
                    "rgba(255,255,255,0)",
                  ]}
                  start={{ x: 0, y: 0.5 }}
                  end={{ x: 1, y: 0.5 }}
                  style={{ flex: 1 }}
                />
              </Animated.View>
            </View>

            {/* Label */}
            <View className="flex-1 items-center justify-center">
              <Text className="text-white text-lg font-josefin-semibold tracking-[0.3px]">
                Begin
              </Text>
            </View>
          </Pressable>

          {/* Sign in link -- 16px gap */}
          <Pressable
            onPress={() => router.push("/(auth)/sign-in")}
            className="mt-4 items-center"
          >
            <Text
              className="text-base font-josefin"
              style={{ color: "#8888aa" }}
            >
              Already have an account?{" "}
              <Text
                className="font-josefin-semibold"
                style={{ color: "#ffffff" }}
              >
                Sign in
              </Text>
            </Text>
          </Pressable>
        </View>
      </View>
    </View>
  );
}
