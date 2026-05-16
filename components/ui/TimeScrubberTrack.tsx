import { useCallback, useMemo, useState } from "react";
import { Text, View, type LayoutChangeEvent } from "react-native";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  runOnJS,
} from "react-native-reanimated";

const HOUR_MS = 60 * 60_000;
const TICK_INTERVAL_MS = 12 * HOUR_MS;
const DAY_MS = 24 * HOUR_MS;

const HAIRLINE = "rgba(255,255,255,0.10)";
const MEDIUM = "rgba(255,255,255,0.35)";

interface Props {
  rangeMs: number; // ± half-range, e.g. 72h
  offsetMs: number; // current scrub offset (state-side, lags ~20fps)
  isScrubbing: boolean;
  onScrubStart: () => void;
  onScrubUpdate: (offsetMs: number) => void;
  onScrubEnd?: () => void;
}

function formatDayLabel(offsetMs: number, now: number) {
  const date = new Date(now + offsetMs);
  return date.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

export function TimeScrubberTrack({
  rangeMs,
  offsetMs,
  isScrubbing,
  onScrubStart,
  onScrubUpdate,
  onScrubEnd,
}: Props) {
  const [trackWidth, setTrackWidth] = useState(0);
  const totalRangeMs = rangeMs * 2;

  // Pan-gesture shared values.
  const dragStart = useSharedValue(0);
  const liveOffset = useSharedValue(offsetMs);

  // Build tick list: every 12h across the range.
  const ticks = useMemo(() => {
    const list: { offset: number; isMajor: boolean }[] = [];
    for (let off = -rangeMs; off <= rangeMs; off += TICK_INTERVAL_MS) {
      list.push({ offset: off, isMajor: Math.abs(off % DAY_MS) === 0 });
    }
    return list;
  }, [rangeMs]);

  // Anchor "now" once per mount so day labels don't churn.
  const [anchorNow] = useState(() => Date.now());
  const seenDayKeys = useMemo(() => new Set<string>(), []);

  const onTrackLayout = useCallback((e: LayoutChangeEvent) => {
    setTrackWidth(e.nativeEvent.layout.width);
  }, []);

  const pan = useMemo(
    () =>
      Gesture.Pan()
        .onBegin(() => {
          "worklet";
          dragStart.value = liveOffset.value;
          runOnJS(onScrubStart)();
        })
        .onUpdate((e) => {
          "worklet";
          if (trackWidth <= 0) return;
          // Drag right → forward in time.
          const deltaMs = (e.translationX / trackWidth) * totalRangeMs;
          const next = Math.max(
            -rangeMs,
            Math.min(rangeMs, dragStart.value + deltaMs),
          );
          liveOffset.value = next;
          runOnJS(onScrubUpdate)(next);
        })
        .onEnd(() => {
          "worklet";
          if (onScrubEnd) runOnJS(onScrubEnd)();
        }),
    [trackWidth, totalRangeMs, rangeMs, onScrubStart, onScrubUpdate, onScrubEnd, dragStart, liveOffset],
  );

  // Sync external offsetMs back into shared value when not scrubbing
  // (e.g. snap-to-live sets offsetMs=0).
  if (!isScrubbing && liveOffset.value !== offsetMs) {
    liveOffset.value = withSpring(offsetMs, { damping: 20, stiffness: 200 });
  }

  // Scrub indicator position — driven by shared value for smooth tracking
  // even while React state lags.
  const thumbStyle = useAnimatedStyle(() => {
    const pct =
      totalRangeMs > 0
        ? (liveOffset.value + rangeMs) / totalRangeMs
        : 0.5;
    return {
      transform: [{ translateX: pct * trackWidth - 4 }],
    };
  });

  return (
    <View style={{ width: "100%", paddingHorizontal: 16 }}>
      <GestureDetector gesture={pan}>
        <View
          onLayout={onTrackLayout}
          style={{
            height: 56,
            justifyContent: "center",
          }}
        >
          {/* Track line */}
          <View
            style={{
              position: "absolute",
              top: 28,
              left: 0,
              right: 0,
              height: 1,
              backgroundColor: HAIRLINE,
            }}
          />

          {/* Center "now" marker — taller, brighter */}
          <View
            style={{
              position: "absolute",
              top: 18,
              left: trackWidth / 2 - 0.5,
              width: 1,
              height: 20,
              backgroundColor: MEDIUM,
            }}
          />

          {/* Ticks + day labels */}
          {trackWidth > 0 &&
            ticks.map(({ offset, isMajor }) => {
              const pct = (offset + rangeMs) / totalRangeMs;
              const left = pct * trackWidth;
              const isNow = offset === 0;

              const dayKey = new Date(anchorNow + offset).toDateString();
              const showLabel = isMajor && !isNow && !seenDayKeys.has(dayKey);
              if (showLabel) seenDayKeys.add(dayKey);

              return (
                <View
                  key={offset}
                  pointerEvents="none"
                  style={{
                    position: "absolute",
                    left: left - 0.5,
                    top: 22,
                    alignItems: "center",
                  }}
                >
                  <View
                    style={{
                      width: 1,
                      height: isMajor ? 12 : 6,
                      backgroundColor: isMajor ? MEDIUM : HAIRLINE,
                    }}
                  />
                  {showLabel && (
                    <Text
                      className="font-josefin text-text-tertiary"
                      style={{
                        fontSize: 10,
                        marginTop: 4,
                        marginLeft: -20,
                        width: 40,
                        textAlign: "center",
                      }}
                    >
                      {formatDayLabel(offset, anchorNow)}
                    </Text>
                  )}
                </View>
              );
            })}

          {/* Scrub thumb (visible only while scrubbing) */}
          {isScrubbing && trackWidth > 0 && (
            <Animated.View
              pointerEvents="none"
              style={[
                {
                  position: "absolute",
                  top: 24,
                  left: 0,
                  width: 8,
                  height: 8,
                  borderRadius: 4,
                  backgroundColor: "#FFFFFF",
                  shadowColor: "#FFFFFF",
                  shadowOffset: { width: 0, height: 0 },
                  shadowOpacity: 0.8,
                  shadowRadius: 8,
                },
                thumbStyle,
              ]}
            />
          )}
        </View>
      </GestureDetector>
    </View>
  );
}
