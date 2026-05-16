import { useMemo, useState } from "react";
import {
  ActivityIndicator,
  Pressable,
  ScrollView,
  Switch,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { Image } from "expo-image";
import { useMoonLive } from "../../hooks/useMoonLive";
import { useTimeScrub } from "../../hooks/useTimeScrub";
import {
  getFrameFromAngle,
  getMoonFrameUri,
  getZodiacFromLongitude,
} from "../../lib/moon-calc";
import { Screen } from "../../components/ui/Screen";
import { NumericValue } from "../../components/ui/NumericValue";
import { GhostPillButton } from "../../components/ui/GhostPillButton";
import { TimeScrubberTrack } from "../../components/ui/TimeScrubberTrack";

const MOON_IMAGE_SIZE = 260;
const SCRUB_RANGE_MS = 72 * 60 * 60 * 1000; // ±3 days
const SYMBOL_FONT_FAMILY = "Apple Symbols";
const TEXT_VARIATION_SELECTOR = "︎";
const HAIRLINE = "rgba(255,255,255,0.10)";

const ORDINAL_RE = /(\d+)(st|nd|rd|th)?$/;

function ordinal(n: number) {
  const v = n % 100;
  if (v >= 11 && v <= 13) return `${n}th`;
  switch (n % 10) {
    case 1:
      return `${n}st`;
    case 2:
      return `${n}nd`;
    case 3:
      return `${n}rd`;
    default:
      return `${n}th`;
  }
}

/**
 * "Saturday, May 16th 12:45:14 AM"
 */
function formatLiveTime(date: Date) {
  const weekday = date.toLocaleDateString("en-US", { weekday: "long" });
  const month = date.toLocaleDateString("en-US", { month: "long" });
  const day = ordinal(date.getDate());
  const time = date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    second: "2-digit",
    hour12: true,
  });
  return `${weekday}, ${month} ${day} ${time}`.replace(ORDINAL_RE, (m) => m);
}

function formatLongitude(deg: number) {
  return `${deg.toFixed(6)}°`;
}

function formatDistance(km: number) {
  return `${km.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ",")} km`;
}

