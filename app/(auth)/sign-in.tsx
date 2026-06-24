import { useState } from "react";
import {
  Keyboard,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Text,
  TouchableWithoutFeedback,
  View,
} from "react-native";
import { useRouter } from "expo-router";
import { supabase } from "../../lib/supabase";
import { Screen } from "../../components/ui/Screen";
import { Input } from "../../components/ui/Input";
import { GhostPillButton } from "../../components/ui/GhostPillButton";
import { TextLink } from "../../components/ui/TextLink";
import { SocialAuthButtons } from "../../components/auth/SocialAuthButtons";

export default function SignInScreen() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [loading, setLoading] = useState(false);

  const validate = (): boolean => {
    let valid = true;
    setEmailError("");
    setPasswordError("");

    if (!email.trim()) {
      setEmailError("Email is required");
      valid = false;
    } else if (!/\S+@\S+\.\S+/.test(email)) {
      setEmailError("Enter a valid email address");
      valid = false;
    }

    if (!password) {
      setPasswordError("Password is required");
      valid = false;
    }

    return valid;
  };

  const handleSignIn = async () => {
    if (!validate()) return;

    setLoading(true);
    setEmailError("");
    setPasswordError("");

    const { error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    setLoading(false);

    if (error) {
      const msg = error.message.toLowerCase();
      if (
        msg.includes("invalid login credentials") ||
        msg.includes("invalid_credentials")
      ) {
        setPasswordError("Incorrect email or password");
      } else if (msg.includes("network")) {
        setPasswordError("Could not connect. Check your internet and try again.");
      } else {
        setPasswordError(error.message);
      }
    }
    // Success: onAuthStateChange in AuthProvider handles navigation
  };

  return (
    <Screen edges={["top"]}>
      <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : "height"}
          style={{ flex: 1 }}
        >
          <ScrollView
            contentContainerStyle={{ flexGrow: 1 }}
            keyboardShouldPersistTaps="handled"
          >
            <View className="flex-1 px-4 pt-16">
              <Text
                className="text-white font-josefin-semibold mt-16"
                style={{ fontSize: 24, lineHeight: 29 }}
              >
                Sign In
              </Text>

              <View className="mt-8">
                <Input
                  value={email}
                  onChangeText={(t) => {
                    setEmail(t);
                    setEmailError("");
                  }}
                  placeholder="Email"
                  keyboardType="email-address"
                  autoCapitalize="none"
                  autoCorrect={false}
                  editable={!loading}
                  error={emailError || undefined}
                />

                <View className="mt-4">
                  <Input
                    value={password}
                    onChangeText={(t) => {
                      setPassword(t);
                      setPasswordError("");
                    }}
                    placeholder="Password"
                    secureTextEntry
                    autoCapitalize="none"
                    editable={!loading}
                    error={passwordError || undefined}
                  />
                </View>

                <View className="mt-6">
                  <GhostPillButton
                    label="Sign in"
                    onPress={handleSignIn}
                    disabled={loading}
                  />
                </View>

                <SocialAuthButtons
                  mode="sign-in"
                  disabled={loading}
                  onError={setPasswordError}
                />

                <View className="mt-4">
                  <TextLink
                    prefix="Don't have an account? "
                    linkText="Sign up"
                    onPress={() => {
                      if (!loading) router.push("/(auth)/sign-up");
                    }}
                  />
                </View>
              </View>
            </View>
          </ScrollView>
        </KeyboardAvoidingView>
      </TouchableWithoutFeedback>
    </Screen>
  );
}
