--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.0

-- Started on 2026-07-07 02:09:44

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 64 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- TOC entry 3919 (class 0 OID 0)
-- Dependencies: 64
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 473 (class 1255 OID 17659)
-- Name: capitalize(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.capitalize(text text) RETURNS text
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN INITCAP(REPLACE(text, '_', ' '));
END;
$$;


--
-- TOC entry 471 (class 1255 OID 17592)
-- Name: generate_ticket_number(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_ticket_number() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.ticket_number :=
    'TKT-' || TO_CHAR(NOW(), 'YYYY') || '-' ||
    LPAD(NEXTVAL('public.ticket_number_seq')::TEXT, 4, '0');
  RETURN NEW;
END;
$$;


--
-- TOC entry 470 (class 1255 OID 17562)
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, role, department)
  VALUES (
    NEW.id,
    COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'name'), ''), split_part(NEW.email,'@',1)),
    COALESCE(NEW.email, ''),
    'user',
    NULLIF(TRIM(COALESCE(NEW.raw_user_meta_data->>'department', '')), '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;


--
-- TOC entry 476 (class 1255 OID 17664)
-- Name: notify_ticket_assigned(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_ticket_assigned() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
BEGIN
  -- Hanya proses jika assigned_to berubah dan ada nilai baru
  IF NEW.assigned_to IS NULL THEN
    RETURN NEW;
  END IF;
  IF OLD.assigned_to IS NOT DISTINCT FROM NEW.assigned_to THEN
    RETURN NEW;
  END IF;

  -- Kirim notifikasi ke assignee baru
  INSERT INTO public.notifications (user_id, title, body, ticket_id, type)
  VALUES (
    NEW.assigned_to,
    'Tiket ditugaskan kepada Anda',
    'Tiket ' || NEW.ticket_number || ' — "' || LEFT(NEW.title, 60) || '" telah ditugaskan kepada Anda.',
    NEW.id,
    'ticket_assigned'
  );

  RETURN NEW;
END;
$$;


--
-- TOC entry 477 (class 1255 OID 17666)
-- Name: notify_ticket_commented(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_ticket_commented() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
DECLARE
  v_ticket        public.tickets%ROWTYPE;
  v_author_name   TEXT;
  v_recipient_id  UUID;
BEGIN
  -- Ambil data tiket terkait
  SELECT * INTO v_ticket FROM public.tickets WHERE id = NEW.ticket_id;
  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  -- Ambil nama author komentar
  SELECT name INTO v_author_name FROM public.profiles WHERE id = NEW.author_id;
  v_author_name := COALESCE(v_author_name, 'Seseorang');

  -- Tentukan penerima notifikasi
  IF NEW.author_id = v_ticket.created_by THEN
    -- Creator yang komentar → notif ke assignee (jika ada dan bukan creator sendiri)
    IF v_ticket.assigned_to IS NOT NULL AND v_ticket.assigned_to <> NEW.author_id THEN
      v_recipient_id := v_ticket.assigned_to;
    ELSE
      -- Tidak ada assignee → tidak ada notifikasi (belum ada yang bisa dinotif)
      RETURN NEW;
    END IF;
  ELSE
    -- Assignee/staff yang komentar → notif ke creator tiket
    -- Kecuali komentar internal (jangan bocorkan ke user biasa)
    IF NEW.is_internal THEN
      RETURN NEW;
    END IF;
    v_recipient_id := v_ticket.created_by;
  END IF;

  -- Jangan kirim notif ke diri sendiri
  IF v_recipient_id = NEW.author_id THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, title, body, ticket_id, type)
  VALUES (
    v_recipient_id,
    'Komentar baru pada tiket',
    v_author_name || ' membalas tiket ' || v_ticket.ticket_number || ': "' ||
      LEFT(NEW.content, 80) || CASE WHEN LENGTH(NEW.content) > 80 THEN '..."' ELSE '"' END,
    NEW.ticket_id,
    'new_comment'
  );

  RETURN NEW;
END;
$$;


--
-- TOC entry 474 (class 1255 OID 17660)
-- Name: notify_ticket_created(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_ticket_created() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
BEGIN
  INSERT INTO public.notifications (user_id, title, body, ticket_id, type)
  VALUES (
    NEW.created_by,
    'Tiket berhasil dibuat',
    'Tiket ' || NEW.ticket_number || ' — "' || LEFT(NEW.title, 60) || '" telah diterima.',
    NEW.id,
    'ticket_created'
  );
  RETURN NEW;
END;
$$;


--
-- TOC entry 475 (class 1255 OID 17662)
-- Name: notify_ticket_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notify_ticket_status() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
DECLARE
  v_status_label TEXT;
BEGIN
  -- Hanya proses jika status benar-benar berubah
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  v_status_label := CASE NEW.status
    WHEN 'open'        THEN 'Open'
    WHEN 'in_progress' THEN 'In Progress'
    WHEN 'resolved'    THEN 'Selesai'
    WHEN 'closed'      THEN 'Ditutup'
    ELSE NEW.status
  END;

  -- Kirim ke creator tiket
  INSERT INTO public.notifications (user_id, title, body, ticket_id, type)
  VALUES (
    NEW.created_by,
    'Status tiket diperbarui',
    'Tiket ' || NEW.ticket_number || ' kini berstatus "' || v_status_label || '".',
    NEW.id,
    'status_updated'
  );

  -- Jika ada assignee dan bukan creator yang sama, kirim juga ke assignee
  IF NEW.assigned_to IS NOT NULL AND NEW.assigned_to <> NEW.created_by THEN
    INSERT INTO public.notifications (user_id, title, body, ticket_id, type)
    VALUES (
      NEW.assigned_to,
      'Status tiket diperbarui',
      'Tiket ' || NEW.ticket_number || ' kini berstatus "' || v_status_label || '".',
      NEW.id,
      'status_updated'
    );
  END IF;

  RETURN NEW;
END;
$$;


--
-- TOC entry 472 (class 1255 OID 17594)
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'public'
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 357 (class 1259 OID 17637)
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    ticket_id uuid,
    is_read boolean DEFAULT false NOT NULL,
    type text DEFAULT 'ticket_created'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notifications_type_check CHECK ((type = ANY (ARRAY['ticket_created'::text, 'status_updated'::text, 'new_comment'::text, 'ticket_assigned'::text])))
);


--
-- TOC entry 352 (class 1259 OID 17544)
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    email text DEFAULT ''::text NOT NULL,
    avatar_url text,
    role text DEFAULT 'user'::text NOT NULL,
    department text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    is_active boolean DEFAULT true,
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['user'::text, 'helpdesk'::text, 'admin'::text])))
);


