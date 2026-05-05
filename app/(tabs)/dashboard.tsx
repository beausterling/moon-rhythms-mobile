import { View, Text, Pressable, Alert, ScrollView } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Ionicons from '@expo/vector-icons/Ionicons';
import { useAuth } from '../../lib/auth';

const READING_TYPES = [
  {
    title: 'Natal Chart',
    subtitle: 'Birth matrix and chart wheel',
    icon: 'radio-button-on-outline',
  },
  {
    title: 'Human Design',
    subtitle: 'Bodygraph view opens in-app',
    icon: 'body-outline',
  },
  {
    title: 'Quiz Results',
    subtitle: 'Personality assessments',
    icon: 'help-circle-outline',
  },
] as const;

export default function DashboardScreen() {
  const { signOut, session } = useAuth();
  const insets = useSafeAreaInsets();

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
          Dashboard
        </Text>
        <Text className="text-text-secondary text-base font-josefin mt-2">
          Saved readings and quiz results will collect here.
        </Text>

        <View className="bg-surface border border-border rounded-xl p-5 mt-6">
          <View
            className="w-12 h-12 rounded-xl items-center justify-center mb-4"
            style={{ backgroundColor: 'rgba(0,255,65,0.1)' }}
          >
            <Ionicons name="folder-open-outline" size={24} color="#00ff41" />
          </View>
          <Text className="text-text-primary text-xl font-josefin-semibold">
            No saved readings yet
          </Text>
          <Text className="text-text-secondary text-sm font-josefin mt-2 leading-5">
            Birth charts, Human Design readings, and quiz results will appear here once those screens are connected.
          </Text>
        </View>

        <Text className="text-text-secondary text-sm font-josefin mt-8 mb-3">
          Planned library
        </Text>
        <View className="gap-3">
          {READING_TYPES.map((reading) => (
            <View
              key={reading.title}
              className="bg-surface border border-border rounded-xl px-4 py-3 flex-row items-center"
            >
              <View
                className="w-10 h-10 rounded-xl items-center justify-center mr-3"
                style={{ backgroundColor: 'rgba(136,136,170,0.12)' }}
              >
                <Ionicons name={reading.icon} size={20} color="#8888aa" />
              </View>
              <View className="flex-1">
                <Text className="text-text-primary text-base font-josefin-semibold">
                  {reading.title}
                </Text>
                <Text className="text-text-secondary text-sm font-josefin mt-1">
                  {reading.subtitle}
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={18} color="#8888aa" />
            </View>
          ))}
        </View>

        {/* Temporary sign out - moves to Settings screen in Phase 6 */}
        <View className="border-t border-border mt-8 pt-6">
          <Text className="text-text-secondary text-sm font-josefin mb-3">
            {session?.user?.email}
          </Text>
          <Pressable
            onPress={handleSignOut}
            className="h-[52px] bg-surface border border-border rounded-xl items-center justify-center active:opacity-80"
          >
            <Text className="text-destructive text-base font-josefin-semibold">
              Sign Out
            </Text>
          </Pressable>
        </View>
      </ScrollView>
    </View>
  );
}
