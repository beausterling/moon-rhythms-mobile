import { View, Text, ScrollView, Pressable } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Ionicons from '@expo/vector-icons/Ionicons';

const QUIZZES = [
  {
    title: 'MBTI',
    subtitle: '32 questions',
    description: 'Explore how you tend to perceive, decide, and recharge.',
    icon: 'sparkles-outline',
  },
  {
    title: 'Big Five',
    subtitle: '50 questions',
    description: 'Map openness, conscientiousness, extraversion, agreeableness, and neuroticism.',
    icon: 'analytics-outline',
  },
  {
    title: 'Enneagram',
    subtitle: '36 questions',
    description: 'Find the motivation pattern behind your default reactions.',
    icon: 'aperture-outline',
  },
  {
    title: 'DISC',
    subtitle: '28 questions',
    description: 'Understand your communication and collaboration style.',
    icon: 'compass-outline',
  },
] as const;

export default function QuizzesScreen() {
  const insets = useSafeAreaInsets();

  return (
    <View className="flex-1 bg-background">
      <ScrollView
        contentContainerStyle={{
          paddingTop: insets.top + 24,
          paddingHorizontal: 16,
          paddingBottom: 56 + insets.bottom + 24,
        }}
        showsVerticalScrollIndicator={false}
      >
        <Text className="text-text-primary font-josefin-semibold" style={{ fontSize: 28, lineHeight: 34 }}>
          Quizzes
        </Text>
        <Text className="text-text-secondary text-base font-josefin mt-2">
          Personality assessments will score on-device and sync when you are online.
        </Text>

        <View className="mt-6 gap-4">
          {QUIZZES.map((quiz) => (
            <Pressable
              key={quiz.title}
              disabled
              className="bg-surface border border-border rounded-xl p-4"
              style={{ opacity: 0.9 }}
            >
              <View className="flex-row items-start">
                <View
                  className="w-11 h-11 rounded-xl items-center justify-center mr-4"
                  style={{ backgroundColor: 'rgba(0,255,65,0.1)' }}
                >
                  <Ionicons name={quiz.icon} size={22} color="#00ff41" />
                </View>
                <View className="flex-1">
                  <View className="flex-row items-center justify-between">
                    <Text className="text-text-primary text-xl font-josefin-semibold">
                      {quiz.title}
                    </Text>
                    <Text className="text-text-secondary text-sm font-josefin">
                      {quiz.subtitle}
                    </Text>
                  </View>
                  <Text className="text-text-secondary text-sm font-josefin mt-2 leading-5">
                    {quiz.description}
                  </Text>
                  <View className="flex-row items-center mt-4">
                    <View className="px-3 py-1 rounded-full border border-border">
                      <Text className="text-text-secondary text-xs font-josefin">
                        Phase 4
                      </Text>
                    </View>
                  </View>
                </View>
              </View>
            </Pressable>
          ))}
        </View>
      </ScrollView>
    </View>
  );
}
