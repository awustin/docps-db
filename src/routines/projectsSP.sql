-- PROJECTS STORED PROCEDURES


USE `docps-dev`;
DROP procedure IF EXISTS `GetGroupsDropdown`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetGroupsDropdown` (
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
		g.idgrupo AS `key`,
        g.nombre AS name
	FROM grupos g
    JOIN usuarios_grupos ug ON ug.idgrupo = g.idgrupo
    WHERE ug.idusuario = id;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `SearchProjects`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `SearchProjects` (
	IN nombre VARCHAR(255),
	IN grupos VARCHAR(512)
)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = @text;
	  SELECT @full_error;
	 END;
	
	SET @nombre = CASE WHEN nombre != '' THEN CONCAT(" AND p.nombre LIKE '%",nombre,"%'") ELSE '' END;
	
	SET @grupos = CASE WHEN grupos != '' THEN CONCAT(" AND p.idgrupo IN (",grupos,")") ELSE '' END;
                    
	SET @getProyectos = CONCAT("    
		SELECT
			@curRank := @curRank + 1 AS `key`
			,CONCAT(p.idgrupo,'.',p.idproyecto) AS id
            ,p.fecha_creacion AS createdOn
            ,p.nombre AS `name`
            ,g.nombre AS `group`
			,a.nombre AS avatar
			,da.name AS defaultAvatar
            ,COUNT(pp.idplan) AS testplanCount
		FROM proyectos p
		JOIN grupos g ON g.idgrupo = p.idgrupo
		LEFT JOIN archivos a ON g.idarchivo_img = a.idarchivo
		LEFT JOIN default_avatar da ON g.iddefavatar = da.iddefavatar
        LEFT JOIN planes pp ON g.idgrupo = pp.idgrupo AND p.idproyecto = pp.idproyecto
		,(SELECT @curRank := 0) r        
		WHERE 0 = 0"
        ,@nombre
        ,@grupos
        ," GROUP BY id ORDER BY createdOn DESC");
        
	PREPARE searchQuery FROM @getProyectos;
	EXECUTE searchQuery;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InsertProject`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertProject` (
	IN nombre VARCHAR(255),
    IN idgrupo INTEGER
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
        INSERT INTO `docps-dev`.`proyectos`(`nombre`,`fecha_creacion`,`idgrupo`)
		VALUES(nombre,SYSDATE(),idgrupo);

	COMMIT;
		SELECT 'PROJECT CREATED' AS message, 1 AS success, last_insert_id() AS id;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetProjectById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetProjectById` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER
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
		CONCAT(p.idgrupo,'.',p.idproyecto) AS id
        ,p.fecha_creacion AS createdOn
        ,p.nombre AS `name`
        ,g.nombre AS `group`
        ,pp.nombre AS tpTitle
        ,CONCAT(pp.idgrupo,'.',pp.idproyecto,'.',pp.idplan) AS tpId
				,DATE_FORMAT(pp.fecha_creacion, '%Y-%m-%d') AS tpCreatedOn
        ,ep.status AS tpStatus
	FROM proyectos p
    JOIN grupos g ON g.idgrupo = p.idgrupo
    LEFT JOIN planes pp ON pp.idgrupo = p.idgrupo AND pp.idproyecto = p.idproyecto
    LEFT JOIN estado_planes ep ON ep.idgrupo = pp.idgrupo AND ep.idproyecto = pp.idproyecto AND ep.idplan = pp.idplan
    WHERE p.idgrupo = idgrupo
    AND p.idproyecto = idproyecto
    ;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `UpdateProject`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateProject` (
	IN `idgrupo` INTEGER,
	IN `idproyecto` INTEGER,
	IN `nombre` VARCHAR(255)
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
		UPDATE `docps-dev`.`proyectos` SET `nombre`=nombre
		WHERE `docps-dev`.`proyectos`.idgrupo = idgrupo
        AND `docps-dev`.`proyectos`.idproyecto = idproyecto;
	COMMIT;
		SELECT 'PROJECT UPDATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteProject`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteProject` (
	IN `idg` INTEGER,
    IN `idp` INTEGER
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
        DELETE FROM `docps-dev`.`proyectos` WHERE idgrupo = idg AND idproyecto = idp;
	COMMIT;
		SELECT 'PROJECT DELETED' AS message, 1 AS success;
END$$
DELIMITER ;