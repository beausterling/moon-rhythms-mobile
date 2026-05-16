import { Tabs } from "expo-router";
import { StyleSheet, View } from "react-native";
import { BlurView } from "expo-blur";
import Ionicons from "@expo/vector-icons/Ionicons";

function GlowIcon({
  name,
  focused,
  color,
}: {
  name: keyof typeof Ionicons.glyphMap;
  focused: boolean;
  color: string;
}) {
  return (
    <View
      style={
        focused
          ? {
              shadowColor: "#FFFFFF",
              shadowOffset: { width: 0, height: 0 },
              shadowOpacity: 0.4,
              shadowRadius: 6,
            }
          : undefined
      }
    >
      <Ionicons name={name} size={24} color={color} />
    </View>
  );
}

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: "#FFFFFF",
        tabBarInactiveTintColor: "#8A8A90",
        tabBarStyle: {
          backgroundColor: "rgba(0, 0, 0, 0.6)",
          borderTopColor: "rgba(255, 255, 255, 0.08)",
          borderTopWidth: 1,
          height: 56,
          position: "absolute",
        },
        tabBarBackground: () => (
          <BlurView
            tint="dark"
            intensity={40}
            style={StyleSheet.absoluteFill}
          />
        ),
        tabBarLabelStyle: {
          fontFamily: "JosefinSans-Regular",
          fontSize: 12,
        },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "Home",
          tabBarIcon: ({ focused, color }) => (
            <GlowIcon
              name={focused ? "moon" : "moon-outline"}
              focused={focused}
              color={color}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="birth-matrix"
        options={{
          title: "Birth Matrix",
          tabBarIcon: ({ focused, color }) => (
            <GlowIcon
              name={focused ? "compass" : "compass-outline"}
              focused={focused}
              color={color}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="chat"
        options={{
          title: "Chat",
          tabBarIcon: ({ focused, color }) => (
            <GlowIcon
              name={focused ? "chatbubbles" : "chatbubbles-outline"}
              focused={focused}
              color={color}
            />
          ),
        }}
      />
      <Tabs.Screen
        name="quizzes"
        options={{
          href: null,
        }}
      />
      <Tabs.Screen
        name="dashboard"
        options={{
          title: "Dashboard",
          tabBarIcon: ({ focused, color }) => (
            <GlowIcon
              name={focused ? "grid" : "grid-outline"}
              focused={focused}
              color={color}
            />
          ),
        }}
      />
    </Tabs>
  );
}
