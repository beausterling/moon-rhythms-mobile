export type ISODate = string;
export type ISODateTime = string;
export type LocalTime = string;

export type Profile = {
  id: string;
  displayName: string | null;
  birthDate: ISODate | null;
  birthTime: LocalTime | null;
  birthTimezone: string | null;
  birthLocationName: string | null;
  birthLatitude: number | null;
  birthLongitude: number | null;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
};

export type BirthReading = {
  id: string;
  userId: string;
  label: string | null;
  birthDate: ISODate;
  birthTime: LocalTime | null;
  birthTimezone: string | null;
  birthLocationName: string | null;
  birthLatitude: number | null;
  birthLongitude: number | null;
  chartPayload: Record<string, unknown>;
  humanDesignPayload: Record<string, unknown>;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
};

export type QuizType = 'mbti' | 'big_five' | 'enneagram' | 'disc';

export type QuizResult = {
  id: string;
  userId: string;
  quizType: QuizType;
  resultCode: string | null;
  scores: Record<string, unknown>;
  answers: unknown[];
  resultPayload: Record<string, unknown>;
  completedAt: ISODateTime;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
};

export type NotificationPreferences = {
  userId: string;
  moonSignNotificationsEnabled: boolean;
  quietHoursStart: LocalTime | null;
  quietHoursEnd: LocalTime | null;
  timezone: string | null;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
};

// Supabase row shapes use snake_case. App shapes use camelCase.
// Keep mapping explicit at the db boundary so UI code never leaks database naming.
export type ProfileRow = {
  id: string;
  display_name: string | null;
  birth_date: ISODate | null;
  birth_time: LocalTime | null;
  birth_timezone: string | null;
  birth_location_name: string | null;
  birth_latitude: number | null;
  birth_longitude: number | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};

export type BirthReadingRow = {
  id: string;
  user_id: string;
  label: string | null;
  birth_date: ISODate;
  birth_time: LocalTime | null;
  birth_timezone: string | null;
  birth_location_name: string | null;
  birth_latitude: number | null;
  birth_longitude: number | null;
  chart_payload: Record<string, unknown>;
  human_design_payload: Record<string, unknown>;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};

export type QuizResultRow = {
  id: string;
  user_id: string;
  quiz_type: QuizType;
  result_code: string | null;
  scores: Record<string, unknown>;
  answers: unknown[];
  result_payload: Record<string, unknown>;
  completed_at: ISODateTime;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};

export type NotificationPreferencesRow = {
  user_id: string;
  moon_sign_notifications_enabled: boolean;
  quiet_hours_start: LocalTime | null;
  quiet_hours_end: LocalTime | null;
  timezone: string | null;
  created_at: ISODateTime;
  updated_at: ISODateTime;
};
