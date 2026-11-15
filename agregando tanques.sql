/*****************************************************************************
  DATAFUELDW - Completar tanques por estación + mantenimientos iniciales

  LÓGICA
  ------
  Tanques requeridos por estación =
      MAX( @MinTanques , CEILING( CapacidadAlmacenamiento / @LitrosPorTanque ) )

  Con los valores por defecto (60.000 L por tanque, mínimo 2) queda:
      Est.1 (180.000 L) = 3     Est.6  (160.000 L) = 3
      Est.2 (220.000 L) = 4     Est.7  (130.000 L) = 3
      Est.3 (160.000 L) = 3     Est.8  (120.000 L) = 2
      Est.4 (140.000 L) = 3     Est.9  (100.000 L) = 2
      Est.5 (120.000 L) = 2     Est.10 (110.000 L) = 2

  Solo se insertan los tanques que FALTAN (requeridos - existentes), por lo
  que el script es idempotente: si se ejecuta dos veces, la segunda no agrega nada.

  Por cada tanque nuevo se crean 2 registros en dbo.Mantenimiento:
    1) Inspección de puesta en marcha  -> Ejecutado  (sept. 2026)
    2) Preventivo                      -> Programado (21 al 25 de oct. 2026)

  RESTRICCIÓN: CK_Mantenimiento_Corte2026 exige FechaProgramada y FechaEjecucion
  entre 2009-01-01 y 2026-10-25, por eso ninguna fecha puede pasar de ese corte.
*****************************************************************************/
USE [DATAFUELDW];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ====================== PARÁMETROS AJUSTABLES ==============================
DECLARE @LitrosPorTanque   DECIMAL(18,2) = 60000;      -- capacidad de referencia por tanque
DECLARE @MinTanques        INT           = 2;          -- mínimo de tanques por estación
DECLARE @FechaBaseAlta     DATE          = '2026-09-01'; -- inspecciones: 01/09 al 19/09/2026
DECLARE @FechaPreventivo   DATE          = '2026-10-21'; -- preventivos: 21/10 al 25/10/2026 (corte = 25/10)
-- ===========================================================================

