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
			SELECT idetiqueta INTO @idetiqueta FROM `docps_dev`.`etiquetas` WHERE UPPER(valor) = UPPER(etiqueta);
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