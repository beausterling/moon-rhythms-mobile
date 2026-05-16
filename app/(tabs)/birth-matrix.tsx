import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  Switch,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import DateTimePicker, {
  DateTimePickerEvent,
} from "@react-native-community/datetimepicker";
import {
  GooglePlaceData,
  GooglePlaceDetail,
  GooglePlacesAutocomplete,
  GooglePlacesAutocompleteRef,
} from "react-native-google-places-autocomplete";
import Ionicons from "@expo/vector-icons/Ionicons";
import { useRouter } from "expo-router";
import {
  ChartInput,
  fetchReadings,
  fetchTimezone,
  generateChart,
  saveBirthChartReading,
} from "../../lib/api";
import { Screen } from "../../components/ui/Screen";
import { Input } from "../../components/ui/Input";
import { GhostPillButton } from "../../components/ui/GhostPillButton";
import { NumericValue } from "../../components/ui/NumericValue";

const PLACES_KEY = process.env.EXPO_PUBLIC_GOOGLE_MAPS_API_KEY || "";

const HAIRLINE = "rgba(255,255,255,0.10)";
const STRONG = "rgba(255,255,255,0.35)";
const SURFACE_1 = "#0A0A0F";

type LocationPick = {
  label: string;
  lat: number;
  lng: number;
};

function pad(n: number) {
  return n.toString().padStart(2, "0");
}

function formatDateLabel(date: Date) {
  return date.toLocaleDateString(undefined, {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
}

function formatTimeLabel(date: Date) {
  return date.toLocaleTimeString(undefined, {
    hour: "numeric",
    minute: "2-digit",
  });
}

function toBirthdate(date: Date) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(
    date.getDate(),
  )}`;
}

function toBirthtime(date: Date) {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}:00`;
}

function TriggerField({
  icon,
  text,
  placeholder,
  onPress,
}: {
  icon: keyof typeof Ionicons.glyphMap;
  text: string | null;
  placeholder: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      style={{
        height: 52,
        backgroundColor: SURFACE_1,
        borderWidth: 1,
        borderColor: HAIRLINE,
        borderRadius: 12,
        paddingHorizontal: 16,
        flexDirection: "row",
        alignItems: "center",
      }}
    >
      <Ionicons name={icon} size={20} color="#8A8A90" />
      <Text
        className="font-josefin"
        style={{
          marginLeft: 12,
          color: text ? "#FFFFFF" : "#8A8A90",
          fontSize: 16,
        }}
      >
        {text || placeholder}
      </Text>
    </Pressable>
  );
}

function FieldLabel({ children }: { children: string }) {
  return (
    <Text
      className="font-josefin text-text-tertiary"
      style={{
        fontSize: 12,
        lineHeight: 16,
        letterSpacing: 2.16,
        textTransform: "uppercase",
        marginBottom: 8,
      }}
    >
      {children}
    </Text>
  );
}

function FieldError({ children }: { children: string }) {
  return (
    <Text
      className="text-destructive font-josefin"
      style={{ fontSize: 14, marginTop: 4 }}
    >
      {children}
    </Text>
  );
}

