import type {
  BirthReading,
  BirthReadingRow,
  NotificationPreferences,
  NotificationPreferencesRow,
  Profile,
  ProfileRow,
  QuizResult,
  QuizResultRow,
} from './schema';

export function mapProfile(row: ProfileRow): Profile {
  return {
    id: row.id,
    displayName: row.display_name,
    birthDate: row.birth_date,
    birthTime: row.birth_time,
    birthTimezone: row.birth_timezone,
    birthLocationName: row.birth_location_name,
    birthLatitude: row.birth_latitude,
    birthLongitude: row.birth_longitude,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapBirthReading(row: BirthReadingRow): BirthReading {
  return {
    id: row.id,
    userId: row.user_id,
    label: row.label,
    birthDate: row.birth_date,
    birthTime: row.birth_time,
    birthTimezone: row.birth_timezone,
    birthLocationName: row.birth_location_name,
    birthLatitude: row.birth_latitude,
    birthLongitude: row.birth_longitude,
    chartPayload: row.chart_payload,
    humanDesignPayload: row.human_design_payload,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapQuizResult(row: QuizResultRow): QuizResult {
  return {
    id: row.id,
    userId: row.user_id,
    quizType: row.quiz_type,
    resultCode: row.result_code,
    scores: row.scores,
    answers: row.answers,
    resultPayload: row.result_payload,
    completedAt: row.completed_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function mapNotificationPreferences(
  row: NotificationPreferencesRow,
): NotificationPreferences {
  return {
    userId: row.user_id,
    moonSignNotificationsEnabled: row.moon_sign_notifications_enabled,
    quietHoursStart: row.quiet_hours_start,
    quietHoursEnd: row.quiet_hours_end,
    timezone: row.timezone,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}
