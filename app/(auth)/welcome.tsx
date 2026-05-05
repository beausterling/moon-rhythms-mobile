import { useEffect, useRef, useMemo, useState } from "react";
import { View, Text, Pressable, Dimensions, StyleSheet } from "react-native";
import { useRouter } from "expo-router";
import { Image } from "expo-image";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  Easing,
  interpolate,
} from "react-native-reanimated";
import {
  MOON_FRAME_BASE_URL,
  MOON_FRAME_START,
  MOON_FRAME_END,
} from "../../lib/constants";

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get("window");
const TOTAL_FRAMES = MOON_FRAME_END - MOON_FRAME_START + 1; // 712 frames
const FRAME_INTERVAL = 1000 / 24; // 24fps = ~42ms per frame

// Generate star data once (deterministic pseudo-random using index as seed)
function generateStars(count: number) {
  const stars = [];
  for (let i = 0; i < count; i++) {
    stars.push({
      id: i,
      x: ((i * 7919 + 104729) % 10000) / 10000, // pseudo-random x (0-1)
      y: ((i * 6271 + 87811) % 10000) / 10000, // pseudo-random y (0-1)
      size: 1 + ((i * 3571) % 2), // 1 or 2px
      baseOpacity: 0.2 + ((i * 4217) % 40) / 100, // 0.2-0.6
      duration: 3000 + ((i * 2719) % 5000), // 3-8 seconds
    });
  }
  return stars;
}

function Star({
  x,
  y,
  size,
  baseOpacity,
  duration,
}: {
  x: number;
  y: number;
  size: number;
  baseOpacity: number;
  duration: number;
}) {
  const opacity = useSharedValue(baseOpacity);

  useEffect(() => {
    opacity.value = withRepeat(
      withTiming(baseOpacity - 0.1, {
        duration,
        easing: Easing.inOut(Easing.ease),
      }),
      -1,
      true,
    );
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
  }));

  return (
    <Animated.View
      style={[
        {
          position: "absolute",
          left: x * SCREEN_WIDTH,
          top: y * SCREEN_HEIGHT,
          width: size,
          height: size,
          borderRadius: size / 2,
          backgroundColor: "#e8e8f0",
        },
        animatedStyle,
      ]}
    />
  );
}

export default function WelcomeScreen() {
  const router = useRouter();
  const frameIndex = useRef(MOON_FRAME_START);
  const [currentFrame, setCurrentFrame] = useState(MOON_FRAME_START);

  const stars = useMemo(() => generateStars(50), []);

  // Shimmer sweep across the Begin button.
  // Button = w-full inside a px-8 container, so width = SCREEN_WIDTH - 64.
  const BUTTON_WIDTH = SCREEN_WIDTH - 64;
  const SHIMMER_WIDTH = 50;
  const shimmerProgress = useSharedValue(0);

  useEffect(() => {
    shimmerProgress.value = withRepeat(
      withTiming(1, { duration: 2200, easing: Easing.linear }),
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
          [-SHIMMER_WIDTH, BUTTON_WIDTH],
        ),
      },
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
      {/* Starfield layer */}
      <View
        style={{ position: "absolute", top: 0, left: 0, right: 0, bottom: 0 }}
      >
        {stars.map((star) => (
          <Star key={star.id} {...star} />
        ))}
      </View>

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
          className="text-white font-josefin-semibold mt-8"
          style={{ fontSize: 32, lineHeight: 38 }}
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
                    top: 0,
                    bottom: 0,
                    width: 50,
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
            <Text className="text-base font-josefin text-white">
              Already have an account?{" "}
              <Text className="text-white">Sign in</Text>
            </Text>
          </Pressable>
        </View>
      </View>
    </View>
  );
}
