import { forwardRef, useState } from "react";
import {
  Text,
  TextInput,
  View,
  type KeyboardTypeOptions,
  type TextInputProps,
  type ViewStyle,
} from "react-native";

interface InputProps {
  value: string;
  onChangeText: (v: string) => void;
  placeholder?: string;
  secureTextEntry?: boolean;
  keyboardType?: KeyboardTypeOptions;
  autoCapitalize?: TextInputProps["autoCapitalize"];
  autoCorrect?: boolean;
  multiline?: boolean;
  numberOfLines?: number;
  error?: string;
  label?: string;
  editable?: boolean;
  style?: ViewStyle;
  onSubmitEditing?: () => void;
  returnKeyType?: TextInputProps["returnKeyType"];
}

const HAIRLINE = "rgba(255,255,255,0.10)";
const STRONG = "rgba(255,255,255,0.35)";
const ERROR = "#EF4444";
const SURFACE_1 = "#0A0A0F";
const SURFACE_2 = "#14141C";

export const Input = forwardRef<TextInput, InputProps>(function Input(
  {
    value,
    onChangeText,
    placeholder,
    secureTextEntry,
    keyboardType,
    autoCapitalize,
    autoCorrect,
    multiline,
    numberOfLines,
    error,
    label,
    editable = true,
    style,
    onSubmitEditing,
    returnKeyType,
  },
  ref,
) {
  const [focused, setFocused] = useState(false);

  const borderColor = error ? ERROR : focused ? STRONG : HAIRLINE;
  const height = multiline ? undefined : 52;
  const minHeight = multiline ? 52 : undefined;

  return (
    <View style={style}>
      {!!label && (
        <Text
          className="font-josefin text-text-tertiary"
          style={{
            fontSize: 12,
            lineHeight: 16,
            letterSpacing: 2.16,
            textTransform: "uppercase",
            marginBottom: 8,
          }}
        >
          {label}
        </Text>
      )}
      <View
        style={{
          backgroundColor: focused ? SURFACE_2 : SURFACE_1,
          borderWidth: 1,
          borderColor,
          borderRadius: 12,
          height,
          minHeight,
          paddingHorizontal: 16,
          justifyContent: "center",
        }}
      >
        <TextInput
          ref={ref}
          value={value}
          onChangeText={onChangeText}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          placeholder={placeholder}
          placeholderTextColor="#8A8A90"
          secureTextEntry={secureTextEntry}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize}
          autoCorrect={autoCorrect}
          multiline={multiline}
          numberOfLines={numberOfLines}
          editable={editable}
          onSubmitEditing={onSubmitEditing}
          returnKeyType={returnKeyType}
          className="font-josefin"
          style={{
            color: "#FFFFFF",
            fontSize: 16,
            lineHeight: 25,
            paddingVertical: multiline ? 14 : 0,
            // textAlignVertical helps multiline iOS render line 1 at top.
            textAlignVertical: multiline ? "top" : "center",
          }}
        />
      </View>
      {!!error && (
        <Text
          className="font-josefin"
          style={{
            color: ERROR,
            fontSize: 14,
            marginTop: 4,
          }}
        >
          {error}
        </Text>
      )}
    </View>
  );
});
