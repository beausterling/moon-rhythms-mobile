import { supabase } from '../supabase';

// Single database boundary for future Supabase-generated types.
// Screens/features should import db helpers, not `../supabase` directly.
export const db = supabase;
