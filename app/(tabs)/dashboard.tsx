import { View, Text, Pressable, Alert } from 'react-native';
import { useAuth } from '../../lib/auth';

export default function DashboardScreen() {
  const { signOut, session } = useAuth();

  const handleSignOut = () => {
    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Sign Out',
          style: 'destructive',
          onPress: () => signOut(),
        },
      ]
    );
  };

  return (
    <View className="flex-1 bg-background items-center justify-center px-4">
      <Text className="text-text-primary text-2xl font-josefin-semibold">
        Dashboard
      </Text>
      <Text className="text-text-secondary text-base font-josefin mt-2 mb-8">
        Saved readings coming in Phase 5
      </Text>

      {/* Temporary sign out — moves to Settings screen in Phase 6 */}
      <Text className="text-text-secondary text-sm font-josefin mb-2">
        {session?.user?.email}
      </Text>
      <Pressable
        onPress={handleSignOut}
        className="bg-surface border border-border rounded-xl px-6 py-3 active:opacity-80"
      >
        <Text className="text-destructive text-base font-josefin-semibold">
          Sign Out
        </Text>
      </Pressable>
    </View>
  );
}
