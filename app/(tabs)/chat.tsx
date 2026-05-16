import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Ionicons from "@expo/vector-icons/Ionicons";
import { useRouter } from "expo-router";
import {
  ChatMessage,
  ChatSession,
  createChatSession,
  fetchChatMessages,
  fetchChatSessions,
  fetchProfile,
  StreamController,
  streamChatResponse,
  synthesizeProfileSummary,
} from "../../lib/api";
import { Screen } from "../../components/ui/Screen";
import { Input } from "../../components/ui/Input";
import { GhostPillButton } from "../../components/ui/GhostPillButton";

const HAIRLINE = "rgba(255,255,255,0.10)";
const STRONG = "rgba(255,255,255,0.35)";
const SURFACE_1 = "#0A0A0F";

type DisplayMessage = ChatMessage & { pending?: boolean };

function MessageBubble({
  msg,
  streaming,
}: {
  msg: DisplayMessage;
  streaming?: boolean;
}) {
  const isUser = msg.role === "user";
  return (
    <View
      className={isUser ? "items-end" : "items-start"}
      style={{ marginVertical: 4 }}
    >
      <View
        style={{
          maxWidth: "85%",
          backgroundColor: isUser ? "transparent" : SURFACE_1,
          borderColor: isUser ? STRONG : HAIRLINE,
          borderWidth: 1,
          borderRadius: 16,
          paddingHorizontal: 14,
          paddingVertical: 10,
        }}
      >
        <Text
          className="font-josefin"
          style={{
            color: "#FFFFFF",
            fontSize: 15,
            lineHeight: 22,
          }}
        >
          {msg.content}
          {streaming && (
            <Text
              style={{
                color: "#FFFFFF",
                textShadowColor: "rgba(255,255,255,0.6)",
                textShadowOffset: { width: 0, height: 0 },
                textShadowRadius: 8,
              }}
            >
              {" "}
              ▍
            </Text>
          )}
        </Text>
      </View>
    </View>
  );
}

