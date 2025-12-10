// Supabase Edge Function - Envoi quotidien d'emails de récapitulatif des tâches
// Déclenché par un cron job à 8h00 chaque matin

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// (emails removed) — cette fonction envoie uniquement des push FCM
// Optional schedule token to protect the function endpoint. If set, incoming
// requests must include header `x-schedule-token: <token>`
const SCHEDULE_TOKEN = Deno.env.get("SCHEDULE_TOKEN");
// Firebase Cloud Messaging (FCM) server key (legacy HTTP API). Optional.
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY");

function normalizeAssignedTo(value: any): string[] {
  // Accept multiple possible stored formats: array of strings, comma-separated string,
  // JSON-encoded string, or single string.
  if (!value) return [];
  if (Array.isArray(value)) return value.map((v) => String(v).trim()).filter(Boolean);
  if (typeof value === "string") {
    // If looks like JSON array
    const trimmed = value.trim();
    if ((trimmed.startsWith("[") && trimmed.endsWith("]")) || trimmed.includes('\"')) {
      try {
        const parsed = JSON.parse(trimmed);
        if (Array.isArray(parsed)) return parsed.map((v) => String(v).trim()).filter(Boolean);
      } catch (_e) {
        // fall through to comma split
      }
    }
    // comma-separated
    return trimmed.split(",").map((s) => s.trim()).filter(Boolean);
  }
  // Fallback: stringify
  return [String(value)];
}



import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// Notification function disabled — no-op endpoint
serve(async (_req) => {
  return new Response(JSON.stringify({ success: true, message: "Notifications désactivées : fonction daily-email remplacée par no-op." }), {
    headers: { "Content-Type": "application/json" },
  });
});
      title,

      body,
