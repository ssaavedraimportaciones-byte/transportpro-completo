-- Grant superadmin role to Sebastian Saavedra
UPDATE usuarios
SET rol = 'superadmin'
WHERE email = 'ssaavedra.importaciones@gmail.com'
AND empresa_id IS NULL;

-- Verify the update
SELECT id, email, rol, empresa_id FROM usuarios WHERE email = 'ssaavedra.importaciones@gmail.com';
