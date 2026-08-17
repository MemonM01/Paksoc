// PakSoc committee dashboard API.
// Deploy: Supabase Dashboard → Edge Functions → New function "dashboard-api"
// → paste this file → Deploy. (Or: npx supabase functions deploy dashboard-api)
//
// Single POST endpoint. Every request carries the shared committee passcode;
// it's checked against admin_settings on every call (including
// change_passcode, which is how "must know the current passcode to change
// it" happens for free) before any write runs. Writes use the service-role
// key (auto-injected by Supabase into every Edge Function's env), which
// bypasses RLS — that's intentional, the passcode check IS the
// authorization, matching the "not real security" framing already on the
// dashboard's UI (a shared passcode is meant to keep casual visitors out,
// not withstand a real attacker).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const BUCKET = 'paksoc-media';

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

function dataUrlToBytes(dataUrl: string) {
  const m = /^data:([^;]+);base64,(.+)$/.exec(dataUrl || '');
  if (!m) throw new Error('bad_image_data');
  return { contentType: m[1], bytes: Uint8Array.from(atob(m[2]), (c) => c.charCodeAt(0)) };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });
  if (req.method !== 'POST') return json({ ok: false, error: 'method_not_allowed' }, 405);

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, error: 'bad_request' }, 400);
  }
  const { action, passcode, payload = {} } = body || {};
  if (!action || typeof passcode !== 'string') return json({ ok: false, error: 'bad_request' }, 400);

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: validPasscode, error: verifyErr } = await admin.rpc('verify_passcode', { input: passcode });
  if (verifyErr) return json({ ok: false, error: 'server_error', message: verifyErr.message }, 500);
  if (!validPasscode) return json({ ok: false, error: 'invalid_passcode' }, 401);

  try {
    switch (action) {
      case 'verify_passcode':
        return json({ ok: true });

      case 'post_announcement': {
        const { title, body: text = '', date, pinned = false } = payload;
        if (!title || !date) throw new Error('title and date are required');
        const { error } = await admin.from('announcements').insert({ title, body: text, date, pinned });
        if (error) throw error;
        return json({ ok: true });
      }

      case 'delete_announcement': {
        const { error } = await admin.from('announcements').delete().eq('id', payload.id);
        if (error) throw error;
        return json({ ok: true });
      }

      case 'add_event': {
        const { title, date, time = '', place = '', body: text = '' } = payload;
        if (!title) throw new Error('title is required');
        const { error } = await admin.from('events').insert({ title, date: date || null, time, place, body: text });
        if (error) throw error;
        return json({ ok: true });
      }

      case 'delete_event': {
        const { error } = await admin.from('events').delete().eq('id', payload.id);
        if (error) throw error;
        return json({ ok: true });
      }

      case 'create_album': {
        const { name, date } = payload;
        if (!name) throw new Error('name is required');
        const { error } = await admin.from('albums').insert({ name, date: date || null });
        if (error) throw error;
        return json({ ok: true });
      }

      case 'delete_album': {
        const { id } = payload;
        const { data: photos, error: findErr } = await admin.from('photos').select('storage_path').eq('album_id', id);
        if (findErr) throw findErr;
        const paths = (photos || []).map((p) => p.storage_path).filter(Boolean);
        if (paths.length) await admin.storage.from(BUCKET).remove(paths);
        const { error } = await admin.from('albums').delete().eq('id', id); // cascades photo rows
        if (error) throw error;
        return json({ ok: true });
      }

      case 'upload_photo': {
        const { albumId, tags = [], caption = '', dataUrl } = payload;
        if (!albumId || !dataUrl) throw new Error('albumId and dataUrl are required');
        const { contentType, bytes } = dataUrlToBytes(dataUrl);
        const path = `photos/${crypto.randomUUID()}.jpg`;
        const { error: upErr } = await admin.storage.from(BUCKET).upload(path, bytes, { contentType, upsert: false });
        if (upErr) throw upErr;
        const { error } = await admin.from('photos').insert({ album_id: albumId, tags, caption, storage_path: path });
        if (error) throw error;
        return json({ ok: true });
      }

      case 'set_crew_name': {
        const { memberId, name } = payload;
        if (!memberId) throw new Error('memberId is required');
        const { error } = await admin
          .from('crew_overrides')
          .upsert({ member_id: memberId, name, updated_at: new Date().toISOString() }, { onConflict: 'member_id' });
        if (error) throw error;
        return json({ ok: true });
      }

      case 'upload_crew_poster': {
        const { memberId, name, dataUrl } = payload;
        if (!memberId || !dataUrl) throw new Error('memberId and dataUrl are required');
        const { contentType, bytes } = dataUrlToBytes(dataUrl);
        const path = `posters/${memberId}.jpg`;
        const { error: upErr } = await admin.storage.from(BUCKET).upload(path, bytes, { contentType, upsert: true });
        if (upErr) throw upErr;
        const { error } = await admin.from('crew_overrides').upsert(
          { member_id: memberId, name, has_img: true, storage_path: path, updated_at: new Date().toISOString() },
          { onConflict: 'member_id' },
        );
        if (error) throw error;
        return json({ ok: true });
      }

      case 'remove_crew_poster': {
        const { memberId } = payload;
        if (!memberId) throw new Error('memberId is required');
        await admin.storage.from(BUCKET).remove([`posters/${memberId}.jpg`]);
        const { error } = await admin
          .from('crew_overrides')
          .upsert(
            { member_id: memberId, has_img: false, storage_path: null, updated_at: new Date().toISOString() },
            { onConflict: 'member_id' },
          );
        if (error) throw error;
        return json({ ok: true });
      }

      case 'upload_highlight': {
        const { dataUrl } = payload;
        if (!dataUrl) throw new Error('dataUrl is required');
        const { contentType, bytes } = dataUrlToBytes(dataUrl);
        const { error: upErr } = await admin.storage
          .from(BUCKET)
          .upload('highlight/highlight.jpg', bytes, { contentType, upsert: true });
        if (upErr) throw upErr;
        const { error } = await admin
          .from('site_flags')
          .update({ highlight_img: true, highlight_updated_at: new Date().toISOString() })
          .eq('id', true);
        if (error) throw error;
        return json({ ok: true });
      }

      case 'set_charity_field': {
        const { charityId, field, value } = payload;
        if (!charityId || !['org', 'url', 'blurb'].includes(field)) throw new Error('bad charity field');
        const { error } = await admin
          .from('charity_overrides')
          .upsert({ charity_id: charityId, [field]: value, updated_at: new Date().toISOString() }, { onConflict: 'charity_id' });
        if (error) throw error;
        return json({ ok: true });
      }

      case 'change_passcode': {
        const { newPasscode } = payload;
        if (!newPasscode || newPasscode.length < 4) throw new Error('newPasscode must be at least 4 characters');
        const { error } = await admin.rpc('set_passcode', { input: newPasscode });
        if (error) throw error;
        return json({ ok: true });
      }

      case 'clear_samples': {
        await admin.from('photos').delete().eq('sample', true);
        await admin.from('albums').delete().eq('sample', true);
        await admin.from('events').delete().eq('sample', true);
        await admin.from('announcements').delete().eq('sample', true);
        return json({ ok: true });
      }

      default:
        return json({ ok: false, error: 'unknown_action' }, 400);
    }
  } catch (e) {
    return json({ ok: false, error: 'server_error', message: e instanceof Error ? e.message : String(e) }, 500);
  }
});