--
-- TOC entry 356 (class 1259 OID 17616)
-- Name: ticket_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_attachments (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    ticket_id uuid NOT NULL,
    file_name text NOT NULL,
    file_url text NOT NULL,
    file_type text DEFAULT 'file'::text NOT NULL,
    file_size integer DEFAULT 0 NOT NULL,
    uploaded_by uuid NOT NULL,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 355 (class 1259 OID 17596)
-- Name: ticket_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_comments (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    ticket_id uuid NOT NULL,
    author_id uuid NOT NULL,
    content text NOT NULL,
    is_internal boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- TOC entry 358 (class 1259 OID 33888)
-- Name: ticket_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ticket_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    action text NOT NULL,
    old_value text,
    new_value text,
    performed_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- TOC entry 353 (class 1259 OID 17564)
-- Name: ticket_number_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ticket_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 354 (class 1259 OID 17565)
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tickets (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    ticket_number text NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    priority text DEFAULT 'medium'::text NOT NULL,
    category text DEFAULT 'Lainnya'::text NOT NULL,
    created_by uuid NOT NULL,
    assigned_to uuid,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tickets_priority_check CHECK ((priority = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text]))),
    CONSTRAINT tickets_status_check CHECK ((status = ANY (ARRAY['open'::text, 'in_progress'::text, 'resolved'::text, 'closed'::text])))
);

