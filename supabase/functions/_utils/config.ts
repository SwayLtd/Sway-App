import * as OneSignal from "https://esm.sh/@onesignal/node-onesignal@1.0.0-beta7";

// OneSignal
export const _OnesignalAppId_ = Deno.env.get("ONESIGNAL_APP_ID")!;
export const _OnesignalUserAuthKey_ = Deno.env.get("USER_AUTH_KEY")!;
export const _OnesignalRestApiKey_ = Deno.env.get("ONESIGNAL_API_KEY")!;
const configuration = OneSignal.createConfiguration({
  userKey: _OnesignalUserAuthKey_,
  appKey: _OnesignalAppId_,
});
export const onesignal = new OneSignal.DefaultApi(configuration);

// Supabase
export const _SupabaseUrl_ = Deno.env.get("SUPABASE_URL")!;
export const _SupabaseServiceRoleKey_ = Deno.env.get(
  "SUPABASE_ANON_KEY",
)!;
