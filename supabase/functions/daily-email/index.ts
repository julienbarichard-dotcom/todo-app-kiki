// Supabase Edge Function - Envoi quotidien d'emails de récapitulatif des tâches
// Déclenché par un cron job à 8h00 chaque matin

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// Configuration Resend (service d'envoi d'emails)
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const FROM_EMAIL = "onboarding@resend.dev"; // Email de test Resend

interface Task {
  id: string;
  titre: string;
  description: string;
  urgence: string;
  date_echeance: string | null;
  est_complete: boolean;
  assigned_to: string[];
  statut: string;
  label: string | null;
  sub_tasks: { titre: string; estComplete: boolean }[];
}

interface User {
  id: string;
  prenom: string;
  email: string | null;
}

serve(async (req) => {
  try {
    // Initialiser Supabase
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Récupérer tous les utilisateurs avec email
    const { data: users, error: usersError } = await supabase
      .from("users")
      .select("id, prenom, email")
      .not("email", "is", null);

    if (usersError) throw usersError;

    const allUsers = users as User[];

    // Si aucun utilisateur n'a d'email, arrêter
    if (allUsers.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: "Aucun utilisateur avec email configuré" }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // Récupérer toutes les tâches non terminées
    const { data: tasks, error } = await supabase
      .from("tasks")
      .select("*")
      .eq("est_complete", false)
      .order("date_echeance", { ascending: true });

    if (error) throw error;

    const allTasks = tasks as Task[];
    const results: { user: string; email: string; success: boolean; error?: string }[] = [];

    // Envoyer un email à chaque utilisateur
    for (const user of allUsers) {
      // Filtrer les tâches assignées à cet utilisateur
      const userTasks = allTasks.filter((task) =>
        task.assigned_to?.some(
          (name) => name.toLowerCase() === user.prenom.toLowerCase()
        )
      );

      if (userTasks.length === 0) {
        results.push({ user: user.prenom, email: user.email!, success: true });
        continue;
      }

      // Générer le contenu HTML de l'email
      const emailHtml = generateEmailHtml(user.prenom, userTasks);

      // Envoyer l'email via Resend
      try {
        const response = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${RESEND_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: FROM_EMAIL,
            to: user.email!,
            subject: `📋 Récap quotidien - ${userTasks.length} tâche(s) en attente`,
            html: emailHtml,
          }),
        });

        if (response.ok) {
          results.push({ user: user.prenom, email: user.email!, success: true });
        } else {
          const errorData = await response.text();
          results.push({ user: user.prenom, email: user.email!, success: false, error: errorData });
        }
      } catch (emailError) {
        results.push({
          user: user.prenom,
          email: user.email!,
          success: false,
          error: String(emailError),
        });
      }
    }

    return new Response(JSON.stringify({ success: true, results }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: String(error) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

function generateEmailHtml(userName: string, tasks: Task[]): string {
  const urgenceEmoji: Record<string, string> = {
    haute: "🔴",
    moyenne: "🟠",
    basse: "🟢",
  };

  const statutLabel: Record<string, string> = {
    enAttente: "En attente",
    enCours: "En cours",
    termine: "Terminé",
  };

  const today = new Date();
  const tasksHtml = tasks
    .map((task) => {
      const urgenceIcon = urgenceEmoji[task.urgence] || "⚪";
      const statut = statutLabel[task.statut] || task.statut;
      const dateStr = task.date_echeance
        ? new Date(task.date_echeance).toLocaleDateString("fr-FR", {
            weekday: "short",
            day: "numeric",
            month: "short",
            hour: "2-digit",
            minute: "2-digit",
          })
        : "Sans date";

      // Vérifier si en retard
      const isOverdue =
        task.date_echeance && new Date(task.date_echeance) < today;
      const overdueStyle = isOverdue ? 'style="color: #dc2626;"' : "";

      // Sous-tâches
      const subTasksCount = task.sub_tasks?.length || 0;
      const completedSubTasks =
        task.sub_tasks?.filter((st) => st.estComplete).length || 0;
      const subTasksInfo =
        subTasksCount > 0
          ? `<br><small>📝 ${completedSubTasks}/${subTasksCount} sous-tâches</small>`
          : "";

      return `
        <tr>
          <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">
            ${urgenceIcon} <strong>${task.titre}</strong>
            ${task.label ? `<span style="background: #e5e7eb; padding: 2px 6px; border-radius: 4px; font-size: 12px; margin-left: 8px;">${task.label}</span>` : ""}
            ${subTasksInfo}
          </td>
          <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">
            <span style="background: #dbeafe; padding: 4px 8px; border-radius: 4px; font-size: 12px;">${statut}</span>
          </td>
          <td ${overdueStyle} style="padding: 12px; border-bottom: 1px solid #e5e7eb;">
            ${isOverdue ? "⚠️ " : ""}${dateStr}
          </td>
        </tr>
      `;
    })
    .join("");

  const overdueCount = tasks.filter(
    (t) => t.date_echeance && new Date(t.date_echeance) < today
  ).length;
  const highPriorityCount = tasks.filter((t) => t.urgence === "haute").length;

  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f3f4f6; padding: 20px;">
      <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
        <div style="background: #4ade80; padding: 24px; color: white;">
          <h1 style="margin: 0; font-size: 24px;">📋 Bonjour ${userName} !</h1>
          <p style="margin: 8px 0 0; opacity: 0.9;">Voici ton récapitulatif du ${today.toLocaleDateString("fr-FR", { weekday: "long", day: "numeric", month: "long" })}</p>
        </div>
        
        <div style="padding: 24px;">
          <div style="display: flex; gap: 16px; margin-bottom: 24px;">
            <div style="flex: 1; background: #fef3c7; padding: 16px; border-radius: 8px; text-align: center;">
              <div style="font-size: 28px; font-weight: bold; color: #d97706;">${tasks.length}</div>
              <div style="font-size: 12px; color: #92400e;">Tâches en attente</div>
            </div>
            <div style="flex: 1; background: #fee2e2; padding: 16px; border-radius: 8px; text-align: center;">
              <div style="font-size: 28px; font-weight: bold; color: #dc2626;">${highPriorityCount}</div>
              <div style="font-size: 12px; color: #991b1b;">Priorité haute</div>
            </div>
            <div style="flex: 1; background: ${overdueCount > 0 ? "#fecaca" : "#d1fae5"}; padding: 16px; border-radius: 8px; text-align: center;">
              <div style="font-size: 28px; font-weight: bold; color: ${overdueCount > 0 ? "#dc2626" : "#059669"};">${overdueCount}</div>
              <div style="font-size: 12px; color: ${overdueCount > 0 ? "#991b1b" : "#065f46"};">En retard</div>
            </div>
          </div>

          <table style="width: 100%; border-collapse: collapse;">
            <thead>
              <tr style="background: #f9fafb;">
                <th style="padding: 12px; text-align: left; font-weight: 600; color: #374151;">Tâche</th>
                <th style="padding: 12px; text-align: left; font-weight: 600; color: #374151;">Statut</th>
                <th style="padding: 12px; text-align: left; font-weight: 600; color: #374151;">Échéance</th>
              </tr>
            </thead>
            <tbody>
              ${tasksHtml}
            </tbody>
          </table>

          <div style="margin-top: 24px; text-align: center;">
            <a href="https://app-des-kiki-s.web.app" style="display: inline-block; background: #4ade80; color: white; padding: 12px 32px; border-radius: 8px; text-decoration: none; font-weight: 600;">
              Ouvrir l'application
            </a>
          </div>
        </div>

        <div style="background: #f9fafb; padding: 16px; text-align: center; font-size: 12px; color: #6b7280;">
          Todo App Kiki's - Récapitulatif automatique
        </div>
      </div>
    </body>
    </html>
  `;
}
