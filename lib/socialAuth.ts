import { Platform } from "react-native";
import * as AppleAuthentication from "expo-apple-authentication";
import {
  GoogleSignin,
  isSuccessResponse,
  statusCodes,
} from "@react-native-google-signin/google-signin";
import { supabase } from "./supabase";

// Configure Google sign-in once at module load.
// webClientId is the audience Supabase validates the ID token against — it must
// match the project's configured Google client in Supabase (the web OAuth client
// shared with moonrhythms.io). iosClientId is the native iOS OAuth client.
GoogleSignin.configure({
  webClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID,
  iosClientId: process.env.EXPO_PUBLIC_GOOGLE_IOS_CLIENT_ID,
});

export type SocialAuthResult = { error: string | null };

/**
 * Native Google sign-in -> Supabase signInWithIdToken.
 * Returns { error: null } on success OR user cancellation (cancellation is not
 * an error worth surfacing). AuthProvider's onAuthStateChange handles navigation.
 */
export async function signInWithGoogle(): Promise<SocialAuthResult> {
  try {
    await GoogleSignin.hasPlayServices();
    const response = await GoogleSignin.signIn();

    if (!isSuccessResponse(response) || !response.data?.idToken) {
      return { error: null }; // cancelled or no token
    }

    const { error } = await supabase.auth.signInWithIdToken({
      provider: "google",
      token: response.data.idToken,
    });
    return { error: error ? error.message : null };
  } catch (e: any) {
    if (
      e?.code === statusCodes.SIGN_IN_CANCELLED ||
      e?.code === statusCodes.IN_PROGRESS
    ) {
      return { error: null };
    }
    if (e?.code === statusCodes.PLAY_SERVICES_NOT_AVAILABLE) {
      return { error: "Google Play Services not available or outdated." };
    }
    return { error: e?.message ?? "Google sign-in failed." };
  }
}

/**
 * Native Apple sign-in -> Supabase signInWithIdToken. iOS only.
 * Apple returns the user's name only on first sign-in, so persist it to user
 * metadata when present.
 */
export async function signInWithApple(): Promise<SocialAuthResult> {
  if (Platform.OS !== "ios") {
    return { error: "Sign in with Apple is only available on iOS." };
  }
  try {
    const credential = await AppleAuthentication.signInAsync({
      requestedScopes: [
        AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        AppleAuthentication.AppleAuthenticationScope.EMAIL,
      ],
    });

    if (!credential.identityToken) {
      return { error: "No identity token returned from Apple." };
    }

    const { error } = await supabase.auth.signInWithIdToken({
      provider: "apple",
      token: credential.identityToken,
    });
    if (error) return { error: error.message };

    const fullName = [
      credential.fullName?.givenName,
      credential.fullName?.familyName,
    ]
      .filter(Boolean)
      .join(" ")
      .trim();
    if (fullName) {
      await supabase.auth
        .updateUser({ data: { full_name: fullName } })
        .catch(() => {});
    }

    return { error: null };
  } catch (e: any) {
    if (e?.code === "ERR_REQUEST_CANCELED") {
      return { error: null }; // user cancelled
    }
    return { error: e?.message ?? "Apple sign-in failed." };
  }
}
