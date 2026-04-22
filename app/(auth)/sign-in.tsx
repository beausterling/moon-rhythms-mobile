import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  Pressable,
  ActivityIndicator,
  KeyboardAvoidingView,
  TouchableWithoutFeedback,
  Keyboard,
  Platform,
  ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { supabase } from '../../lib/supabase';

export default function SignInScreen() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [emailError, setEmailError] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [loading, setLoading] = useState(false);

  const validate = (): boolean => {
    let valid = true;
    setEmailError('');
    setPasswordError('');

    if (!email.trim()) {
      setEmailError('Email is required');
      valid = false;
    } else if (!/\S+@\S+\.\S+/.test(email)) {
      setEmailError('Enter a valid email address');
      valid = false;
    }

    if (!password) {
      setPasswordError('Password is required');
      valid = false;
    }

    return valid;
  };

  const handleSignIn = async () => {
    if (!validate()) return;

    setLoading(true);
    setEmailError('');
    setPasswordError('');

    const { error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    setLoading(false);

    if (error) {
      // Map Supabase errors to user-facing copy per UI-SPEC Copywriting Contract
      if (error.message.toLowerCase().includes('invalid login credentials') ||
          error.message.toLowerCase().includes('invalid_credentials')) {
        setPasswordError('Incorrect email or password');
      } else if (error.message.toLowerCase().includes('network')) {
        setPasswordError('Could not connect. Check your internet and try again.');
      } else {
        setPasswordError(error.message);
      }
    }
    // Success: onAuthStateChange in AuthProvider handles navigation
  };

  return (
    <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        className="flex-1 bg-background"
      >
        <ScrollView
          contentContainerStyle={{ flexGrow: 1 }}
          keyboardShouldPersistTaps="handled"
        >
          <View className="flex-1 px-4 pt-16">
            {/* Heading -- 24px semibold, left-aligned, 64px from safe area top */}
            <Text className="text-text-primary text-2xl font-josefin-semibold mt-16">
              Sign In
            </Text>

            <View className="mt-8">
              {/* Email input */}
              <TextInput
                value={email}
                onChangeText={(t) => { setEmail(t); setEmailError(''); }}
                placeholder="Email"
                placeholderTextColor="#8888aa"
                keyboardType="email-address"
                autoCapitalize="none"
                autoComplete="email"
                editable={!loading}
                className={`h-[52px] bg-surface rounded-xl px-4 text-base text-text-primary font-josefin border ${
                  emailError ? 'border-destructive' : 'border-border'
                }`}
                style={{ fontFamily: 'JosefinSans-Regular' }}
              />
              {emailError ? (
                <Text className="text-destructive text-sm font-josefin mt-1 ml-1">
                  {emailError}
                </Text>
              ) : null}

              {/* Password input -- 16px gap */}
              <TextInput
                value={password}
                onChangeText={(t) => { setPassword(t); setPasswordError(''); }}
                placeholder="Password"
                placeholderTextColor="#8888aa"
                secureTextEntry
                autoComplete="password"
                editable={!loading}
                className={`h-[52px] bg-surface rounded-xl px-4 text-base text-text-primary font-josefin border mt-4 ${
                  passwordError ? 'border-destructive' : 'border-border'
                }`}
                style={{ fontFamily: 'JosefinSans-Regular' }}
              />
              {passwordError ? (
                <Text className="text-destructive text-sm font-josefin mt-1 ml-1">
                  {passwordError}
                </Text>
              ) : null}

              {/* Submit button -- 24px gap */}
              <Pressable
                onPress={handleSignIn}
                disabled={loading}
                className="h-[52px] bg-accent rounded-xl items-center justify-center mt-6"
                style={({ pressed }) => ({
                  opacity: pressed || loading ? 0.8 : 1,
                })}
              >
                {loading ? (
                  <ActivityIndicator color="#0a0a1a" />
                ) : (
                  <Text className="text-background text-base font-josefin-semibold">
                    Sign In
                  </Text>
                )}
              </Pressable>

              {/* Switch link -- 16px gap, centered */}
              <Pressable
                onPress={() => router.push('/(auth)/sign-up')}
                disabled={loading}
                className="mt-4 items-center"
              >
                <Text className="text-sm font-josefin">
                  <Text className="text-text-secondary">Don't have an account? </Text>
                  <Text className="text-accent">Sign up</Text>
                </Text>
              </Pressable>
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </TouchableWithoutFeedback>
  );
}
