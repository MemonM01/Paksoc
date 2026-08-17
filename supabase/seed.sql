-- One-time sample content, run once in the SQL Editor right after schema.sql.
-- Reproduces the placeholder content the site used to generate client-side
-- in seed()/sampleImg() (index.html), so a freshly deployed site isn't
-- empty before the committee posts anything. Dates are computed relative
-- to whenever this actually runs (matches the old iso(d) = today + d days).
-- Safe to run only once — re-running duplicates rows (no unique constraint
-- on title/content is intended, since real announcements/events can repeat).

do $$
declare
  alb_id uuid;
begin
  insert into public.albums (name, date, sample)
    values ('Freshers'' Welcome', current_date - 14, true)
    returning id into alb_id;

  insert into public.announcements (title, body, date, pinned, sample) values
    ('Group chat for 2026/27 is open',
     'New year, new link — the old chat is archived. Join through the button at the top so you get ticket drops first.',
     current_date - 2, true, true),
    ('Freshers Week commencing week 21st September', '', current_date - 6, false, true);

  insert into public.events (title, date, time, place, body, sample) values
    ('Freshers'' Chai & Meet', current_date + 9, '6:00pm', 'LUU, Room 6',
     'Free chai and samosas, no tickets needed. Bring someone who hasn''t met anyone yet.', true),
    ('PakSoc vs IndSoc — five-a-side', current_date + 17, '2:00pm', 'The Edge, pitch 3',
     'Annual grudge match. £2 on the door, all abilities, subs guaranteed a run.', true),
    ('Culture Night', current_date + 38, '7:00pm', 'Riley Smith Hall',
     'Food, dance, qawwali and the fashion walk. Tickets go live two weeks before — they sell out.', true);

  insert into public.photos (album_id, caption, tags, external_src, sample)
    select alb_id, 'Freshers'' Welcome', array['sample'], src, true
    from unnest(array[
'data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22700%22%20height%3D%22700%22%3E%0A%20%20%3Cdefs%3E%3ClinearGradient%20id%3D%22g%22%20x1%3D%220%22%20y1%3D%220%22%20x2%3D%221%22%20y2%3D%221%22%3E%3Cstop%20offset%3D%220%22%20stop-color%3D%22%23FF4D85%22%2F%3E%3Cstop%20offset%3D%221%22%20stop-color%3D%22%23E7A93A%22%2F%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E%0A%20%20%3Crect%20width%3D%22700%22%20height%3D%22700%22%20fill%3D%22url(%23g)%22%2F%3E%0A%20%20%3Cg%20fill%3D%22rgba(255%2C255%2C255%2C.15)%22%3E%3Ccircle%20cx%3D%22140%22%20cy%3D%22200%22%20r%3D%22120%22%2F%3E%3Ccircle%20cx%3D%22520%22%20cy%3D%22480%22%20r%3D%2290%22%2F%3E%3C%2Fg%3E%0A%20%20%3Cpath%20d%3D%22M0%20560%20Q175%20470%20350%20560%20T700%20560%22%20fill%3D%22none%22%20stroke%3D%22rgba(255%2C255%2C255%2C.28)%22%20stroke-width%3D%223%22%2F%3E%3C%2Fsvg%3E',
'data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22700%22%20height%3D%22700%22%3E%0A%20%20%3Cdefs%3E%3ClinearGradient%20id%3D%22g%22%20x1%3D%220%22%20y1%3D%220%22%20x2%3D%221%22%20y2%3D%221%22%3E%3Cstop%20offset%3D%220%22%20stop-color%3D%22%23D06A28%22%2F%3E%3Cstop%20offset%3D%221%22%20stop-color%3D%22%23331546%22%2F%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E%0A%20%20%3Crect%20width%3D%22700%22%20height%3D%22700%22%20fill%3D%22url(%23g)%22%2F%3E%0A%20%20%3Cg%20fill%3D%22rgba(255%2C255%2C255%2C.15)%22%3E%3Ccircle%20cx%3D%22187%22%20cy%3D%22231%22%20r%3D%22120%22%2F%3E%3Ccircle%20cx%3D%22491%22%20cy%3D%22497%22%20r%3D%2290%22%2F%3E%3C%2Fg%3E%0A%20%20%3Cpath%20d%3D%22M0%20572%20Q175%20479%20350%20572%20T700%20572%22%20fill%3D%22none%22%20stroke%3D%22rgba(255%2C255%2C255%2C.28)%22%20stroke-width%3D%223%22%2F%3E%3C%2Fsvg%3E',
'data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22700%22%20height%3D%22700%22%3E%0A%20%20%3Cdefs%3E%3ClinearGradient%20id%3D%22g%22%20x1%3D%220%22%20y1%3D%220%22%20x2%3D%221%22%20y2%3D%221%22%3E%3Cstop%20offset%3D%220%22%20stop-color%3D%22%23E7A93A%22%2F%3E%3Cstop%20offset%3D%221%22%20stop-color%3D%22%239C3F22%22%2F%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E%0A%20%20%3Crect%20width%3D%22700%22%20height%3D%22700%22%20fill%3D%22url(%23g)%22%2F%3E%0A%20%20%3Cg%20fill%3D%22rgba(255%2C255%2C255%2C.15)%22%3E%3Ccircle%20cx%3D%22234%22%20cy%3D%22262%22%20r%3D%22120%22%2F%3E%3Ccircle%20cx%3D%22462%22%20cy%3D%22514%22%20r%3D%2290%22%2F%3E%3C%2Fg%3E%0A%20%20%3Cpath%20d%3D%22M0%20584%20Q175%20488%20350%20584%20T700%20584%22%20fill%3D%22none%22%20stroke%3D%22rgba(255%2C255%2C255%2C.28)%22%20stroke-width%3D%223%22%2F%3E%3C%2Fsvg%3E',
'data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22700%22%20height%3D%22700%22%3E%0A%20%20%3Cdefs%3E%3ClinearGradient%20id%3D%22g%22%20x1%3D%220%22%20y1%3D%220%22%20x2%3D%221%22%20y2%3D%221%22%3E%3Cstop%20offset%3D%220%22%20stop-color%3D%22%235E2130%22%2F%3E%3Cstop%20offset%3D%221%22%20stop-color%3D%22%23EE9B45%22%2F%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E%0A%20%20%3Crect%20width%3D%22700%22%20height%3D%22700%22%20fill%3D%22url(%23g)%22%2F%3E%0A%20%20%3Cg%20fill%3D%22rgba(255%2C255%2C255%2C.15)%22%3E%3Ccircle%20cx%3D%22281%22%20cy%3D%22293%22%20r%3D%22120%22%2F%3E%3Ccircle%20cx%3D%22433%22%20cy%3D%22531%22%20r%3D%2290%22%2F%3E%3C%2Fg%3E%0A%20%20%3Cpath%20d%3D%22M0%20596%20Q175%20497%20350%20596%20T700%20596%22%20fill%3D%22none%22%20stroke%3D%22rgba(255%2C255%2C255%2C.28)%22%20stroke-width%3D%223%22%2F%3E%3C%2Fsvg%3E',
'data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22700%22%20height%3D%22700%22%3E%0A%20%20%3Cdefs%3E%3ClinearGradient%20id%3D%22g%22%20x1%3D%220%22%20y1%3D%220%22%20x2%3D%221%22%20y2%3D%221%22%3E%3Cstop%20offset%3D%220%22%20stop-color%3D%22%23331546%22%2F%3E%3Cstop%20offset%3D%221%22%20stop-color%3D%22%23FF4D85%22%2F%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E%0A%20%20%3Crect%20width%3D%22700%22%20height%3D%22700%22%20fill%3D%22url(%23g)%22%2F%3E%0A%20%20%3Cg%20fill%3D%22rgba(255%2C255%2C255%2C.15)%22%3E%3Ccircle%20cx%3D%22328%22%20cy%3D%22324%22%20r%3D%22120%22%2F%3E%3Ccircle%20cx%3D%22404%22%20cy%3D%22548%22%20r%3D%2290%22%2F%3E%3C%2Fg%3E%0A%20%20%3Cpath%20d%3D%22M0%20608%20Q175%20506%20350%20608%20T700%20608%22%20fill%3D%22none%22%20stroke%3D%22rgba(255%2C255%2C255%2C.28)%22%20stroke-width%3D%223%22%2F%3E%3C%2Fsvg%3E',
'data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22700%22%20height%3D%22700%22%3E%0A%20%20%3Cdefs%3E%3ClinearGradient%20id%3D%22g%22%20x1%3D%220%22%20y1%3D%220%22%20x2%3D%221%22%20y2%3D%221%22%3E%3Cstop%20offset%3D%220%22%20stop-color%3D%22%239C3F22%22%2F%3E%3Cstop%20offset%3D%221%22%20stop-color%3D%22%23E7A93A%22%2F%3E%3C%2FlinearGradient%3E%3C%2Fdefs%3E%0A%20%20%3Crect%20width%3D%22700%22%20height%3D%22700%22%20fill%3D%22url(%23g)%22%2F%3E%0A%20%20%3Cg%20fill%3D%22rgba(255%2C255%2C255%2C.15)%22%3E%3Ccircle%20cx%3D%22375%22%20cy%3D%22355%22%20r%3D%22120%22%2F%3E%3Ccircle%20cx%3D%22375%22%20cy%3D%22565%22%20r%3D%2290%22%2F%3E%3C%2Fg%3E%0A%20%20%3Cpath%20d%3D%22M0%20620%20Q175%20515%20350%20620%20T700%20620%22%20fill%3D%22none%22%20stroke%3D%22rgba(255%2C255%2C255%2C.28)%22%20stroke-width%3D%223%22%2F%3E%3C%2Fsvg%3E'
    ]) as src;

  update public.site_flags set seeded = true where id = true;
end $$;
