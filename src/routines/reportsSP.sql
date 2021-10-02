-- REPORTS STORED PROCEDURES
USE `docps-dev`;
DROP procedure IF EXISTS `GetTestplansTestcasesCountReport`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTestplansTestcasesCountReport` (
	IN idgrupo INTEGER,
  IN proyectos VARCHAR(100),
	IN desde VARCHAR(100),
	IN hasta VARCHAR(100)
)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = @text;
	  SELECT @full_error;
	 END;
    
    SET @idProyectos = CASE WHEN proyectos != '' THEN CONCAT(" AND d.idproyecto IN (",proyectos,")") ELSE '' END;
    
    SET @fechas = CASE WHEN desde != '' AND hasta != '' THEN CONCAT(" AND d.dataX BETWEEN STR_TO_DATE('",desde,"','%Y-%m-%d') AND STR_TO_DATE('",hasta,"','%Y-%m-%d')") WHEN desde != '' AND hasta = '' THEN CONCAT(" AND d.dataX >= STR_TO_DATE('",desde,"','%Y-%m-%d')") ELSE '' END;
    
    SET @reportData = REPLACE(REPLACE(REPLACE("
		SELECT 
			plot.*
			,@accPP := @accPP + plot.dataYtestplans AS totalTestplans
			,@accCP := @accCP + plot.dataYtestcases AS totalTestcases
		FROM (
			SELECT 
				d.dataX
				,CASE WHEN group_concat(d.dataYtestplans) IS NULL 
					THEN 0 
					ELSE group_concat(d.dataYtestplans) 
				END AS dataYtestplans
				,CASE WHEN group_concat(d.dataYtestcases) IS NULL 
					THEN 0 
					ELSE group_concat(d.dataYtestcases) 
				END AS dataYtestcases
				,d.idgrupo
				,d.idproyecto
			FROM (
			SELECT 
				DATE_FORMAT(pp.fecha_creacion, '%Y-%m-%d') AS dataX
				, COUNT(*) AS dataYtestplans
				, null AS dataYtestcases
				, pp.idgrupo AS idgrupo
				, pp.idproyecto AS idproyecto
			FROM planes pp
			GROUP BY DATE(pp.fecha_creacion) 
			UNION
            SELECT 
				DATE_FORMAT(cp.fecha_creacion, '%Y-%m-%d') AS dataX
				, null AS dataYtestplans
				, COUNT(*) AS dataYtestcases
				, cp.idgrupo AS idgrupo
				, cp.idproyecto AS idproyecto
			FROM casos_prueba cp
			WHERE 1=1
			GROUP BY DATE(cp.fecha_creacion)
			) d
			WHERE d.idgrupo = [grupo]
            [proyectos]
            [fechas]
			GROUP BY d.dataX
			ORDER BY d.dataX ASC
		) plot
		, (SELECT @accPP := 0) countPP
		, (SELECT @accCP := 0) countCP"
        ,'[grupo]',idgrupo)
        ,'[proyectos]',@idProyectos)
        ,'[fechas]',@fechas); 
    
	PREPARE searchQuery FROM @reportData;
	EXECUTE searchQuery;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetExecutionsReport`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetExecutionsReport` (
	IN idgrupo INTEGER,
  IN proyectos VARCHAR(512),
	IN desde VARCHAR(100),
	IN hasta VARCHAR(100)
)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = @text;
	  SELECT @full_error;
	 END;
    
    SET @idProyectos = CASE WHEN proyectos != '' THEN CONCAT(" AND e.idproyecto IN (",proyectos,")") ELSE '' END;
    
    SET @fechas = CASE WHEN desde != '' AND hasta != '' THEN CONCAT(" AND e.fecha_ejecucion BETWEEN STR_TO_DATE('",desde,"','%Y-%m-%d') AND STR_TO_DATE('",hasta,"','%Y-%m-%d')") WHEN desde != '' AND hasta = '' THEN CONCAT(" AND e.fecha_ejecucion >= STR_TO_DATE('",desde,"','%Y-%m-%d')") ELSE '' END;
    
    SET @reportData = REPLACE(REPLACE(REPLACE("
		SELECT 
			plot.*
			,@acc := @acc + plot.dataY AS totalExecutions
		FROM (
			SELECT 
				DATE_FORMAT(e.fecha_ejecucion, '%Y-%m-%d') AS dataX
				, COUNT(*) AS dataY
				, e.idgrupo AS idgrupo
				, e.idproyecto AS idproyecto
			FROM ejecuciones e
			WHERE e.idgrupo = [grupo]
            [proyectos]
            [fechas]
			GROUP BY DATE(e.fecha_ejecucion) 
			ORDER BY e.fecha_ejecucion ASC
		) plot
		, (SELECT @acc := 0) countE
        "
        ,'[grupo]',idgrupo)
        ,'[proyectos]',@idProyectos)
        ,'[fechas]',@fechas); 
    
	PREPARE searchQuery FROM @reportData;
	EXECUTE searchQuery;
END$$
DELIMITER ;



USE `docps-dev`;
DROP procedure IF EXISTS `GetCurrentGroupStats`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetCurrentGroupStats` (
	IN id INTEGER
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
    
	SELECT 
		(SELECT COUNT(*) FROM usuarios_grupos ug WHERE ug.idgrupo = g.idgrupo) AS memberCount,
        a.nombre AS avatar,
        da.name AS defavatar,
        (SELECT COUNT(*) FROM planes pp WHERE pp.idgrupo = g.idgrupo) AS testplansCount,
        (SELECT SUM(op.total_casos_generados) FROM operaciones_exportacion op WHERE op.idgrupo = g.idgrupo GROUP BY op.idgrupo) AS testcasesCount
	FROM grupos g
    LEFT JOIN archivos a ON g.idarchivo_img = a.idarchivo
    LEFT JOIN default_avatar da ON g.iddefavatar = da.iddefavatar
    WHERE g.idgrupo = id;		
END$$
DELIMITER ;