export default function ChatScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const listRef = useRef<FlatList<DisplayMessage>>(null);
  const streamRef = useRef<StreamController | null>(null);

  const [bootstrapping, setBootstrapping] = useState(true);
  const [synthesizing, setSynthesizing] = useState(false);
  const [session, setSession] = useState<ChatSession | null>(null);
  const [profileId, setProfileId] = useState<string | null>(null);
  const [messages, setMessages] = useState<DisplayMessage[]>([]);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [streamingText, setStreamingText] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [noChart, setNoChart] = useState(false);

  const bootstrap = useCallback(async () => {
    setError(null);
    setBootstrapping(true);
    try {
      const profile = await fetchProfile();
      if (!profile?.profile_id) {
        setNoChart(true);
        return;
      }
      setProfileId(profile.profile_id);

      const sessions = await fetchChatSessions();
      if (sessions.length > 0) {
        setSession(sessions[0]);
        return;
      }

      let createRes = await createChatSession(profile.profile_id);
      if (!createRes.ok && createRes.code === "summary_not_ready") {
        setSynthesizing(true);
        try {
          await synthesizeProfileSummary(profile.profile_id);
        } finally {
          setSynthesizing(false);
        }
        createRes = await createChatSession(profile.profile_id);
      }
      if (!createRes.ok) {
        throw new Error(createRes.error);
      }
      setSession(createRes.session);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to start chat");
    } finally {
      setBootstrapping(false);
    }
  }, []);

  useEffect(() => {
    void bootstrap();
    return () => {
      streamRef.current?.cancel();
    };
  }, [bootstrap]);

  useEffect(() => {
    if (!session) {
      setMessages([]);
      return;
    }
    (async () => {
      try {
        const list = await fetchChatMessages(session.id);
        setMessages(list);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Failed to load messages");
      }
    })();
  }, [session]);

  const scrollToBottom = useCallback(() => {
    requestAnimationFrame(() => {
      listRef.current?.scrollToOffset({ offset: 0, animated: true });
    });
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages.length, streamingText, scrollToBottom]);

  const handleSend = useCallback(async () => {
    const text = input.trim();
    if (!text || !session || sending) return;
    setInput("");
    setSending(true);
    setStreamingText("");
    setError(null);

    const optimistic: DisplayMessage = {
      id: `temp-user-${Date.now()}`,
      role: "user",
      content: text,
      ai_response_id: null,
      created_at: new Date().toISOString(),
      pending: true,
    };
    setMessages((prev) => [...prev, optimistic]);

    let accumulated = "";

    const attemptStream = async () => {
      streamRef.current = await streamChatResponse(session.id, text, {
        onToken: (t) => {
          accumulated += t;
          setStreamingText(accumulated);
        },
        onDone: async () => {
          setStreamingText("");
          try {
            const fresh = await fetchChatMessages(session.id);
            setMessages(fresh);
          } catch {
            /* keep optimistic */
          }
          setSending(false);
        },
        onError: async (err) => {
          if (err.code === "summary_not_ready" && profileId) {
            try {
              setSynthesizing(true);
              await synthesizeProfileSummary(profileId);
              setSynthesizing(false);
              await attemptStream();
              return;
            } catch (e) {
              setSynthesizing(false);
              setError(e instanceof Error ? e.message : "Synthesis failed");
            }
          } else {
            setError(err.message);
          }
          setMessages((prev) => prev.filter((m) => m.id !== optimistic.id));
          setStreamingText("");
          setSending(false);
        },
      });
    };

    try {
      await attemptStream();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to send");
      setMessages((prev) => prev.filter((m) => m.id !== optimistic.id));
      setSending(false);
    }
  }, [input, session, sending, profileId]);

  const inverted = useMemo(() => {
    const base = [...messages];
    if (streamingText) {
      base.push({
        id: "streaming-assistant",
        role: "assistant",
        content: streamingText,
        ai_response_id: null,
        created_at: new Date().toISOString(),
      });
    }
    return base.slice().reverse();
  }, [messages, streamingText]);

  // ─── Render ────────────────────────────────────────────────────────────

  if (bootstrapping || synthesizing) {
    return (
      <Screen>
        <View
          className="flex-1 items-center justify-center"
          style={{ paddingBottom: 56 + insets.bottom }}
        >
          <ActivityIndicator color="#FFFFFF" />
          <Text
            className="font-josefin mt-3"
            style={{ color: "#D4D4D8", fontSize: 14 }}
          >
            {synthesizing
              ? "Preparing your astrological profile (~5s)…"
              : "Loading chat…"}
          </Text>
        </View>
      </Screen>
    );
  }

  if (noChart) {
    return (
      <Screen>
        <View
          className="flex-1 items-center justify-center px-8"
          style={{ paddingBottom: 56 + insets.bottom }}
        >
          <Ionicons name="compass-outline" size={36} color="#FFFFFF" />
          <Text className="text-white text-xl font-josefin-semibold mt-3">
            Add your birth chart first
          </Text>
          <Text
            className="font-josefin text-center mt-2 leading-5"
            style={{ color: "#D4D4D8", fontSize: 14 }}
          >
            The AI guide needs your natal chart to know what to talk about. Open
            Birth Matrix to enter your birth details.
          </Text>
          <View style={{ marginTop: 24, minWidth: 220 }}>
            <GhostPillButton
              label="Open Birth Matrix"
              onPress={() => router.push("/birth-matrix")}
              shimmer={false}
            />
          </View>
        </View>
      </Screen>
    );
  }

  if (error && !session) {
    return (
      <Screen>
        <View
          className="flex-1 items-center justify-center px-8"
          style={{ paddingBottom: 56 + insets.bottom }}
        >
          <Text className="text-white text-xl font-josefin-semibold mb-2">
            Chat unavailable
          </Text>
          <Text
            className="font-josefin text-center mb-5"
            style={{ color: "#D4D4D8", fontSize: 14 }}
          >
            {error}
          </Text>
          <View style={{ minWidth: 200 }}>
            <GhostPillButton
              label="Try again"
              onPress={() => void bootstrap()}
              shimmer={false}
            />
          </View>
        </View>
      </Screen>
    );
  }

  return (
    <Screen edges={["top", "left", "right"]}>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : undefined}
        keyboardVerticalOffset={Platform.OS === "ios" ? insets.top : 0}
      >
        {/* Header */}
        <View
          style={{
            paddingTop: 12,
            paddingHorizontal: 16,
            paddingBottom: 12,
            borderBottomColor: HAIRLINE,
            borderBottomWidth: 1,
          }}
        >
          <Text
            className="text-white font-josefin-semibold"
            style={{ fontSize: 22 }}
          >
            Chat
          </Text>
          <Text
            className="font-josefin text-text-tertiary mt-0.5"
            style={{ fontSize: 12 }}
          >
            Your AI guide, grounded in your chart
          </Text>
        </View>

        {/* Messages */}
        {messages.length === 0 && !streamingText && (
          <View className="flex-1 items-center justify-center px-8">
            <Ionicons name="sparkles-outline" size={28} color="#FFFFFF" />
            <Text
              className="text-white font-josefin-semibold mt-3"
              style={{
                fontSize: 16,
                textShadowColor: "rgba(255,255,255,0.25)",
                textShadowOffset: { width: 0, height: 0 },
                textShadowRadius: 8,
              }}
            >
              Say hello
            </Text>
            <Text
              className="font-josefin text-center mt-1"
              style={{ color: "#D4D4D8", fontSize: 14 }}
            >
              Ask anything about your chart, patterns, or what's coming up.
            </Text>
          </View>
        )}

        {(messages.length > 0 || streamingText) && (
          <FlatList
            ref={listRef}
            data={inverted}
            inverted
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
              <MessageBubble
                msg={item}
                streaming={item.id === "streaming-assistant"}
              />
            )}
            contentContainerStyle={{
              paddingHorizontal: 16,
              paddingVertical: 12,
            }}
            keyboardShouldPersistTaps="handled"
            keyboardDismissMode="interactive"
          />
        )}

        {/* Error banner */}
        {error && session && (
          <View style={{ marginHorizontal: 16, marginBottom: 8 }}>
            <Text
              className="text-destructive font-josefin"
              style={{ fontSize: 14 }}
            >
              {error}
            </Text>
          </View>
        )}

        {/* Input */}
        <View
          className="flex-row items-end"
          style={{
            paddingHorizontal: 12,
            paddingTop: 8,
            paddingBottom: 56 + insets.bottom + 8,
            borderTopColor: HAIRLINE,
            borderTopWidth: 1,
            backgroundColor: "#000000",
            gap: 8,
          }}
        >
          <View style={{ flex: 1 }}>
            <Input
              value={input}
              onChangeText={setInput}
              placeholder="Ask anything…"
              multiline
              editable={!sending}
            />
          </View>
          <Pressable
            onPress={handleSend}
            disabled={!input.trim() || sending}
            style={({ pressed }) => ({
              width: 44,
              height: 44,
              borderRadius: 22,
              borderWidth: 1,
              borderColor: !input.trim() || sending ? HAIRLINE : STRONG,
              backgroundColor: "transparent",
              alignItems: "center",
              justifyContent: "center",
              opacity: pressed ? 0.85 : 1,
            })}
          >
            {sending ? (
              <ActivityIndicator color="#FFFFFF" size="small" />
            ) : (
              <Ionicons
                name="arrow-up"
                size={20}
                color={!input.trim() ? "#5A5A60" : "#FFFFFF"}
              />
            )}
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </Screen>
  );
}
