import { useEffect, useMemo, useState } from "react";
import { View, Dimensions, StyleSheet } from "react-native";
import { LinearGradient } from "expo-linear-gradient";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  withDelay,
  Easing,
  interpolate,
} from "react-native-reanimated";

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get("window");

// ---------- Stars ----------

type StarData = {
  id: number;
  x: number;
  y: number;
  size: number;
  duration: number;
  delay: number;
};

function generateStars(count: number): StarData[] {
  const stars: StarData[] = [];
  for (let i = 0; i < count; i++) {
    stars.push({
      id: i,
      x: Math.random(),
      y: Math.random(),
      size: 0.5 + Math.random() * 1.5,
      duration: 3000 + Math.random() * 4000,
      delay: Math.random() * 4000,
    });
  }
  return stars;
}

function Star({ x, y, size, duration, delay }: StarData) {
  const opacity = useSharedValue(0.2);

  useEffect(() => {
    opacity.value = withDelay(
      delay,
      withRepeat(
        withTiming(0.8, {
          duration,
          easing: Easing.inOut(Easing.ease),
        }),
        -1,
        true,
      ),
    );
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
  }));

  return (
    <Animated.View
      style={[
        {
          position: "absolute",
          left: x * SCREEN_WIDTH,
          top: y * SCREEN_HEIGHT,
          width: size,
          height: size,
          borderRadius: size / 2,
          backgroundColor: "#ffffff",
        },
        animatedStyle,
      ]}
    />
  );
}

// ---------- Satellite ----------

type SatelliteData = {
  id: number;
  startX: number;
  startY: number;
  endX: number;
  endY: number;
  duration: number;
};

function Satellite({
  startX,
  startY,
  endX,
  endY,
  duration,
  onDone,
}: SatelliteData & { onDone: () => void }) {
  const tx = useSharedValue(startX);
  const ty = useSharedValue(startY);

  useEffect(() => {
    const ms = duration * 1000;
    tx.value = withTiming(endX, { duration: ms, easing: Easing.linear });
    ty.value = withTiming(endY, { duration: ms, easing: Easing.linear });
    const timer = setTimeout(onDone, ms);
    return () => clearTimeout(timer);
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: tx.value }, { translateY: ty.value }],
  }));

  return (
    <Animated.View
      style={[
        {
          position: "absolute",
          top: 0,
          left: 0,
          width: 2,
          height: 2,
          borderRadius: 1,
          backgroundColor: "#ffffff",
          opacity: 0.6,
        },
        animatedStyle,
      ]}
    />
  );
}

// ---------- Shooting Star ----------

type ShootingStarData = {
  id: number;
  xPct: number;
  yPct: number;
  angle: number;
};

function ShootingStar({
  xPct,
  yPct,
  angle,
  onDone,
}: ShootingStarData & { onDone: () => void }) {
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withTiming(1, {
      duration: 700,
      easing: Easing.out(Easing.quad),
    });
    const timer = setTimeout(onDone, 800);
    return () => clearTimeout(timer);
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: interpolate(progress.value, [0, 0.1, 0.75, 1], [0, 1, 1, 0]),
    transform: [
      { rotate: `${angle}deg` },
      { translateX: interpolate(progress.value, [0, 1], [0, 460]) },
    ],
  }));

  return (
    <Animated.View
      style={[
        {
          position: "absolute",
          left: xPct * SCREEN_WIDTH,
          top: yPct * SCREEN_HEIGHT,
          width: 0,
          height: 0,
        },
        animatedStyle,
      ]}
    >
      {/* Subtle short trail */}
      <LinearGradient
        colors={["rgba(255,255,255,0)", "rgba(255,255,255,0.35)"]}
        start={{ x: 0, y: 0.5 }}
        end={{ x: 1, y: 0.5 }}
        style={{
          position: "absolute",
          left: -11.5,
          top: -0.75,
          width: 10,
          height: 1.5,
        }}
      />
      {/* Head */}
      <View
        style={{
          position: "absolute",
          left: -1.5,
          top: -1.5,
          width: 3,
          height: 3,
          borderRadius: 1.5,
          backgroundColor: "#ffffff",
        }}
      />
    </Animated.View>
  );
}

// ---------- NightSky ----------

