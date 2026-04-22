import { View, Text } from 'react-native';

export default function HomeScreen() {
  return (
    <View className="flex-1 bg-background items-center justify-center">
      <Text className="text-text-primary text-2xl font-josefin-semibold">
        Home
      </Text>
      <Text className="text-text-secondary text-base font-josefin mt-2">
        Moon data coming in Phase 2
      </Text>
    </View>
  );
}
