import { useEffect, useState } from "react";
import {
  Pressable,
  Text,
  View,
  StyleSheet,
  type LayoutChangeEvent,
  type ViewStyle,
} from "react-native";
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

const SHIMMER_WIDTH = 24;
const SHIMMER_DELAY_MS = 7500;
const SHIMMER_SWEEP_MS = 900;

interface GhostPillButtonProps {
  label: string;
  onPress: () => void;
  height?: number;
  shimmer?: boolean;
  disabled?: boolean;
  style?: ViewStyle;
}

export function GhostPillButton({
  label,
  onPress,
  height = 56,
  shimmer = true,
  disabled = false,
  style,
}: GhostPillButtonProps) {
  const [buttonWidth, setButtonWidth] = useState(0);
  const shimmerProgress = useSharedValue(0);
  const borderRadius = height / 2;

  useEffect(() => {
    if (!shimmer) return;
    shimmerProgress.value = withRepeat(
      withSequence(
        withDelay(
          SHIMMER_DELAY_MS,
          withTiming(1, { duration: SHIMMER_SWEEP_MS, easing: Easing.linear }),
        ),
        withTiming(0, { duration: 0 }),
      ),
      -1,
      false,
    );
  }, [shimmer]);

  const shimmerStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateX: interpolate(
          shimmerProgress.value,
          [0, 1],
          [-SHIMMER_WIDTH * 2, buttonWidth + SHIMMER_WIDTH],
        ),
      },
      { rotate: "22.5deg" },
    ],
  }));

  const handleLayout = (e: LayoutChangeEvent) => {
    setButtonWidth(e.nativeEvent.layout.width);
  };

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      onLayout={handleLayout}
      style={({ pressed }) => [
        {
          height,
          borderRadius,
          overflow: "hidden",
          opacity: disabled ? 0.5 : pressed ? 0.85 : 1,
          transform: [{ scale: pressed && !disabled ? 0.98 : 1 }],
        },
        style,
      ]}
    >
      <View
        style={[
          StyleSheet.absoluteFill,
          {
            borderRadius,
            borderWidth: 1,
            borderColor: "rgba(255,255,255,0.35)",
          },
        ]}
        pointerEvents="none"
      />

      <LinearGradient
        colors={["rgba(255,255,255,0.08)", "rgba(255,255,255,0)"]}
        style={[StyleSheet.absoluteFill, { borderRadius }]}
        pointerEvents="none"
      />

      {shimmer && (
        <View
          style={[
            StyleSheet.absoluteFill,
            { borderRadius, overflow: "hidden" },
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
      )}

      <View className="flex-1 items-center justify-center">
        <Text className="text-white text-lg font-josefin-semibold tracking-[0.3px]">
          {label}
        </Text>
      </View>
    </Pressable>
  );
}
