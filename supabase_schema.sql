-- ==========================================
-- SCRIPT DE INICIALIZACIÓN SIMPLIFICADO: LA MÁXIMA 88.5 FM
-- Ejecuta este script en el editor SQL de Supabase.
-- ==========================================

-- 1. Tabla de Perfiles de Usuario (users)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    nombre TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    foto TEXT,
    is_admin BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Habilitar RLS en la tabla users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS para users
CREATE POLICY "Permitir lectura pública de perfiles" 
ON public.users FOR SELECT 
USING (true);

CREATE POLICY "Permitir actualización propia" 
ON public.users FOR UPDATE 
USING (auth.uid() = id);

-- Trigger para crear automáticamente el perfil de usuario tras el registro
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, nombre, email, foto, is_admin)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'nombre', 'Oyente Máxima'),
        new.email,
        new.raw_user_meta_data->>'foto',
        false -- Por defecto, ningún usuario es admin
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 2. Tabla de Programas
CREATE TABLE public.programas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    locutor TEXT NOT NULL,
    imagen TEXT,
    hora_inicio TIME WITHOUT TIME ZONE NOT NULL,
    hora_fin TIME WITHOUT TIME ZONE NOT NULL
);

ALTER TABLE public.programas ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS para programas
CREATE POLICY "Permitir lectura pública de programas" 
ON public.programas FOR SELECT 
USING (true);

CREATE POLICY "Solo admins pueden modificar programas" 
ON public.programas FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() AND users.is_admin = true
    )
);


-- 3. Tabla de Configuración Global (Configuracion)
CREATE TABLE public.configuracion (
    id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1), -- Solo permitimos un registro de configuración global
    stream_radio TEXT NOT NULL,
    stream_tv TEXT NOT NULL,
    facebook TEXT,
    instagram TEXT,
    youtube TEXT,
    tiktok TEXT,
    twitter TEXT
);

-- Insertar configuración inicial por defecto si no existe
INSERT INTO public.configuracion (id, stream_radio, stream_tv, facebook, instagram, youtube, tiktok, twitter)
VALUES (
    1, 
    'https://streaming.lamaximafm.com:8000/stream', -- URL Streaming oficial por defecto
    'https://streaming.lamaximafm.com:2020/hls/lamaximatv/lamaximatv.m3u8', -- URL Live TV HLS oficial por defecto
    'https://www.facebook.com/share/18qKUQ9LT2/?mibextid=wwXIfr',
    'https://www.instagram.com/lamaxima88.9?igsh=MXRtZWlwampkdHFsYw==',
    'https://www.youtube.com/@lamaxima88',
    'https://tiktok.com/@lamaxima885',
    'https://twitter.com/lamaxima885'
) ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.configuracion ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS para configuracion
CREATE POLICY "Permitir lectura pública de configuración" 
ON public.configuracion FOR SELECT 
USING (true);

CREATE POLICY "Solo admins pueden modificar la configuración" 
ON public.configuracion FOR UPDATE 
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE users.id = auth.uid() AND users.is_admin = true
    )
);

-- =======================================================
-- NOTA IMPORTANTE PARA EL ALMACENAMIENTO DE ARCHIVOS:
-- =======================================================
-- Debes crear un "Bucket" público en Supabase Storage:
-- 1. 'imagenes' (para locutores, carátulas y fotos de perfil)
--
-- Asegúrate de establecer las políticas de acceso en Supabase Storage:
-- - Lectura: Permitida para todos de forma pública (SELECT).
-- - Escritura/Edición: Permitida solo para usuarios autenticados con rol de administrador.
-- =======================================================