export default function BirthMatrixScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const placesRef = useRef<GooglePlacesAutocompleteRef | null>(null);

  const [name, setName] = useState("");
  const [date, setDate] = useState<Date | null>(null);
  const [time, setTime] = useState<Date | null>(null);
  const [timeUnknown, setTimeUnknown] = useState(false);
  const [location, setLocation] = useState<LocationPick | null>(null);
  const [tzLabel, setTzLabel] = useState<string | null>(null);

  const [showDatePicker, setShowDatePicker] = useState(false);
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [prefilling, setPrefilling] = useState(true);
  const [hasExisting, setHasExisting] = useState(false);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const readings = await fetchReadings("birth_chart");
        if (cancelled || !readings.length) return;
        setHasExisting(true);
        const latest = readings[0];
        const input = latest.input_data || {};
        if (input.name) setName(input.name);
        if (input.birthdate) {
          const [y, m, d] = input.birthdate.split("-").map(Number);
          if (y && m && d) setDate(new Date(y, m - 1, d));
        }
        if (input.birthtime) {
          const [h, mi] = input.birthtime.split(":").map(Number);
          const base = input.birthdate
            ? input.birthdate.split("-").map(Number)
            : [1990, 1, 1];
          setTime(new Date(base[0], base[1] - 1, base[2], h || 0, mi || 0));
        } else if (input.birthdate) {
          setTimeUnknown(true);
        }
        if (input.lat != null && input.lng != null && input.location) {
          const pick: LocationPick = {
            label: input.location,
            lat: Number(input.lat),
            lng: Number(input.lng),
          };
          setLocation(pick);
          placesRef.current?.setAddressText(input.location);
        }
        if (input.utc_offset) setTzLabel(input.utc_offset);
      } catch {
        // Non-fatal: user can still fill the form fresh.
      } finally {
        if (!cancelled) setPrefilling(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const resolveTimezone = useCallback(
    async (
      pick: LocationPick | null = location,
      d: Date | null = date,
    ): Promise<string | null> => {
      if (!pick || !d) return null;
      try {
        const tz = await fetchTimezone(pick.lat, pick.lng, toBirthdate(d));
        setTzLabel(tz.utcOffset);
        setErrors((prev) => ({ ...prev, submit: "" }));
        return tz.utcOffset;
      } catch (e) {
        setTzLabel(null);
        setErrors((prev) => ({
          ...prev,
          submit:
            e instanceof Error ? e.message : "Could not resolve timezone.",
        }));
        return null;
      }
    },
    [date, location],
  );

  const onDateChange = (_: DateTimePickerEvent, picked?: Date) => {
    if (Platform.OS !== "ios") setShowDatePicker(false);
    if (!picked) return;
    setDate(picked);
    setErrors((prev) => ({ ...prev, birthdate: "" }));
    void resolveTimezone(location, picked);
  };

  const onTimeChange = (_: DateTimePickerEvent, picked?: Date) => {
    if (Platform.OS !== "ios") setShowTimePicker(false);
    if (!picked) return;
    setTime(picked);
    setErrors((prev) => ({ ...prev, birthtime: "" }));
  };

  const onPlacePicked = (
    data: GooglePlaceData,
    details: GooglePlaceDetail | null,
  ) => {
    const lat = details?.geometry?.location?.lat;
    const lng = details?.geometry?.location?.lng;
    const label = details?.formatted_address || data.description || "";
    if (lat == null || lng == null) {
      setErrors((prev) => ({
        ...prev,
        location: "Pick a location from the dropdown.",
      }));
      return;
    }
    const pick = { label, lat, lng };
    setLocation(pick);
    setErrors((prev) => ({ ...prev, location: "" }));
    void resolveTimezone(pick, date);
  };

  const validate = (): string | null => {
    const next: Record<string, string> = {};
    if (!name.trim()) next.name = "Enter your name.";
    if (!date) next.birthdate = "Select a birth date.";
    if (!timeUnknown && !time) next.birthtime = "Select a birth time.";
    if (!location) next.location = "Pick a location from the dropdown.";
    setErrors(next);
    return Object.keys(next).length ? "Fix the highlighted fields." : null;
  };

  const handleSubmit = async () => {
    const failure = validate();
    if (failure) return;
    if (!date || !location) return;

    setSubmitting(true);
    try {
      const utcOffset =
        tzLabel || (await resolveTimezone(location, date)) || "UTC+00:00";

      const chartTime = timeUnknown ? "12:00:00" : toBirthtime(time as Date);
      const inputForChart: ChartInput = {
        name: name.trim(),
        birthdate: toBirthdate(date),
        birthtime: chartTime,
        location: location.label,
        lat: location.lat,
        lng: location.lng,
        utc_offset: utcOffset,
      };

      const chartData = await generateChart(inputForChart);
      const inputForSave: ChartInput = {
        ...inputForChart,
        birthtime: timeUnknown ? null : chartTime,
      };
      await saveBirthChartReading(inputForSave, chartData);
      setHasExisting(true);

      router.push("/dashboard");
    } catch (e) {
      setErrors((prev) => ({
        ...prev,
        submit: e instanceof Error ? e.message : "Something went wrong.",
      }));
    } finally {
      setSubmitting(false);
    }
  };

  const submitDisabled = useMemo(
    () => submitting || !name.trim() || !date || !location,
    [submitting, name, date, location],
  );

  return (
    <Screen>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : undefined}
      >
        <ScrollView
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={{
            paddingTop: 24,
            paddingHorizontal: 16,
            paddingBottom: 56 + insets.bottom + 24,
          }}
          showsVerticalScrollIndicator={false}
        >
          <Text
            className="text-white font-josefin-semibold"
            style={{ fontSize: 28, lineHeight: 34 }}
          >
            Birth Matrix
          </Text>
          <Text
            className="font-josefin mt-2"
            style={{ color: "#D4D4D8", fontSize: 16 }}
          >
            {prefilling
              ? "Loading your saved chart…"
              : "Enter your birth details to generate your natal chart."}
          </Text>

          {/* Name */}
          <View className="mt-6">
            <Input
              label="Name"
              value={name}
              onChangeText={(v) => {
                setName(v);
                setErrors((prev) => ({ ...prev, name: "" }));
              }}
              placeholder="Display name"
              autoCapitalize="words"
              error={errors.name || undefined}
            />
          </View>

          {/* Birth date */}
          <View className="mt-5">
            <FieldLabel>Birth date</FieldLabel>
            <TriggerField
              icon="calendar-outline"
              text={date ? formatDateLabel(date) : null}
              placeholder="Select date"
              onPress={() => setShowDatePicker(true)}
            />
            {!!errors.birthdate && <FieldError>{errors.birthdate}</FieldError>}
            {showDatePicker && (
              <View className="mt-2">
                <DateTimePicker
                  value={date ?? new Date(1990, 0, 1)}
                  mode="date"
                  display={Platform.OS === "ios" ? "spinner" : "default"}
                  maximumDate={new Date()}
                  onChange={onDateChange}
                  themeVariant="dark"
                />
                {Platform.OS === "ios" && (
                  <Pressable
                    onPress={() => setShowDatePicker(false)}
                    className="self-end mt-1"
                  >
                    <Text
                      className="text-white font-josefin-semibold"
                      style={{ fontSize: 14 }}
                    >
                      Done
                    </Text>
                  </Pressable>
                )}
              </View>
            )}
          </View>

          {/* Birth time */}
          <View className="mt-5">
            <View className="flex-row items-center justify-between mb-2">
              <FieldLabel>Birth time</FieldLabel>
              <View className="flex-row items-center" style={{ marginBottom: 8 }}>
                <Text
                  className="font-josefin text-text-tertiary mr-2"
                  style={{ fontSize: 12 }}
                >
                  Unknown
                </Text>
                <Switch
                  value={timeUnknown}
                  onValueChange={(v) => {
                    setTimeUnknown(v);
                    if (v) {
                      setTime(null);
                      setShowTimePicker(false);
                      setErrors((prev) => ({ ...prev, birthtime: "" }));
                    }
                  }}
                  trackColor={{ false: HAIRLINE, true: STRONG }}
                  thumbColor="#FFFFFF"
                  ios_backgroundColor={HAIRLINE}
                />
              </View>
            </View>
            {!timeUnknown && (
              <>
                <TriggerField
                  icon="time-outline"
                  text={time ? formatTimeLabel(time) : null}
                  placeholder="Select time"
                  onPress={() => setShowTimePicker(true)}
                />
                {!!errors.birthtime && <FieldError>{errors.birthtime}</FieldError>}
                {showTimePicker && (
                  <View className="mt-2">
                    <DateTimePicker
                      value={time ?? new Date(1990, 0, 1, 12, 0)}
                      mode="time"
                      display={Platform.OS === "ios" ? "spinner" : "default"}
                      onChange={onTimeChange}
                      themeVariant="dark"
                    />
                    {Platform.OS === "ios" && (
                      <Pressable
                        onPress={() => setShowTimePicker(false)}
                        className="self-end mt-1"
                      >
                        <Text
                          className="text-white font-josefin-semibold"
                          style={{ fontSize: 14 }}
                        >
                          Done
                        </Text>
                      </Pressable>
                    )}
                  </View>
                )}
              </>
            )}
            {timeUnknown && (
              <Text
                className="font-josefin text-text-tertiary"
                style={{ fontSize: 12 }}
              >
                Rising sign and houses will be omitted.
              </Text>
            )}
          </View>

          {/* Birth location */}
          <View className="mt-5" style={{ zIndex: 10 }}>
            <FieldLabel>Birth location</FieldLabel>
            <GooglePlacesAutocomplete
              ref={placesRef}
              placeholder="Search for city or town"
              fetchDetails
              onPress={onPlacePicked}
              query={{ key: PLACES_KEY, language: "en" }}
              enablePoweredByContainer={false}
              disableScroll
              keyboardShouldPersistTaps="handled"
              textInputProps={{
                placeholderTextColor: "#8A8A90",
              }}
              styles={{
                container: { flex: 0 },
                textInput: {
                  backgroundColor: SURFACE_1,
                  borderColor: HAIRLINE,
                  borderWidth: 1,
                  borderRadius: 12,
                  color: "#FFFFFF",
                  height: 52,
                  fontSize: 16,
                  fontFamily: "JosefinSans-Regular",
                  paddingHorizontal: 16,
                },
                listView: {
                  backgroundColor: SURFACE_1,
                  borderRadius: 12,
                  borderWidth: 1,
                  borderColor: HAIRLINE,
                  marginTop: 4,
                  overflow: "hidden",
                },
                row: {
                  backgroundColor: "transparent",
                  paddingVertical: 12,
                  paddingHorizontal: 16,
                },
                separator: {
                  backgroundColor: HAIRLINE,
                },
                description: {
                  color: "#FFFFFF",
                  fontFamily: "JosefinSans-Regular",
                },
                poweredContainer: { display: "none" },
              }}
            />
            {!!location && (
              <View className="mt-2 flex-row items-center">
                <Ionicons name="location" size={14} color="#FFFFFF" />
                <Text
                  className="font-josefin text-text-tertiary ml-1 flex-1"
                  style={{ fontSize: 12 }}
                  numberOfLines={1}
                >
                  {location.label}
                </Text>
                {!!tzLabel && (
                  <NumericValue size="sm" style={{ marginLeft: 8 }}>
                    {tzLabel}
                  </NumericValue>
                )}
              </View>
            )}
            {!!errors.location && <FieldError>{errors.location}</FieldError>}
          </View>

          {/* Submit */}
          {!!errors.submit && (
            <Text
              className="text-destructive font-josefin"
              style={{ fontSize: 14, marginTop: 20 }}
            >
              {errors.submit}
            </Text>
          )}

          <View style={{ marginTop: 24 }}>
            <GhostPillButton
              label={
                submitting
                  ? "Working…"
                  : hasExisting
                    ? "Save changes"
                    : "Save birth chart"
              }
              onPress={handleSubmit}
              disabled={submitDisabled}
            />
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </Screen>
  );
}