export default function HomeScreen() {
  const insets = useSafeAreaInsets();
  const [showDetails, setShowDetails] = useState(false);

  const scrub = useTimeScrub({ rangeHours: 72, intervalHours: 2 });
  const live = useMoonLive(scrub.isScrubbingRef);

  const isScrubbing = scrub.isScrubbing;
  const sd = scrub.scrubDisplayData;
  const server = live.server;

  // Active display lon/angle/illum — live (rAF-extrapolated) or scrub-interpolated
  const display = useMemo(() => {
    if (isScrubbing && sd) {
      return {
        lon: sd.moonLongitude,
        angle: sd.moonPhase.angle,
        illum: sd.illuminationPercent,
      };
    }
    return live.display;
  }, [isScrubbing, sd, live.display, live.tick]); // eslint-disable-line react-hooks/exhaustive-deps

  // Active sample (for fields that don't extrapolate: distance, altitude, etc.)
  const sample = isScrubbing && sd ? sd : server;

  // Active timestamp
  const displayedTime = useMemo(() => {
    if (isScrubbing && sd) return new Date(sd.timestamp);
    return new Date(Date.now());
    // re-evaluated every tick (live.tick is in `display`'s deps above)
  }, [isScrubbing, sd, live.tick]); // eslint-disable-line react-hooks/exhaustive-deps

  // Loading / error gates
  if (live.isLoading && !display) {
    return (
      <Screen starfield>
        <View className="flex-1 items-center justify-center">
          <ActivityIndicator color="#FFFFFF" />
          <Text
            className="font-josefin mt-4"
            style={{ color: "#D4D4D8", fontSize: 14 }}
          >
            Locating the Moon…
          </Text>
        </View>
      </Screen>
    );
  }

  if (live.error && !display) {
    return (
      <Screen starfield>
        <View className="flex-1 items-center justify-center px-8">
          <Text
            className="text-white font-josefin-semibold mb-2"
            style={{ fontSize: 20 }}
          >
            Unable to reach the sky
          </Text>
          <Text
            className="font-josefin text-center mb-6"
            style={{ color: "#D4D4D8", fontSize: 14 }}
          >
            {live.error}
          </Text>
          <View style={{ minWidth: 200 }}>
            <GhostPillButton
              label="Try again"
              onPress={() => void live.refresh()}
              shimmer={false}
            />
          </View>
        </View>
      </Screen>
    );
  }

  if (!display) return null;

  const zodiac = getZodiacFromLongitude(display.lon);
  const frameUri = getMoonFrameUri(getFrameFromAngle(display.angle));

  return (
    <Screen starfield>
      <ScrollView
        contentContainerStyle={{
          paddingTop: 8,
          paddingBottom: 56 + insets.bottom + 24,
          alignItems: "center",
        }}
        showsVerticalScrollIndicator={false}
      >
        {/* Stale banner */}
        {live.isStale && !isScrubbing && (
          <Pressable onPress={() => void live.refresh()} className="mx-8 mb-3">
            <View
              style={{
                paddingHorizontal: 16,
                paddingVertical: 8,
                borderRadius: 999,
                borderWidth: 1,
                borderColor: "rgba(255,255,255,0.35)",
              }}
            >
              <Text
                className="font-josefin text-center text-white"
                style={{
                  fontSize: 12,
                  textShadowColor: "rgba(255,255,255,0.25)",
                  textShadowOffset: { width: 0, height: 0 },
                  textShadowRadius: 8,
                }}
              >
                Showing cached data · Tap to retry
              </Text>
            </View>
          </Pressable>
        )}

        {/* Moon image */}
        <View
          className="overflow-hidden"
          style={{
            width: MOON_IMAGE_SIZE,
            height: MOON_IMAGE_SIZE,
            borderRadius: MOON_IMAGE_SIZE / 2,
            marginTop: 8,
          }}
        >
          <Image
            source={{ uri: frameUri }}
            style={{ width: MOON_IMAGE_SIZE, height: MOON_IMAGE_SIZE }}
            contentFit="cover"
            cachePolicy="memory-disk"
            transition={120}
          />
        </View>

        {/* Live (or scrubbed) date+time */}
        <Text
          className="font-josefin text-white mt-6"
          style={{
            fontSize: 16,
            textShadowColor: "rgba(255,255,255,0.25)",
            textShadowOffset: { width: 0, height: 0 },
            textShadowRadius: 8,
          }}
        >
          {formatLiveTime(displayedTime)}
        </Text>

        {/* Scrubber */}
        <View style={{ width: "100%", marginTop: 12, marginBottom: 4 }}>
          <TimeScrubberTrack
            rangeMs={SCRUB_RANGE_MS}
            offsetMs={scrub.scrubOffsetMs}
            isScrubbing={isScrubbing}
            onScrubStart={scrub.startScrub}
            onScrubUpdate={scrub.updateScrubOffset}
          />
        </View>

        {/* Snap-to-live button — only while scrubbing */}
        {isScrubbing && (
          <Pressable onPress={scrub.snapToLive} className="mt-1 mb-2">
            <Text
              className="font-josefin text-text-tertiary"
              style={{
                fontSize: 11,
                letterSpacing: 1.98,
                textTransform: "uppercase",
              }}
            >
              Tap for Now
            </Text>
          </Pressable>
        )}

        {/* Zodiac + arcseconds — transparent panel, stars visible through it */}
        <View
          style={{
            width: "100%",
            paddingHorizontal: 16,
            marginTop: 12,
          }}
        >
          <View
            style={{
              backgroundColor: "rgba(0,0,0,0.35)",
              borderRadius: 20,
              borderWidth: 1,
              borderColor: HAIRLINE,
              padding: 20,
            }}
          >
            <View style={{ alignItems: "center" }}>
              <View
                className="flex-row items-center"
                style={{ marginBottom: 4 }}
              >
                <Text
                  style={{
                    fontSize: 32,
                    lineHeight: 38,
                    color: "#FFFFFF",
                    fontFamily: SYMBOL_FONT_FAMILY,
                    textShadowColor: "rgba(255,255,255,0.6)",
                    textShadowOffset: { width: 0, height: 0 },
                    textShadowRadius: 12,
                    marginRight: 12,
                  }}
                >
                  {zodiac.symbol}
                  {TEXT_VARIATION_SELECTOR}
                </Text>
                <Text
                  className="text-white font-josefin-semibold"
                  style={{
                    fontSize: 26,
                    textShadowColor: "rgba(255,255,255,0.25)",
                    textShadowOffset: { width: 0, height: 0 },
                    textShadowRadius: 8,
                  }}
                >
                  {zodiac.name}
                </Text>
              </View>
              <NumericValue size="md" emphasis>
                {zodiac.degrees}°{" "}
                {String(zodiac.minutes).padStart(2, "0")}'{" "}
                {String(zodiac.seconds).padStart(2, "0")}"
              </NumericValue>
            </View>

            {/* Divider */}
            <View
              style={{
                height: 1,
                backgroundColor: HAIRLINE,
                marginTop: 16,
                marginBottom: 12,
              }}
            />

            {/* Detailed data toggle */}
            <View
              className="flex-row items-center justify-center"
              style={{ paddingVertical: 4, gap: 12 }}
            >
              <Text
                className="font-josefin text-text-tertiary"
                style={{
                  fontSize: 12,
                  lineHeight: 16,
                  letterSpacing: 2.16,
                  textTransform: "uppercase",
                }}
              >
                Detailed data
              </Text>
              <Switch
                value={showDetails}
                onValueChange={setShowDetails}
                trackColor={{ false: HAIRLINE, true: "rgba(255,255,255,0.35)" }}
                thumbColor="#FFFFFF"
                ios_backgroundColor={HAIRLINE}
              />
            </View>

            {showDetails && (
              <View style={{ marginTop: 16, gap: 10 }}>
                <DetailRow
                  label="Phase"
                  value={
                    <Text
                      className="font-josefin text-white"
                      style={{ fontSize: 13 }}
                    >
                      {sample?.moonPhase?.name ?? "—"}
                    </Text>
                  }
                />
                <DetailRow
                  label="Phase angle"
                  value={
                    <NumericValue size="sm">
                      {display.angle.toFixed(4)}°
                    </NumericValue>
                  }
                />
                <DetailRow
                  label="Longitude"
                  value={
                    <NumericValue size="sm">
                      {formatLongitude(display.lon)}
                    </NumericValue>
                  }
                />
                {sample?.moonLatitude != null && (
                  <DetailRow
                    label="Latitude"
                    value={
                      <NumericValue size="sm">
                        {sample.moonLatitude.toFixed(6)}°
                      </NumericValue>
                    }
                  />
                )}
                {sample?.moonDistanceKm != null && (
                  <DetailRow
                    label="Distance"
                    value={
                      <NumericValue size="sm">
                        {formatDistance(sample.moonDistanceKm)}
                      </NumericValue>
                    }
                  />
                )}
                <DetailRow
                  label="Illumination"
                  value={
                    <NumericValue size="sm">
                      {display.illum.toFixed(2)}%
                    </NumericValue>
                  }
                />
                {sample?.phaseDaysPast != null && (
                  <DetailRow
                    label="Lunation age"
                    value={
                      <NumericValue size="sm">
                        {sample.phaseDaysPast.toFixed(2)} days
                      </NumericValue>
                    }
                  />
                )}
                {sample?.altitude ? (
                  <>
                    <DetailRow
                      label="Altitude"
                      value={
                        <NumericValue size="sm">
                          {sample.altitude.apparentAltitude.toFixed(2)}°
                        </NumericValue>
                      }
                    />
                    <DetailRow
                      label="Azimuth"
                      value={
                        <NumericValue size="sm">
                          {sample.altitude.azimuth.toFixed(2)}°
                        </NumericValue>
                      }
                    />
                  </>
                ) : null}
                {sample?.source && (
                  <DetailRow
                    label="Source"
                    value={
                      <Text
                        className="font-josefin text-text-tertiary"
                        style={{ fontSize: 11 }}
                        numberOfLines={1}
                      >
                        {sample.source}
                      </Text>
                    }
                  />
                )}
              </View>
            )}
          </View>
        </View>
      </ScrollView>
    </Screen>
  );
}

function DetailRow({
  label,
  value,
}: {
  label: string;
  value: React.ReactNode;
}) {
  return (
    <View style={{ paddingVertical: 2 }}>
      <Text
        className="font-josefin text-text-tertiary"
        style={{
          fontSize: 10,
          letterSpacing: 1.8,
          textTransform: "uppercase",
          marginBottom: 2,
        }}
        numberOfLines={1}
      >
        {label}
      </Text>
      <View>{value}</View>
    </View>
  );
}
