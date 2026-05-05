import { useState, useMemo, useCallback } from "react";
import {
  View,
  Text,
  ScrollView,
  Pressable,
  Dimensions,
  ActivityIndicator,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Image } from "expo-image";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  runOnJS,
} from "react-native-reanimated";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import { useMoonPosition } from "../../hooks/useMoonPosition";
import {
  getFrameFromAngle,
  getMoonFrameUri,
  interpolatePosition,
  formatDegrees,
  formatOffsetLabel,
} from "../../lib/moon-calc";

const { width: SCREEN_WIDTH } = Dimensions.get("window");
const TRACK_PADDING = 32;
const TRACK_WIDTH = SCREEN_WIDTH - TRACK_PADDING * 2;
const HALF_TRACK = TRACK_WIDTH / 2;
const THUMB_SIZE = 28;
const MAX_HOURS = 36;
const MOON_IMAGE_SIZE = 260;

export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  const { data, isLoading, error, isStale, refresh } = useMoonPosition();

  // Scrubber state
  const [displayOffset, setDisplayOffset] = useState(0);
  const thumbX = useSharedValue(0);
  const startX = useSharedValue(0);

  const updateOffset = useCallback((hours: number) => {
    setDisplayOffset(hours);
  }, []);

  const gesture = Gesture.Pan()
    .onStart(() => {
      "worklet";
      startX.value = thumbX.value;
    })
    .onUpdate((e) => {
      "worklet";
      const newX = Math.max(
        -HALF_TRACK,
        Math.min(HALF_TRACK, startX.value + e.translationX),
      );
      thumbX.value = newX;
      const hours = (newX / HALF_TRACK) * MAX_HOURS;
      runOnJS(updateOffset)(hours);
    })
    .onEnd(() => {
      "worklet";
      // Snap to center if close
      if (Math.abs(thumbX.value) < 12) {
        thumbX.value = withSpring(0, { damping: 20, stiffness: 300 });
        runOnJS(updateOffset)(0);
      }
    });

  const thumbStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: thumbX.value }],
  }));

  const resetToNow = useCallback(() => {
    thumbX.value = withSpring(0, { damping: 20, stiffness: 300 });
    setDisplayOffset(0);
  }, []);

  // Compute display values
  const display = useMemo(() => {
    if (!data) return null;

    if (Math.abs(displayOffset) < 0.5) {
      // Live data from API
      const frameIndex = getFrameFromAngle(data.moonPhase.angle);
      return {
        frameUri: getMoonFrameUri(frameIndex),
        phaseName: data.moonPhase.name,
        illumination: data.illuminationPercent,
        zodiacName: data.zodiacSign.name,
        zodiacSymbol: data.zodiacSign.symbol,
        degrees: data.zodiacSign.degrees,
        minutes: data.zodiacSign.minutes,
        source: data.source,
        isLive: true,
        time: new Date(data.timestamp),
      };
    }

    // Interpolated data for scrubber
    const interp = interpolatePosition(data, displayOffset);
    const time = new Date(
      new Date(data.timestamp).getTime() + displayOffset * 3600_000,
    );
    return {
      frameUri: interp.frameUri,
      phaseName: interp.phaseName,
      illumination: interp.illuminationPercent,
      zodiacName: interp.zodiac.name,
      zodiacSymbol: interp.zodiac.symbol,
      degrees: interp.zodiac.degrees,
      minutes: interp.zodiac.minutes,
      source: data.source,
      isLive: false,
      time,
    };
  }, [data, displayOffset]);

  // Loading state
  if (isLoading) {
    return (
      <View className="flex-1 bg-background items-center justify-center">
        <ActivityIndicator size="large" color="#7BA5FF" />
        <Text className="text-text-secondary text-sm font-josefin mt-4">
          Locating the Moon...
        </Text>
      </View>
    );
  }

  // Error state (no cached data)
  if (error && !data) {
    return (
      <View className="flex-1 bg-background items-center justify-center px-8">
        <Text className="text-text-primary text-xl font-josefin-semibold mb-2">
          Unable to reach the sky
        </Text>
        <Text className="text-text-secondary text-sm font-josefin text-center mb-6">
          {error}
        </Text>
        <Pressable
          onPress={refresh}
          className="h-[44px] px-6 bg-accent rounded-xl items-center justify-center"
          style={({ pressed }) => ({ opacity: pressed ? 0.8 : 1 })}
        >
          <Text className="text-background text-sm font-josefin-semibold">
            Try again
          </Text>
        </Pressable>
      </View>
    );
  }

  if (!display) return null;

  const timeString = display.time.toLocaleTimeString([], {
    hour: "numeric",
    minute: "2-digit",
  });
  const dateString = display.time.toLocaleDateString([], {
    month: "short",
    day: "numeric",
  });

  return (
    <View className="flex-1 bg-background">
      <ScrollView
        contentContainerStyle={{
          paddingTop: insets.top + 16,
          paddingBottom: 56 + insets.bottom + 24, // tab bar height + safe area
          alignItems: "center",
        }}
        showsVerticalScrollIndicator={false}
      >
        {/* Stale indicator */}
        {isStale && (
          <View
            className="mx-8 mb-4 px-4 py-2 rounded-lg"
            style={{ backgroundColor: "rgba(245,158,11,0.15)" }}
          >
            <Text
              className="text-center text-xs font-josefin"
              style={{ color: "#f59e0b" }}
            >
              Showing cached data &middot; Tap to retry
            </Text>
          </View>
        )}

        {/* Time offset banner */}
        {!display.isLive && (
          <Pressable onPress={resetToNow} className="mb-2">
            <View
              className="px-4 py-1.5 rounded-full"
              style={{ backgroundColor: "rgba(123,165,255,0.1)" }}
            >
              <Text className="text-accent text-xs font-josefin text-center">
                {formatOffsetLabel(displayOffset)} &middot; {dateString}{" "}
                {timeString} &middot; Tap for Now
              </Text>
            </View>
          </Pressable>
        )}

        {/* Moon phase image */}
        <View
          className="overflow-hidden mt-4"
          style={{
            width: MOON_IMAGE_SIZE,
            height: MOON_IMAGE_SIZE,
            borderRadius: MOON_IMAGE_SIZE / 2,
          }}
        >
          <Image
            source={{ uri: display.frameUri }}
            style={{ width: MOON_IMAGE_SIZE, height: MOON_IMAGE_SIZE }}
            contentFit="cover"
            cachePolicy="memory-disk"
            transition={200}
          />
        </View>

        {/* Phase name */}
        <Text
          className="text-text-primary font-josefin-semibold mt-6"
          style={{ fontSize: 28, lineHeight: 34 }}
        >
          {display.phaseName}
        </Text>

        {/* Illumination */}
        <Text className="text-text-secondary text-base font-josefin mt-1">
          {display.illumination.toFixed(1)}% illuminated
        </Text>

        {/* Zodiac card */}
        <View
          className="mt-6 mx-8 rounded-2xl px-6 py-5 items-center"
          style={{ backgroundColor: "rgba(18,18,42,0.8)" }}
        >
          <Text style={{ fontSize: 48, lineHeight: 56 }}>
            {display.zodiacSymbol}
          </Text>
          <Text
            className="text-text-primary font-josefin-semibold mt-2"
            style={{ fontSize: 22 }}
          >
            {display.zodiacName}
          </Text>
          <Text className="text-text-secondary text-base font-josefin mt-1">
            {formatDegrees(display.degrees, display.minutes)}
          </Text>
        </View>

        {/* 72-Hour Time Scrubber */}
        <View
          className="mt-8 w-full"
          style={{ paddingHorizontal: TRACK_PADDING }}
        >
          <Text className="text-text-secondary text-xs font-josefin text-center mb-3">
            72-Hour Time Scrubber
          </Text>

          <GestureDetector gesture={gesture}>
            <View style={{ height: 48, justifyContent: "center" }}>
              {/* Track background */}
              <View
                className="rounded-full"
                style={{
                  height: 3,
                  backgroundColor: "rgba(42,42,74,0.8)",
                  width: "100%",
                }}
              />

              {/* Center tick (Now) */}
              <View
                style={{
                  position: "absolute",
                  left: HALF_TRACK - 0.5,
                  width: 1,
                  height: 12,
                  backgroundColor: "rgba(136,136,170,0.4)",
                  top: 18,
                }}
              />

              {/* Quarter ticks */}
              {[-0.5, -0.25, 0.25, 0.5].map((pct) => (
                <View
                  key={pct}
                  style={{
                    position: "absolute",
                    left: HALF_TRACK + pct * TRACK_WIDTH - 0.5,
                    width: 1,
                    height: 8,
                    backgroundColor: "rgba(136,136,170,0.2)",
                    top: 20,
                  }}
                />
              ))}

              {/* Thumb */}
              <Animated.View
                style={[
                  {
                    position: "absolute",
                    left: HALF_TRACK - THUMB_SIZE / 2,
                    top: (48 - THUMB_SIZE) / 2,
                    width: THUMB_SIZE,
                    height: THUMB_SIZE,
                    borderRadius: THUMB_SIZE / 2,
                    backgroundColor: "#7BA5FF",
                    shadowColor: "#7BA5FF",
                    shadowOffset: { width: 0, height: 0 },
                    shadowOpacity: 0.5,
                    shadowRadius: 8,
                    elevation: 6,
                  },
                  thumbStyle,
                ]}
              />
            </View>
          </GestureDetector>

          {/* Scrubber labels */}
          <View className="flex-row justify-between mt-1">
            <Text
              className="text-text-secondary text-xs font-josefin"
              style={{ opacity: 0.5 }}
            >
              -36h
            </Text>
            <Text
              className="text-text-secondary text-xs font-josefin"
              style={{ opacity: 0.5 }}
            >
              Now
            </Text>
            <Text
              className="text-text-secondary text-xs font-josefin"
              style={{ opacity: 0.5 }}
            >
              +36h
            </Text>
          </View>
        </View>

        {/* Source attribution */}
        <Text
          className="text-text-secondary text-xs font-josefin mt-8"
          style={{ opacity: 0.4 }}
        >
          {display.source}
        </Text>

        {/* Live indicator */}
        {display.isLive && (
          <View className="flex-row items-center mt-3">
            <View
              style={{
                width: 6,
                height: 6,
                borderRadius: 3,
                backgroundColor: "#7BA5FF",
                marginRight: 6,
              }}
            />
            <Text
              className="text-text-secondary text-xs font-josefin"
              style={{ opacity: 0.5 }}
            >
              Live
            </Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}
