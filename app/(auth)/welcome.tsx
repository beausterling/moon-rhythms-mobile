import { useCallback } from "react";
import { View, Text } from "react-native";
import { useFocusEffect, useRouter } from "expo-router";
import { useVideoPlayer, VideoView } from "expo-video";
import { NightSky } from "../../components/NightSky";
import { GhostPillButton } from "../../components/ui/GhostPillButton";
import { TextLink } from "../../components/ui/TextLink";

// Looping moon-phase animation, bundled locally (no network). One synodic month
// (712 frames @ 24fps, ~30s) encoded as H.264 — hardware-decoded with constant
// memory, so it runs reliably for as long as the welcome screen stays open.
const MOON_LOOP = require("../../assets/moon-loop.mp4");

export default function WelcomeScreen() {
  const router = useRouter();

  const player = useVideoPlayer(MOON_LOOP, (p) => {
    p.loop = true;
    p.muted = true;
    p.play();
  });

  // Pause while the screen isn't focused (behind Sign in/up), resume on return.
  useFocusEffect(
    useCallback(() => {
      player.play();
      return () => player.pause();
    }, [player]),
  );

  return (
    <View className="flex-1 bg-black items-center justify-center">
      <NightSky />

      <View className="items-center px-8 w-full">
        {/* Moon loop — 240px diameter circle, video slightly oversized + offset
            to match the previous framed look (cover crop). */}
        <View
          className="overflow-hidden"
          style={{
            width: 240,
            height: 240,
            borderRadius: 120,
            backgroundColor: "transparent",
          }}
        >
          <VideoView
            player={player}
            style={{
              position: "absolute",
              width: 280,
              height: 280,
              left: -20,
              top: -20,
              backgroundColor: "transparent",
            }}
            contentFit="cover"
            nativeControls={false}
            allowsPictureInPicture={false}
          />
        </View>

        <Text
          className="font-josefin-semibold mt-8"
          style={{ fontSize: 32, lineHeight: 38, color: "#ffffff" }}
        >
          Moon Rhythms
        </Text>

        <Text className="text-slate-300 text-lg font-josefin mt-2">
          live in tune with the sky
        </Text>

        <View className="w-full mt-12">
          <GhostPillButton
            label="Begin"
            onPress={() => router.push("/(auth)/sign-up")}
          />

          <View className="mt-4">
            <TextLink
              prefix="Already have an account? "
              linkText="Sign in"
              onPress={() => router.push("/(auth)/sign-in")}
            />
          </View>
        </View>
      </View>
    </View>
  );
}
