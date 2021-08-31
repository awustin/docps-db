-- GROUPS STORED PROCEDURES

USE `docps-dev`;
DROP procedure IF EXISTS `GetGroupById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetGroupById` (
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
		idgrupo AS ID
        ,nombre AS NAME
	FROM grupos
    WHERE idgrupo = id;	
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `SearchGroups`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `SearchGroups` (
	IN nombre VARCHAR(255),
	IN estado VARCHAR(1)
)
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = @text;
	  SELECT @full_error;
	 END;
	
	SET @nombre = CASE WHEN nombre != '' THEN CONCAT(" AND g.nombre = '",nombre,"'") ELSE '' END;
	
	SET @estado = CASE WHEN estado != '' THEN CONCAT(" AND g.estado_alta = ",estado) ELSE '' END;
                    
	SET @getUsuarios = CONCAT("    
		SELECT
			@curRank := @curRank + 1 AS `key`
			,idgrupo AS id
			,DATE_FORMAT(g.fecha_alta, '%Y-%m-%d') AS createdOn
			,g.nombre AS `name`
			,case when g.estado_alta = 1 then 'active' else 'inactive' end AS status
			,a.nombre AS avatar
			,da.name AS defaultAvatar
		FROM grupos g
		LEFT JOIN archivos a ON g.idarchivo_img = a.idarchivo
		LEFT JOIN default_avatar da ON g.iddefavatar = da.iddefavatar
		,(SELECT @curRank := 0) r
		WHERE 0 = 0",@nombre,@estado);
        
	PREPARE searchQuery FROM @getUsuarios;
	EXECUTE searchQuery;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InsertGroup`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertGroup` (
	IN `name` VARCHAR(255)
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
		SELECT MAX(iddefavatar),MIN(iddefavatar) FROM default_avatar INTO @max,@min;
		SELECT FLOOR(RAND()*@max + @min) INTO @iddefavatar;
		INSERT INTO `docps-dev`.`grupos`(`nombre`,`estado_alta`,`fecha_alta`,`iddefavatar`)
		VALUES(name,1,SYSDATE(),@iddefavatar);
	COMMIT;
		SELECT 'GROUP CREATED' AS message, 1 AS success, last_insert_id() AS id;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InsertGroupMember`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertGroupMember` (
	IN `idgrupo` INTEGER,
    IN `idusuario`INTEGER,
    IN `esAdmin` INTEGER
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
		INSERT INTO `docps-dev`.`usuarios_grupos`(`idgrupo`,`idusuario`,`admin_grupo`,`fecha_alta`)
		VALUES(idgrupo,idusuario,esAdmin,SYSDATE());
	COMMIT;
		SELECT 'MEMBER ADDED' AS message, 1 AS success;
END$$
DELIMITER ;