--
-- TOC entry 3712 (class 2606 OID 17648)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 3702 (class 2606 OID 17556)
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- TOC entry 3710 (class 2606 OID 17626)
-- Name: ticket_attachments ticket_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_attachments
    ADD CONSTRAINT ticket_attachments_pkey PRIMARY KEY (id);


--
-- TOC entry 3708 (class 2606 OID 17605)
-- Name: ticket_comments ticket_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_comments
    ADD CONSTRAINT ticket_comments_pkey PRIMARY KEY (id);


--
-- TOC entry 3715 (class 2606 OID 33896)
-- Name: ticket_history ticket_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_history
    ADD CONSTRAINT ticket_history_pkey PRIMARY KEY (id);


--
-- TOC entry 3704 (class 2606 OID 17579)
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- TOC entry 3706 (class 2606 OID 17581)
-- Name: tickets tickets_ticket_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_ticket_number_key UNIQUE (ticket_number);


--
-- TOC entry 3713 (class 1259 OID 33907)
-- Name: idx_ticket_history_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ticket_history_ticket_id ON public.ticket_history USING btree (ticket_id);


--
-- TOC entry 3727 (class 2620 OID 17665)
-- Name: tickets on_ticket_assigned; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_ticket_assigned AFTER UPDATE OF assigned_to ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.notify_ticket_assigned();


--
-- TOC entry 3732 (class 2620 OID 17667)
-- Name: ticket_comments on_ticket_commented; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_ticket_commented AFTER INSERT ON public.ticket_comments FOR EACH ROW EXECUTE FUNCTION public.notify_ticket_commented();


--
-- TOC entry 3728 (class 2620 OID 17661)
-- Name: tickets on_ticket_created; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_ticket_created AFTER INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.notify_ticket_created();


--
-- TOC entry 3729 (class 2620 OID 17663)
-- Name: tickets on_ticket_status_changed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER on_ticket_status_changed AFTER UPDATE OF status ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.notify_ticket_status();


--
-- TOC entry 3730 (class 2620 OID 17593)
-- Name: tickets set_ticket_number; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_ticket_number BEFORE INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.generate_ticket_number();


--
-- TOC entry 3731 (class 2620 OID 17595)
-- Name: tickets tickets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tickets_updated_at BEFORE UPDATE ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- TOC entry 3723 (class 2606 OID 17654)
-- Name: notifications notifications_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE SET NULL;


--
-- TOC entry 3724 (class 2606 OID 17649)
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- TOC entry 3716 (class 2606 OID 17557)
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- TOC entry 3721 (class 2606 OID 17627)
-- Name: ticket_attachments ticket_attachments_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_attachments
    ADD CONSTRAINT ticket_attachments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- TOC entry 3722 (class 2606 OID 17632)
-- Name: ticket_attachments ticket_attachments_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_attachments
    ADD CONSTRAINT ticket_attachments_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.profiles(id);


--
-- TOC entry 3719 (class 2606 OID 17611)
-- Name: ticket_comments ticket_comments_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_comments
    ADD CONSTRAINT ticket_comments_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id);


--
-- TOC entry 3720 (class 2606 OID 17606)
-- Name: ticket_comments ticket_comments_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_comments
    ADD CONSTRAINT ticket_comments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- TOC entry 3725 (class 2606 OID 33902)
-- Name: ticket_history ticket_history_performed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_history
    ADD CONSTRAINT ticket_history_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.profiles(id);


--
-- TOC entry 3726 (class 2606 OID 33897)
-- Name: ticket_history ticket_history_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_history
    ADD CONSTRAINT ticket_history_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- TOC entry 3717 (class 2606 OID 17587)
