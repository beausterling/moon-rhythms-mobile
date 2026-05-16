import { useCallback, useMemo, useState } from "react";
import { useFocusEffect } from "expo-router";
import {
  ActivityIndicator,
  Alert,
  Pressable,
  RefreshControl,
  ScrollView,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Ionicons from "@expo/vector-icons/Ionicons";
import { useRouter } from "expo-router";
import { useAuth } from "../../lib/auth";
import { fetchReadings, SavedReading } from "../../lib/api";
import { Screen } from "../../components/ui/Screen";
import { Card } from "../../components/ui/Card";
import { DataRow } from "../../components/ui/DataRow";
import { NumericValue } from "../../components/ui/NumericValue";
import { GhostPillButton } from "../../components/ui/GhostPillButton";

// Force text-style rendering so iOS doesn't substitute color emoji.
const TEXT_VARIATION_SELECTOR = "︎";
const SYMBOL_FONT_FAMILY = "Apple Symbols";

const ZODIAC_GLYPHS: Record<string, string> = {
  Aries: "♈",
  Taurus: "♉",
  Gemini: "♊",
  Cancer: "♋",
  Leo: "♌",
  Virgo: "♍",
  Libra: "♎",
  Scorpio: "♏",
  Sagittarius: "♐",
  Capricorn: "♑",
  Aquarius: "♒",
  Pisces: "♓",
};

const ZODIAC_SIGNS = [
  "Aries",
  "Taurus",
  "Gemini",
  "Cancer",
  "Leo",
  "Virgo",
  "Libra",
  "Scorpio",
  "Sagittarius",
  "Capricorn",
  "Aquarius",
  "Pisces",
] as const;

type Placement = {
  label: string;
  sign: string;
  glyph: string;
  positionLabel: string | null;
};

function signFromLongitude(lon?: number): string | null {
  if (lon == null || Number.isNaN(lon)) return null;
  const norm = ((lon % 360) + 360) % 360;
  return ZODIAC_SIGNS[Math.floor(norm / 30)];
}

function positionInSign(lon?: number): number | null {
  if (lon == null || Number.isNaN(lon)) return null;
  const norm = ((lon % 360) + 360) % 360;
  return norm % 30;
}

function formatPosition(p: { degrees?: number; minutes?: number } | null) {
  if (!p) return null;
  if (p.degrees == null) return null;
  return `${p.degrees}°${p.minutes != null ? ` ${p.minutes}'` : ""}`;
}

function buildPlacements(reading: SavedReading | null): Placement[] {
  if (!reading?.result_data) return [];
  const data = reading.result_data;
  const planets = data.planets || [];
  const out: Placement[] = [];

  const sun = planets.find((p) => p.key === "sun");
  if (sun?.sign) {
    out.push({
      label: "Sun",
      sign: sun.sign,
      glyph: ZODIAC_GLYPHS[sun.sign] || "",
      positionLabel: formatPosition(sun.positionDMS ?? null),
    });
  }

  const moon = planets.find((p) => p.key === "moon");
  if (moon?.sign) {
    out.push({
      label: "Moon",
      sign: moon.sign,
      glyph: ZODIAC_GLYPHS[moon.sign] || "",
      positionLabel: formatPosition(moon.positionDMS ?? null),
    });
  }

  const ascSign = signFromLongitude(data.ascendant);
  if (ascSign && reading.input_data?.birthtime) {
    const ascPos = positionInSign(data.ascendant);
    out.push({
      label: "Rising",
      sign: ascSign,
      glyph: ZODIAC_GLYPHS[ascSign] || "",
      positionLabel:
        ascPos != null
          ? `${Math.floor(ascPos)}° ${Math.floor((ascPos % 1) * 60)}'`
          : null,
    });
  }

  return out;
}

function formatReadingDate(iso: string) {
  try {
    return new Date(iso).toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  } catch {
    return iso;
  }
}

export default function DashboardScreen() {
  const { signOut, session } = useAuth();
  const insets = useSafeAreaInsets();
  const router = useRouter();

  const [readings, setReadings] = useState<SavedReading[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setError(null);
      const data = await fetchReadings("birth_chart");
      setReadings(data);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to load readings.");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );

  const onRefresh = useCallback(() => {
    setRefreshing(true);
    void load();
  }, [load]);

  const latest = readings && readings.length > 0 ? readings[0] : null;
  const placements = useMemo(() => buildPlacements(latest), [latest]);

  const handleSignOut = () => {
    Alert.alert("Sign Out", "Are you sure you want to sign out?", [
      { text: "Cancel", style: "cancel" },
      {
        text: "Sign Out",
        style: "destructive",
        onPress: () => signOut(),
      },
    ]);
  };

  return (
    <Screen>
      <ScrollView
        contentContainerStyle={{
          paddingTop: 24,
          paddingHorizontal: 16,
          paddingBottom: 56 + insets.bottom + 24,
        }}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor="#FFFFFF"
          />
        }
      >
        <Text
          className="text-white font-josefin-semibold"
          style={{ fontSize: 28, lineHeight: 34 }}
        >
          Dashboard
        </Text>
        <Text
          className="font-josefin mt-2"
          style={{ color: "#D4D4D8", fontSize: 16 }}
        >
          Your astrology, at a glance.
        </Text>

        {loading && !readings && (
          <View className="items-center mt-12">
            <ActivityIndicator color="#FFFFFF" />
            <Text
              className="font-josefin mt-3"
              style={{ color: "#D4D4D8", fontSize: 14 }}
            >
              Loading readings…
            </Text>
          </View>
        )}

        {error && !loading && (
          <View className="mt-6">
            <Text
              className="text-destructive font-josefin"
              style={{ fontSize: 14 }}
            >
              {error}
            </Text>
            <Pressable onPress={() => void load()} className="mt-2">
              <Text
                className="text-white font-josefin-semibold"
                style={{ fontSize: 14 }}
              >
                Try again
              </Text>
            </Pressable>
          </View>
        )}

        {!loading && readings && readings.length === 0 && (
          <Card style={{ marginTop: 24 }}>
            <View
              className="w-12 h-12 rounded-xl items-center justify-center mb-4"
              style={{ backgroundColor: "rgba(255,255,255,0.06)" }}
            >
              <Ionicons name="compass-outline" size={24} color="#FFFFFF" />
            </View>
            <Text className="text-white text-xl font-josefin-semibold">
              No chart yet
            </Text>
            <Text
              className="font-josefin mt-2 leading-5"
              style={{ color: "#D4D4D8", fontSize: 14 }}
            >
              Add your birth details on the Birth Matrix tab to generate your
              natal chart.
            </Text>
            <View className="mt-4">
              <GhostPillButton
                label="Open Birth Matrix"
                onPress={() => router.push("/birth-matrix")}
                shimmer={false}
              />
            </View>
          </Card>
        )}

        {placements.length > 0 && (
          <View className="mt-6">
            <Text
              className="font-josefin text-text-tertiary mb-3"
              style={{
                fontSize: 12,
                letterSpacing: 2.16,
                textTransform: "uppercase",
              }}
            >
              Core placements
            </Text>
            <View className="flex-row" style={{ gap: 12 }}>
              {placements.map((p) => (
                <View key={p.label} style={{ flex: 1 }}>
                  <Card padding={16} style={{ alignItems: "center" }}>
                    <Text
                      className="font-josefin text-text-tertiary"
                      style={{
                        fontSize: 12,
                        letterSpacing: 2.16,
                        textTransform: "uppercase",
                      }}
                    >
                      {p.label}
                    </Text>
                    <Text
                      style={{
                        fontSize: 36,
                        lineHeight: 44,
                        color: "#FFFFFF",
                        marginTop: 4,
                        fontFamily: SYMBOL_FONT_FAMILY,
                        textShadowColor: "rgba(255,255,255,0.6)",
                        textShadowOffset: { width: 0, height: 0 },
                        textShadowRadius: 12,
                      }}
                    >
                      {p.glyph}
                      {TEXT_VARIATION_SELECTOR}
                    </Text>
                    <Text className="text-white text-sm font-josefin-semibold mt-1">
                      {p.sign}
                    </Text>
                    {!!p.positionLabel && (
                      <NumericValue size="sm" style={{ marginTop: 2 }}>
                        {p.positionLabel}
                      </NumericValue>
                    )}
                  </Card>
                </View>
              ))}
            </View>
          </View>
        )}

        {latest?.input_data && (
          <View style={{ marginTop: 20 }}>
            <Card>
              <Text
                className="font-josefin text-text-tertiary mb-3"
                style={{
                  fontSize: 12,
                  letterSpacing: 2.16,
                  textTransform: "uppercase",
                }}
              >
                Birth details
              </Text>
              {!!latest.input_data.name && (
                <Text className="text-white text-base font-josefin-semibold mb-2">
                  {latest.input_data.name}
                </Text>
              )}
              {!!latest.input_data.birthdate && (
                <DataRow label="Date">
                  <NumericValue size="md">
                    {latest.input_data.birthdate}
                  </NumericValue>
                </DataRow>
              )}
              <DataRow label="Time">
                {latest.input_data.birthtime ? (
                  <NumericValue size="md">
                    {latest.input_data.birthtime.slice(0, 5)}
                  </NumericValue>
                ) : (
                  <Text
                    className="font-josefin text-text-tertiary"
                    style={{ fontSize: 14 }}
                  >
                    Unknown
                  </Text>
                )}
              </DataRow>
              {!!latest.input_data.location && (
                <View
                  className="flex-row justify-between items-center"
                  style={{ paddingVertical: 8 }}
                >
                  <Text
                    className="font-josefin text-text-tertiary"
                    style={{
                      fontSize: 12,
                      letterSpacing: 2.16,
                      textTransform: "uppercase",
                    }}
                  >
                    Location
                  </Text>
                  <Text
                    className="font-josefin text-white text-right flex-shrink"
                    style={{ fontSize: 14, maxWidth: "70%" }}
                    numberOfLines={1}
                  >
                    {latest.input_data.location}
                  </Text>
                </View>
              )}
              <Pressable
                onPress={() => router.push("/birth-matrix")}
                className="mt-3 self-start"
              >
                <Text
                  className="text-white font-josefin-semibold"
                  style={{ fontSize: 14 }}
                >
                  Edit
                </Text>
              </Pressable>
            </Card>
          </View>
        )}

        {readings && readings.length > 0 && (
          <View className="mt-6">
            <Text
              className="font-josefin text-text-tertiary mb-3"
              style={{
                fontSize: 12,
                letterSpacing: 2.16,
                textTransform: "uppercase",
              }}
            >
              Recent readings
            </Text>
            <View style={{ gap: 12 }}>
              {readings.map((reading) => (
                <View
                  key={reading.id}
                  className="bg-surface-1 rounded-xl px-4 py-3 flex-row items-center"
                  style={{
                    borderWidth: 1,
                    borderColor: "rgba(255,255,255,0.10)",
                  }}
                >
                  <View
                    className="w-10 h-10 rounded-xl items-center justify-center mr-3"
                    style={{ backgroundColor: "rgba(255,255,255,0.06)" }}
                  >
                    <Ionicons
                      name="radio-button-on-outline"
                      size={20}
                      color="#FFFFFF"
                    />
                  </View>
                  <View className="flex-1">
                    <Text className="text-white text-base font-josefin-semibold">
                      Natal Chart
                    </Text>
                    <NumericValue size="sm" style={{ marginTop: 4 }}>
                      {formatReadingDate(reading.created_at)}
                    </NumericValue>
                  </View>
                  <Ionicons
                    name="chevron-forward"
                    size={18}
                    color="#8A8A90"
                  />
                </View>
              ))}
            </View>
          </View>
        )}

        {/* Temporary sign out - moves to Settings screen in Phase 6 */}
        <View
          style={{
            marginTop: 32,
            paddingTop: 24,
            borderTopWidth: 1,
            borderTopColor: "rgba(255,255,255,0.10)",
          }}
        >
          <Text
            className="font-josefin mb-3"
            style={{ color: "#D4D4D8", fontSize: 14 }}
          >
            {session?.user?.email}
          </Text>
          <Pressable
            onPress={handleSignOut}
            style={({ pressed }) => ({
              height: 56,
              borderRadius: 28,
              borderWidth: 1,
              borderColor: "rgba(239,68,68,0.6)",
              backgroundColor: "transparent",
              alignItems: "center",
              justifyContent: "center",
              opacity: pressed ? 0.85 : 1,
              transform: [{ scale: pressed ? 0.98 : 1 }],
            })}
          >
            <Text
              className="font-josefin-semibold"
              style={{
                color: "#EF4444",
                fontSize: 18,
                letterSpacing: 0.3,
              }}
            >
              Sign out
            </Text>
          </Pressable>
        </View>
      </ScrollView>
    </Screen>
  );
}