BEGIN TRY
    BEGIN TRAN;

    DECLARE @MaxEquipo        INT = (SELECT ISNULL(MAX(IdEquipo), 0)        FROM dbo.Equipos);
    DECLARE @MaxMantenimiento INT = (SELECT ISNULL(MAX(IdMantenimiento), 0) FROM dbo.Mantenimiento);

    -- 1) Faltantes por estación --------------------------------------------
    ;WITH Requeridos AS (
        SELECT
            e.IdEstacion,
            CASE
                WHEN CEILING(e.CapacidadAlmacenamiento / @LitrosPorTanque) > @MinTanques
                    THEN CAST(CEILING(e.CapacidadAlmacenamiento / @LitrosPorTanque) AS INT)
                ELSE @MinTanques
            END AS TanquesRequeridos
        FROM dbo.Estaciones e
        WHERE e.Estado = 'Operativa'
    ),
    Existentes AS (
        SELECT IdEstacion, COUNT(*) AS TanquesActuales
        FROM dbo.Equipos
        WHERE TipoEquipo = 'Tanque'
        GROUP BY IdEstacion
    ),
    Faltantes AS (
        SELECT r.IdEstacion,
               r.TanquesRequeridos - ISNULL(x.TanquesActuales, 0) AS Faltan
        FROM Requeridos r
        LEFT JOIN Existentes x ON x.IdEstacion = r.IdEstacion
        WHERE r.TanquesRequeridos > ISNULL(x.TanquesActuales, 0)
    ),
    Numeros AS (   -- tabla de números 1..50 para "multiplicar" filas
        SELECT TOP (50) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
        FROM sys.all_objects
    )
    SELECT
        @MaxEquipo + ROW_NUMBER() OVER (ORDER BY f.IdEstacion, n.n) AS IdEquipo,
        f.IdEstacion,
        ROW_NUMBER() OVER (ORDER BY f.IdEstacion, n.n)              AS Orden
    INTO #NuevosTanques
    FROM Faltantes f
    JOIN Numeros n ON n.n <= f.Faltan;

    DECLARE @Nuevos INT = (SELECT COUNT(*) FROM #NuevosTanques);

    IF @Nuevos = 0
    BEGIN
        PRINT 'Todas las estaciones ya cumplen con la cantidad de tanques. No se insertó nada.';
        DROP TABLE #NuevosTanques;
        COMMIT TRAN;
        RETURN;
    END

    -- 2) Insertar los tanques nuevos en Equipos ----------------------------
    INSERT INTO dbo.Equipos (IdEquipo, IdEstacion, TipoEquipo, Modelo, Estado, UnidadOperativa)
    SELECT
        t.IdEquipo,
        t.IdEstacion,
        N'Tanque',
        N'EQ-' + CAST(1000 + t.IdEquipo AS NVARCHAR(10)),   -- mismo patrón: EQ-1065, EQ-1066...
        N'Operativo',
        'Litros'
    FROM #NuevosTanques t;

    -- 3) Mantenimientos: 2 registros por cada tanque nuevo -----------------
    -- 3a) Inspección de puesta en marcha (Ejecutada)
    INSERT INTO dbo.Mantenimiento
        (IdMantenimiento, IdEstacion, IdEquipo, Equipo, FechaProgramada, FechaEjecucion,
         TipoMantenimiento, Estado, CostoUSD, EsFechaCritica)
    SELECT
        @MaxMantenimiento + (2 * t.Orden - 1),
        t.IdEstacion,
        t.IdEquipo,
        N'Tanque (EQ-' + CAST(1000 + t.IdEquipo AS NVARCHAR(10)) + N')',
        DATEADD(DAY, t.Orden % 19, @FechaBaseAlta),
        DATEADD(DAY, t.Orden % 19, @FechaBaseAlta),
        N'Inspección',
        N'Ejecutado',
        CAST(1800.00 + (t.Orden % 10) * 95.50 AS DECIMAL(18,2)),
        0
    FROM #NuevosTanques t;

    -- 3b) Preventivo (Programado, sin costo ni ejecución aún; respeta el corte 25/10/2026)
    INSERT INTO dbo.Mantenimiento
        (IdMantenimiento, IdEstacion, IdEquipo, Equipo, FechaProgramada, FechaEjecucion,
         TipoMantenimiento, Estado, CostoUSD, EsFechaCritica)
    SELECT
        @MaxMantenimiento + (2 * t.Orden),
        t.IdEstacion,
        t.IdEquipo,
        N'Tanque (EQ-' + CAST(1000 + t.IdEquipo AS NVARCHAR(10)) + N')',
        DATEADD(DAY, t.Orden % 5, @FechaPreventivo),
        NULL,
        N'Preventivo',
        N'Programado',
        0.00,
        0
    FROM #NuevosTanques t;

    DROP TABLE #NuevosTanques;

    COMMIT TRAN;
    PRINT 'Tanques agregados: ' + CAST(@Nuevos AS VARCHAR(10))
        + ' | Mantenimientos agregados: ' + CAST(@Nuevos * 2 AS VARCHAR(10));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    IF OBJECT_ID('tempdb..#NuevosTanques') IS NOT NULL DROP TABLE #NuevosTanques;
    THROW;
END CATCH;
GO

/*************************** VERIFICACIÓN ************************************/

-- Tanques por estación vs. requeridos (la columna Estado debe decir OK en todas)
SELECT
    e.IdEstacion,
    e.NombreEstacion,
    e.CapacidadAlmacenamiento,
    COUNT(q.IdEquipo) AS TanquesActuales,
    CASE WHEN CEILING(e.CapacidadAlmacenamiento / 60000.0) > 2
         THEN CAST(CEILING(e.CapacidadAlmacenamiento / 60000.0) AS INT) ELSE 2 END AS TanquesRequeridos,
    CASE WHEN COUNT(q.IdEquipo) >= CASE WHEN CEILING(e.CapacidadAlmacenamiento / 60000.0) > 2
         THEN CEILING(e.CapacidadAlmacenamiento / 60000.0) ELSE 2 END THEN 'OK' ELSE 'FALTAN' END AS Estado
FROM dbo.Estaciones e
LEFT JOIN dbo.Equipos q ON q.IdEstacion = e.IdEstacion AND q.TipoEquipo = 'Tanque'
GROUP BY e.IdEstacion, e.NombreEstacion, e.CapacidadAlmacenamiento
ORDER BY e.IdEstacion;

-- Mantenimientos de los tanques nuevos (equipos con id > 64, el último original)
SELECT m.*
FROM dbo.Mantenimiento m
WHERE m.IdEquipo > 64 AND m.Equipo LIKE 'Tanque%'
ORDER BY m.IdEquipo, m.FechaProgramada;
GO


commit
