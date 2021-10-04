-- TESTPLANS STORED PROCEDURES
USE `docps-dev`;
DROP procedure IF EXISTS `InsertTestplan`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertTestplan` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN nombre VARCHAR(255),
    IN descripcion VARCHAR(512)
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
        
	START TRANSACTION;
        INSERT INTO `docps-dev`.`planes`(`fecha_creacion`,`nombre`,`descripcion`,`idgrupo`,`idproyecto`)
		VALUES(SYSDATE(),nombre,descripcion,idgrupo,idproyecto);

	COMMIT;
		SELECT 'TESTPLAN CREATED' AS message, 1 AS success, last_insert_id() AS id;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `AddTagToTestplan`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `AddTagToTestplan` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
    IN etiqueta VARCHAR(255)
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
        
	START TRANSACTION;
        SELECT COUNT(*) INTO @cuenta FROM `docps-dev`.`etiquetas` WHERE UPPER(valor) = UPPER(etiqueta);
        IF @cuenta = 0 THEN
			INSERT INTO `docps-dev`.`etiquetas`(`valor`) VALUES (UPPER(etiqueta));
			INSERT INTO `docps-dev`.`planes_etiquetas`(`idgrupo`,`idproyecto`,`idplan`,`idetiqueta`) VALUES (idgrupo,idproyecto,idplan,last_insert_id());
        ELSE
			SELECT idetiqueta INTO @idetiqueta FROM `docps-dev`.`etiquetas` WHERE UPPER(valor) = UPPER(etiqueta) LIMIT 1;
			INSERT INTO `docps-dev`.`planes_etiquetas`(`idgrupo`,`idproyecto`,`idplan`,`idetiqueta`) VALUES (idgrupo,idproyecto,idplan,@idetiqueta);	
        END IF;

	COMMIT;
		SELECT 'TAG ADDED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `SearchTestplans`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `SearchTestplans` (
	IN idgrupo INTEGER,
    IN proyectos VARCHAR(100),
	IN nombre VARCHAR(255),
	IN desde VARCHAR(100),
	IN hasta VARCHAR(100),
	IN etiquetas VARCHAR(512)
)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = @text;
	  SELECT @full_error;
	 END;
     
	SET @idgrupo = CONCAT(" AND p.idgrupo = '",idgrupo,"'");
    
    SET @proyectos = CASE WHEN proyectos != '' THEN CONCAT(" AND p.idproyecto IN (",proyectos,")") ELSE '' END;
    
    SET @nombre = CASE WHEN nombre != '' THEN CONCAT(" AND p.nombre LIKE '%",nombre,"%'") ELSE '' END;
    
	SET @fechas = CASE WHEN desde != '' AND hasta != '' THEN CONCAT(" AND p.fecha_creacion BETWEEN STR_TO_DATE('",desde,"','%Y-%m-%d') AND STR_TO_DATE('",hasta,"','%Y-%m-%d')") WHEN desde != '' AND hasta = '' THEN CONCAT(" AND p.fecha_creacion > STR_TO_DATE('",desde,"','%Y-%m-%d')") ELSE '' END;
                        
	SET @etiquetas = CASE WHEN etiquetas != '' THEN CONCAT(" 
    WHERE plans.id IN (
		SELECT
			CONCAT(p.idgrupo,'.',p.idproyecto,'.',p.idplan) AS id
		FROM planes p
		LEFT JOIN planes_etiquetas pe ON p.idgrupo = pe.idgrupo AND p.idproyecto = pe.idproyecto AND p.idplan = pe.idplan
		LEFT JOIN etiquetas e ON pe.idetiqueta = e.idetiqueta
		WHERE e.valor IN (",etiquetas,")
	)") ELSE '' END;
                    
	SET @getPlanes = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE("    
		SELECT plans.*
		FROM (
			SELECT 
				CONCAT(p.idgrupo,'.',p.idproyecto,'.',p.idplan) AS id
				,@curRank := @curRank + 1 AS `key`
				,p.nombre AS testplanName
				,p.descripcion AS description
				-- ,e.valor AS tag
				,GROUP_CONCAT(e.valor SEPARATOR ',') AS tags
				,DATE_FORMAT(p.fecha_creacion, '%Y-%m-%d') AS createdOn
				,ep.status AS `status`
				,pr.nombre AS projectName
			FROM planes p 
			LEFT JOIN estado_planes ep ON p.idgrupo = ep.idgrupo AND p.idproyecto = ep.idproyecto AND p.idplan = ep.idplan
			LEFT JOIN planes_etiquetas pe ON p.idgrupo = pe.idgrupo AND p.idproyecto = pe.idproyecto AND p.idplan = pe.idplan
			LEFT JOIN etiquetas e ON pe.idetiqueta = e.idetiqueta
			JOIN proyectos pr ON p.idgrupo = pr.idgrupo AND p.idproyecto = pr.idproyecto
			,(SELECT @curRank := 0) r
			WHERE 1=1
            [grupo]
            [proyectos]
            [nombre]
            [fechas]
			GROUP BY id
		) AS plans
        [etiquetas]"
	,"[grupo]",@idgrupo)
    ,"[proyectos]",@proyectos)
    ,"[nombre]",@nombre)
    ,"[fechas]",@fechas)
    ,"[etiquetas]",@etiquetas);
        
	PREPARE searchQuery FROM @getPlanes;
	EXECUTE searchQuery;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetTagsForTestplan`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTagsForTestplan` ()
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
    
	SELECT
		valor AS tag
	FROM etiquetas;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetTestplanById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTestplanById` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER
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
		CONCAT(pp.idgrupo,'.',pp.idproyecto,'.',pp.idplan) AS testplanId
        ,CONCAT(pp.idgrupo,'.',pp.idproyecto,'.',pp.idplan) AS `key`
        ,pp.nombre AS testplanName
        ,pp.descripcion AS description
        ,e.valor AS tag
		,DATE_FORMAT(pp.fecha_creacion, '%Y-%m-%d') AS createdOn
        ,estp.status
		,CONCAT(pp.idgrupo,'.',pp.idproyecto) AS projectId
        ,p.nombre AS projectName
        ,pp.idgrupo AS groupId
        ,g.nombre AS groupName
        ,CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS tcId
        ,CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS tcKey
        ,cp.nombre AS tcName
        ,estc.estado_del_caso AS tcStatus
        ,DATE_FORMAT(cp.fecha_ultima_modificacion, '%Y-%m-%d') AS tcModifiedOn
	FROM planes pp
    JOIN grupos g ON pp.idgrupo = g.idgrupo
    JOIN proyectos p ON pp.idgrupo = p.idgrupo AND pp.idproyecto = p.idproyecto
    LEFT JOIN casos_prueba cp ON pp.idgrupo = cp.idgrupo AND pp.idproyecto = cp.idproyecto AND pp.idplan = cp.idplan
    LEFT JOIN planes_etiquetas pe ON pe.idgrupo = pp.idgrupo AND pe.idproyecto = pp.idproyecto AND pe.idplan = pp.idplan
    LEFT JOIN etiquetas e ON e.idetiqueta = pe.idetiqueta
    LEFT JOIN estado_planes estp ON estp.idgrupo = pp.idgrupo AND estp.idproyecto = pp.idproyecto AND estp.idplan = pp.idplan
    LEFT JOIN estado_casos estc ON estc.caso = CONCAT(pp.idgrupo,'.',pp.idproyecto,'.',pp.idplan,'.',cp.idcaso)
    WHERE pp.idgrupo = idgrupo
    AND pp.idproyecto = idproyecto
    AND pp.idplan = idplan
    ;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `UpdateTestplan`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateTestplan` (
	IN `idgrupo` INTEGER,
    IN `idproyecto` INTEGER,
    IN `idplan` INTEGER,
	IN `nombre` VARCHAR(255),
	IN `descripcion` VARCHAR(255)
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
        
	START TRANSACTION;
		UPDATE `docps-dev`.`planes` SET `nombre`=nombre,`descripcion`=descripcion
		WHERE `docps-dev`.`planes`.idgrupo = idgrupo
        AND `docps-dev`.`planes`.idproyecto = idproyecto
        AND `docps-dev`.`planes`.idplan = idplan;
	COMMIT;
		SELECT 'TESTPLAN UPDATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteTagsForTestplan`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteTagsForTestplan` (
	IN `idg` INTEGER,
    IN `idp` INTEGER,
    IN `idpp` INTEGER
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
        
	START TRANSACTION;
		DELETE FROM  `docps-dev`.`planes_etiquetas` 
        WHERE idgrupo = idg
        AND idproyecto = idp
        AND idplan = idpp
        ;
	COMMIT;
		SELECT 'TAGS DELETED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteTestplan`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteTestplan` (
	IN `idg` INTEGER,
    IN `idp` INTEGER,
    IN `idpp` INTEGER
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
	
	START TRANSACTION;
		DELETE FROM `docps-dev`.`planes_etiquetas` WHERE idgrupo = idg AND idproyecto = idp AND idplan = idpp;
        DELETE FROM `docps-dev`.`planes` WHERE idgrupo = idg AND idproyecto = idp AND idplan = idpp;
	COMMIT;
		SELECT 'TESTPLAN DELETED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetTestcasesCount`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTestcasesCount` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER
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
		(SELECT COUNT(*) FROM casos_prueba cp 
        WHERE pp.idgrupo = cp.idgrupo 
        AND pp.idproyecto = cp.idproyecto 
        AND pp.idplan = cp.idplan
        AND cp.exportado = 0
        ) AS `count`,
        pp.nombre AS `name`
	FROM planes pp
    WHERE pp.idgrupo = idg
    AND pp.idproyecto = idp
    AND pp.idplan = idpp
    ;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetTestplanDataForExport`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTestplanDataForExport` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER
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
		cp.idcaso AS caseId,
		CONCAT(pp.nombre,' | ',cp.nombre) AS `name`,
		CONCAT(pp.descripcion,' | ',cp.descripcion) AS `description`,
        cp.precondiciones AS preconditions,
        pr.nombre AS priority        
	FROM planes pp
    LEFT JOIN casos_prueba cp ON pp.idgrupo = cp.idgrupo AND pp.idproyecto = cp.idproyecto AND pp.idplan = cp.idplan
    LEFT JOIN prioridades pr ON pr.idprioridad = cp.idprioridad
    WHERE pp.idgrupo = 1
    AND pp.idproyecto = 1
    AND pp.idplan = 1
    ORDER BY cp.idcaso
    ;
    
    SELECT 
		concat(pa.idcaso,'.',pa.idpaso) AS stepId,
        pa.accion AS `action`,
        pa.datos AS `data`,
        pa.resultado AS `result`,
        pa.orden AS `order`        
	FROM pasos pa 
    WHERE pa.idgrupo = 1
    AND pa.idproyecto = 1
    AND pa.idplan = 1
    ORDER BY pa.idcaso, pa.orden
    ;
    
	SELECT 
		concat(vars.tcId,'.',vars.sId) AS stepId,
		group_concat(vars.acName) AS acN,
		group_concat(vars.acValue) AS acV,
		group_concat(vars.resName) AS reN,
		group_concat(vars.resValue) AS reV,
		group_concat(vars.daName) AS daN,
		group_concat(vars.daValue) AS daV
	FROM (
		SELECT 
			idcaso AS tcId,
			idpaso AS sId,
			nombre AS acName,
			valor AS acValue,
			null AS resName,
			null AS resValue,
			null AS daName,
			null AS daValue
		FROM `variables` 
		WHERE idtipov = 1 
		AND idgrupo = idg
		AND idproyecto = idp
		AND idplan = idpp 
		
		UNION
		
		SELECT 
			idcaso AS tcId,
			idpaso AS sId,
			null AS acName,
			null AS acValue,
			nombre AS resName,
			valor AS resValue,
			null AS daName,
			null AS daValue
		FROM `variables` 
		WHERE idtipov = 2 
		AND idgrupo = idg
		AND idproyecto = idp
		AND idplan = idpp 
		
		UNION
		
		SELECT 
			idcaso AS tcId,
			idpaso AS sId,
			null AS acName,
			null AS acValue,
			null AS resName,
			null AS resValue,
			nombre AS daName,
			valor AS daValue
		FROM `variables` 
		WHERE idtipov = 3 
		AND idgrupo = idg
		AND idproyecto = idp
		AND idplan = idpp
	) vars
	GROUP BY vars.tcId, vars.sId
	;
END$$
DELIMITER ;