const STAR_COUNT = 150;

export function NightSky() {
  const stars = useMemo(() => generateStars(STAR_COUNT), []);
  const [satellites, setSatellites] = useState<SatelliteData[]>([]);
  const [shootingStars, setShootingStars] = useState<ShootingStarData[]>([]);

  // Satellite spawner: initial 3-8s, recurring every 15-45s
  useEffect(() => {
    const spawn = () => {
      const id = Date.now() + Math.floor(Math.random() * 1000);
      // Direction is biased near-horizontal: ±20deg around right or left.
      // A perpendicular offset keeps paths from all crossing screen center.
      const goLeft = Math.random() > 0.5;
      const baseAngle = goLeft ? Math.PI : 0;
      const tilt = ((Math.random() - 0.5) * 40 * Math.PI) / 180;
      const angle = baseAngle + tilt;
      const dirX = Math.cos(angle);
      const dirY = Math.sin(angle);
      const perpX = -dirY;
      const perpY = dirX;
      const perpOffset =
        (Math.random() - 0.5) * Math.min(SCREEN_WIDTH, SCREEN_HEIGHT) * 0.85;
      const cx = SCREEN_WIDTH / 2;
      const cy = SCREEN_HEIGHT / 2;
      const halfPath =
        Math.sqrt(SCREEN_WIDTH ** 2 + SCREEN_HEIGHT ** 2) / 2 + 30;
      const startX = cx + perpOffset * perpX - halfPath * dirX;
      const startY = cy + perpOffset * perpY - halfPath * dirY;
      const endX = cx + perpOffset * perpX + halfPath * dirX;
      const endY = cy + perpOffset * perpY + halfPath * dirY;
      // Preserve the previous horizontal speed feel: pick a speed in the same
      // range that 20-50s across screen-width gave, then derive duration.
      const minSpeed = (SCREEN_WIDTH + 20) / 50;
      const maxSpeed = (SCREEN_WIDTH + 20) / 20;
      const speed = minSpeed + Math.random() * (maxSpeed - minSpeed);
      const duration = (halfPath * 2) / speed;
      setSatellites((prev) => [
        ...prev,
        { id, startX, startY, endX, endY, duration },
      ]);
    };

    const initialT = setTimeout(spawn, 3000 + Math.random() * 5000);
    const interval = setInterval(spawn, 15000 + Math.random() * 30000);
    return () => {
      clearTimeout(initialT);
      clearInterval(interval);
    };
  }, []);

  // Shooting star spawner: initial 8-23s, recurring every 20-60s
  useEffect(() => {
    const spawn = () => {
      const id = Date.now() + Math.floor(Math.random() * 1000);
      // Near-horizontal: ±15deg from right (0deg) or left (180deg). Start in
      // the half opposite the direction of travel so the burst stays on-screen.
      const goLeft = Math.random() > 0.5;
      const baseDeg = goLeft ? 180 : 0;
      const tiltDeg = (Math.random() - 0.5) * 30;
      const xPct = goLeft ? 0.5 + Math.random() * 0.5 : Math.random() * 0.5;
      setShootingStars((prev) => [
        ...prev,
        {
          id,
          xPct,
          yPct: 0.05 + Math.random() * 0.65,
          angle: baseDeg + tiltDeg,
        },
      ]);
    };

    const initialT = setTimeout(spawn, 8000 + Math.random() * 15000);
    const interval = setInterval(spawn, 20000 + Math.random() * 40000);
    return () => {
      clearTimeout(initialT);
      clearInterval(interval);
    };
  }, []);

  const removeSatellite = (id: number) =>
    setSatellites((prev) => prev.filter((s) => s.id !== id));
  const removeShootingStar = (id: number) =>
    setShootingStars((prev) => prev.filter((s) => s.id !== id));

  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {stars.map((star) => (
        <Star key={star.id} {...star} />
      ))}
      {satellites.map((sat) => (
        <Satellite
          key={sat.id}
          {...sat}
          onDone={() => removeSatellite(sat.id)}
        />
      ))}
      {shootingStars.map((ss) => (
        <ShootingStar
          key={ss.id}
          {...ss}
          onDone={() => removeShootingStar(ss.id)}
        />
      ))}
    </View>
  );
}
