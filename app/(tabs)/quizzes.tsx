import { ScrollView, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Ionicons from "@expo/vector-icons/Ionicons";
import { Screen } from "../../components/ui/Screen";
import { Card } from "../../components/ui/Card";

const QUIZZES = [
  {
    title: "MBTI",
    subtitle: "32 questions",
    description: "Explore how you tend to perceive, decide, and recharge.",
    icon: "sparkles-outline",
  },
  {
    title: "Big Five",
    subtitle: "50 questions",
    description:
      "Map openness, conscientiousness, extraversion, agreeableness, and neuroticism.",
    icon: "analytics-outline",
  },
  {
    title: "Enneagram",
    subtitle: "36 questions",
    description: "Find the motivation pattern behind your default reactions.",
    icon: "aperture-outline",
  },
  {
    title: "DISC",
    subtitle: "28 questions",
    description: "Understand your communication and collaboration style.",
    icon: "compass-outline",
  },
] as const;

const HAIRLINE = "rgba(255,255,255,0.10)";

export default function QuizzesScreen() {
  const insets = useSafeAreaInsets();

  return (
    <Screen>
      <ScrollView
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
          Quizzes
        </Text>
        <Text
          className="font-josefin mt-2"
          style={{ color: "#D4D4D8", fontSize: 16, lineHeight: 25 }}
        >
          Personality assessments will score on-device and sync when you are
          online.
        </Text>

        <View className="mt-6" style={{ gap: 16 }}>
          {QUIZZES.map((quiz) => (
            <Card key={quiz.title} style={{ opacity: 0.9 }}>
              <View className="flex-row items-start">
                <View
                  className="w-11 h-11 rounded-xl items-center justify-center mr-4"
                  style={{ backgroundColor: "rgba(255,255,255,0.06)" }}
                >
                  <Ionicons name={quiz.icon} size={22} color="#FFFFFF" />
                </View>
                <View className="flex-1">
                  <View className="flex-row items-center justify-between">
                    <Text className="text-white text-xl font-josefin-semibold">
                      {quiz.title}
                    </Text>
                    <Text
                      className="font-josefin text-text-tertiary"
                      style={{ fontSize: 13 }}
                    >
                      {quiz.subtitle}
                    </Text>
                  </View>
                  <Text
                    className="font-josefin mt-2"
                    style={{ color: "#D4D4D8", fontSize: 14, lineHeight: 21 }}
                  >
                    {quiz.description}
                  </Text>
                  <View className="flex-row items-center mt-4">
                    <View
                      className="px-3 py-1 rounded-full"
                      style={{ borderWidth: 1, borderColor: HAIRLINE }}
                    >
                      <Text
                        className="font-josefin text-text-tertiary"
                        style={{
                          fontSize: 11,
                          letterSpacing: 1.98,
                          textTransform: "uppercase",
                        }}
                      >
                        Phase 4
                      </Text>
                    </View>
                  </View>
                </View>
              </View>
            </Card>
          ))}
        </View>
      </ScrollView>
    </Screen>
  );
}
