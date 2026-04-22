import { View, Text } from 'react-native';

export default function QuizzesScreen() {
  return (
    <View className="flex-1 bg-background items-center justify-center">
      <Text className="text-text-primary text-2xl font-josefin-semibold">
        Quizzes
      </Text>
      <Text className="text-text-secondary text-base font-josefin mt-2">
        Personality assessments coming in Phase 4
      </Text>
    </View>
  );
}
