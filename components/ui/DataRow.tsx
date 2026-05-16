import { Text, View } from "react-native";

interface DataRowProps {
  label: string;
  children: React.ReactNode;
}

export function DataRow({ label, children }: DataRowProps) {
  return (
    <View
      className="flex-row justify-between items-center"
      style={{ paddingVertical: 8 }}
    >
      <Text
        className="font-josefin text-text-tertiary"
        style={{
          fontSize: 12,
          lineHeight: 16,
          letterSpacing: 2.16,
          textTransform: "uppercase",
        }}
      >
        {label}
      </Text>
      <View>{children}</View>
    </View>
  );
}