-- Name: tickets tickets_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id);


--
-- TOC entry 3718 (class 2606 OID 17582)
-- Name: tickets tickets_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- TOC entry 3902 (class 3256 OID 33909)
-- Name: ticket_history Authenticated users can insert history; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert history" ON public.ticket_history FOR INSERT WITH CHECK ((auth.uid() IS NOT NULL));


--
-- TOC entry 3901 (class 3256 OID 33908)
-- Name: ticket_history Everyone can read ticket history; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can read ticket history" ON public.ticket_history FOR SELECT USING (true);


--
-- TOC entry 3896 (class 3256 OID 17677)
-- Name: ticket_attachments attach_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY attach_insert ON public.ticket_attachments FOR INSERT TO authenticated WITH CHECK ((auth.uid() = uploaded_by));


--
-- TOC entry 3895 (class 3256 OID 17676)
-- Name: ticket_attachments attach_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY attach_select ON public.ticket_attachments FOR SELECT TO authenticated USING (true);


--
-- TOC entry 3894 (class 3256 OID 17675)
-- Name: ticket_comments comments_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY comments_insert ON public.ticket_comments FOR INSERT TO authenticated WITH CHECK ((auth.uid() = author_id));


--
-- TOC entry 3893 (class 3256 OID 17674)
-- Name: ticket_comments comments_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY comments_select ON public.ticket_comments FOR SELECT TO authenticated USING (true);


--
-- TOC entry 3899 (class 3256 OID 33871)
-- Name: profiles free_update_profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY free_update_profile ON public.profiles FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- TOC entry 3900 (class 3256 OID 33872)
-- Name: tickets free_update_tickets; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY free_update_tickets ON public.tickets FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- TOC entry 3897 (class 3256 OID 17678)
-- Name: notifications notif_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notif_select ON public.notifications FOR SELECT TO authenticated USING ((auth.uid() = user_id));


--
-- TOC entry 3898 (class 3256 OID 17679)
-- Name: notifications notif_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notif_update ON public.notifications FOR UPDATE TO authenticated USING ((auth.uid() = user_id));


--
-- TOC entry 3885 (class 0 OID 17637)
-- Dependencies: 357
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 3881 (class 0 OID 17544)
-- Dependencies: 352
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 3888 (class 3256 OID 17669)
-- Name: profiles profiles_insert_service; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_insert_service ON public.profiles FOR INSERT WITH CHECK (true);


--
-- TOC entry 3887 (class 3256 OID 17668)
-- Name: profiles profiles_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_select ON public.profiles FOR SELECT USING (true);


--
-- TOC entry 3889 (class 3256 OID 17670)
-- Name: profiles profiles_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_update ON public.profiles FOR UPDATE USING ((auth.uid() = id));


--
-- TOC entry 3884 (class 0 OID 17616)
-- Dependencies: 356
-- Name: ticket_attachments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ticket_attachments ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 3883 (class 0 OID 17596)
-- Dependencies: 355
-- Name: ticket_comments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ticket_comments ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 3886 (class 0 OID 33888)
-- Dependencies: 358
-- Name: ticket_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.ticket_history ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 3882 (class 0 OID 17565)
-- Dependencies: 354
-- Name: tickets; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 3891 (class 3256 OID 17672)
-- Name: tickets tickets_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tickets_insert ON public.tickets FOR INSERT TO authenticated WITH CHECK ((auth.uid() = created_by));


--
-- TOC entry 3890 (class 3256 OID 17671)
-- Name: tickets tickets_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tickets_select ON public.tickets FOR SELECT TO authenticated USING (true);


--
-- TOC entry 3892 (class 3256 OID 17673)
-- Name: tickets tickets_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tickets_update ON public.tickets FOR UPDATE TO authenticated USING (true);


-- Completed on 2026-07-07 02:09:57

--
-- PostgreSQL database dump complete
--

