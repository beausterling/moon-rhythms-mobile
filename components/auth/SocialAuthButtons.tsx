import { useState } from "react";
import { Platform, Text, View } from "react-native";
import * as AppleAuthentication from "expo-apple-authentication";
import { GoogleSigninButton } from "@react-native-google-signin/google-signin";
import {
  signInWithApple,
  signInWithGoogle,
  type SocialAuthResult,
} from "../../lib/socialAuth";

interface SocialAuthButtonsProps {
  mode?: "sign-in" | "sign-up";
  onError?: (message: string) => void;
  disabled?: boolean;
}

export function SocialAuthButtons({
  mode = "sign-in",
  onError,
  disabled = false,
}: SocialAuthButtonsProps) {
  const [busy, setBusy] = useState(false);

  const run = async (fn: () => Promise<SocialAuthResult>) => {
    if (busy || disabled) return;
    setBusy(true);
    const { error } = await fn();
    setBusy(false);
    if (error) onError?.(error);
    // Success: AuthProvider.onAuthStateChange handles navigation.
  };

  return (
    <View>
      <View className="flex-row items-center my-6">
        <View className="flex-1 h-px bg-white/15" />
        <Text className="text-white/40 mx-3 font-josefin">or</Text>
        <View className="flex-1 h-px bg-white/15" />
      </View>

      {Platform.OS === "ios" && (
        <AppleAuthentication.AppleAuthenticationButton
          buttonType={
            mode === "sign-up"
              ? AppleAuthentication.AppleAuthenticationButtonType.SIGN_UP
              : AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN
          }
          buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.WHITE}
          cornerRadius={28}
          style={{ width: "100%", height: 56 }}
          onPress={() => run(signInWithApple)}
        />
      )}

      <View className="mt-3 items-center">
        <GoogleSigninButton
          size={GoogleSigninButton.Size.Wide}
          color={GoogleSigninButton.Color.Dark}
          onPress={() => run(signInWithGoogle)}
          disabled={busy || disabled}
        />
      </View>
    </View>
  );
}
