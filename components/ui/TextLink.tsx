import { Pressable, Text } from "react-native";

interface TextLinkProps {
  prefix?: string;
  linkText: string;
  onPress: () => void;
}

export function TextLink({ prefix, linkText, onPress }: TextLinkProps) {
  return (
    <Pressable onPress={onPress} className="items-center">
      <Text className="text-base font-josefin" style={{ color: "#8888aa" }}>
        {prefix}
        <Text className="font-josefin-semibold" style={{ color: "#ffffff" }}>
          {linkText}
        </Text>
      </Text>
    </Pressable>
  );
}
