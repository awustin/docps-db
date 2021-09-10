-- USERS STORED PROCEDURES

USE `docps-dev`;
DROP procedure IF EXISTS `UserLogin`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UserLogin` (
	IN username VARCHAR(255), 
  IN clave VARCHAR(255)
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
		u.idusuario AS id,
		g.idgrupo AS groupid,
		g.nombre AS groupname,
        u.es_admin AS isAdmin
    FROM cuentas c 
    LEFT JOIN usuarios u ON u.idusuario = c.idusuario
	LEFT JOIN usuarios_grupos ug ON u.idusuario = ug.idusuario
	LEFT JOIN grupos g ON g.idgrupo = ug.idgrupo
    WHERE c.username = username AND c.clave = clave;	
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetUserInfoById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetUserInfoById` (
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
		u.idusuario AS id,
		g.idgrupo AS groupid,
		g.nombre AS groupname,
		c.fecha_creacion AS createdOn,
		u.nombre AS name,
		u.apellido AS lastname,
		c.email AS email,
		CASE WHEN u.estado_alta = 1 THEN 'active' ELSE 'inactive' END AS status,
		c.username AS username,
		u.dni AS dni,
		u.calle AS street,
		u.num_calle AS streetNumber,
		u.direccion_extra AS addressExtra,
		u.puesto AS job,
		a.nombre AS image
	FROM usuarios u
	JOIN cuentas c ON u.idusuario = c.idusuario
	LEFT JOIN usuarios_grupos ug ON u.idusuario = ug.idusuario
	LEFT JOIN grupos g ON g.idgrupo = ug.idgrupo
	LEFT JOIN archivos a ON a.idarchivo = u.idarchivo_img
	WHERE u.idusuario = id
	;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InsertUser`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertUser` (
	IN `email` VARCHAR(255),
	IN `username` VARCHAR(255),
	IN `clave` VARCHAR(255),
	IN `nombre` VARCHAR(255),
	IN `apellido` VARCHAR(255),
	IN `dni` VARCHAR(255),
	IN `calle` VARCHAR(255),
	IN `num_calle` VARCHAR(255),
	IN `direccion_extra` VARCHAR(255),
	IN `puesto` VARCHAR(255)
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
		INSERT INTO `docps-dev`.`usuarios`(`nombre`,`apellido`,`estado_alta`,`dni`,`calle`,`num_calle`,`direccion_extra`,`puesto`)
		VALUES(nombre,apellido,0,dni,calle,num_calle,direccion_extra,puesto); 
        INSERT INTO `docps-dev`.`cuentas`(`username`,`clave`,`email`,`fecha_creacion`,`idusuario`)
		VALUES(username,clave,email,SYSDATE(),last_insert_id());
	COMMIT;
		SELECT 'USER CREATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `SearchUsers`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `SearchUsers` (
	IN desde VARCHAR(100),
	IN hasta VARCHAR(100),
	IN email VARCHAR(255),
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
    
	SET @daterange = CASE WHEN desde != '' AND hasta != '' THEN CONCAT(" AND c.fecha_creacion BETWEEN STR_TO_DATE('",desde,"','%Y-%m-%d') AND STR_TO_DATE('",hasta,"','%Y-%m-%d')") WHEN desde != '' AND hasta = '' THEN CONCAT(" AND c.fecha_creacion > STR_TO_DATE('",desde,"','%Y-%m-%d')") ELSE '' END;
                        
	SET @email = CASE WHEN email != '' THEN CONCAT(" AND c.email = '",email,"'") ELSE '' END;
	
	SET @nombre = CASE WHEN nombre != '' THEN CONCAT(" AND u.nombre = '",nombre,"'") ELSE '' END;
	
	SET @estado = CASE WHEN estado != '' THEN CONCAT(" AND u.estado_alta = ",estado) ELSE '' END;
                    
	SET @getUsuarios = CONCAT("    
		SELECT
			@curRank := @curRank + 1 AS `key`
			,u.idusuario AS id
			,DATE_FORMAT(c.fecha_creacion, '%Y-%m-%d') AS createdOn
			,u.nombre AS `name`
			,u.apellido AS lastname
			,c.email AS email
			,case when u.estado_alta = 1 then 'active' else 'inactive' end AS status
		FROM usuarios u 
		JOIN cuentas c on u.idusuario = c.idusuario
        ,(SELECT @curRank := 0) r
		WHERE c.eliminada = 0",@daterange,@email,@nombre,@estado);
        
	PREPARE searchQuery FROM @getUsuarios;
	EXECUTE searchQuery;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `UpdateUser`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateUser` (
	IN `id` INTEGER,
	IN `email` VARCHAR(255),
	IN `username` VARCHAR(255),
	IN `nombre` VARCHAR(255),
	IN `apellido` VARCHAR(255),
	IN `dni` VARCHAR(255),
	IN `calle` VARCHAR(255),
	IN `num_calle` VARCHAR(255),
	IN `direccion_extra` VARCHAR(255),
	IN `puesto` VARCHAR(255),
	IN `estado_alta` INTEGER
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
			UPDATE `docps-dev`.`usuarios` SET `nombre`=nombre,`apellido`=apellido,`estado_alta`=estado_alta,`dni`=dni,`calle`=calle,`num_calle`=num_calle,`direccion_extra`=direccion_extra,`puesto`=puesto
			WHERE `docps-dev`.`usuarios`.idusuario = id;
			UPDATE `docps-dev`.`cuentas` SET `username`=username,`clave`=clave,`email`=email
			WHERE `docps-dev`.`cuentas`.idusuario = id;
	COMMIT;
		SELECT 'USER UPDATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InactivateUser`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InactivateUser` (
	IN `id` INTEGER
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
		UPDATE `docps-dev`.`cuentas` SET `eliminada`=1 WHERE idusuario = id;
	COMMIT;
		SELECT 'USER DELETED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetCurrentUserInfoById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetCurrentUserInfoById` (
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
		u.idusuario AS id,
		CONCAT(u.nombre,' ',u.apellido) AS completeName,
        c.email,
        c.username,
        COALESCE(u.puesto,' ') AS job,
        a.nombre AS avatar,
        CAST(u.es_admin AS UNSIGNED) AS isAdmin
	FROM usuarios u
	JOIN cuentas c ON u.idusuario = c.idusuario
    LEFT JOIN archivos a ON u.idusuario = a.idarchivo
	WHERE u.idusuario = id
	;
END$$
DELIMITER ;




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
		WHERE 0 = 0",@nombre,@estado,
		" ORDER BY g.fecha_alta DESC");
        
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


USE `docps-dev`;
DROP procedure IF EXISTS `GetUsersForGroups`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetUsersForGroups` ()
BEGIN
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;
    
	SELECT 		
        u.idusuario AS `key`,
        u.idusuario AS id,
        CONCAT(u.nombre,' ',u.apellido) AS completeName
	FROM usuarios u
    JOIN cuentas c ON u.idusuario = c.idcuenta
    , (SELECT @curRank := 0) r
    WHERE u.estado_alta = 1 
    AND c.eliminada = 0;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetGroupAndMembersById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetGroupAndMembersById` (
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
		g.nombre AS name,
		g.idgrupo AS id,
        DATE_FORMAT(g.fecha_alta, '%Y-%m-%d') AS createdOn,
        CASE WHEN g.estado_alta = 1 THEN 'active' ELSE 'inactive' END AS status,      
        a.nombre AS avatar,
        da.name AS defaultAvatar,
		u.idusuario AS userKey,
        u.idusuario AS userId,
        CONCAT(u.nombre,' ',u.apellido) AS userCompleteName,
        CAST(ug.admin_grupo AS UNSIGNED) AS userIsAdmin        
	FROM grupos g
    LEFT JOIN archivos a ON g.idarchivo_img = a.idarchivo
    LEFT JOIN default_avatar da ON g.iddefavatar = da.iddefavatar
    LEFT JOIN usuarios_grupos ug ON g.idgrupo = ug.idgrupo
    LEFT JOIN usuarios u ON u.idusuario = ug.idusuario
    WHERE g.idgrupo = id;	
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `UpdateGroup`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateGroup` (
	IN `id` INTEGER,
	IN `nombre` VARCHAR(255),
	IN `estado_alta` INTEGER
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
		UPDATE `docps-dev`.`grupos` SET `nombre`=nombre,`estado_alta`=estado_alta
		WHERE `docps-dev`.`grupos`.idgrupo = id;
	COMMIT;
		SELECT 'GROUP UPDATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteGroupMembers`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteGroupMembers` (
	IN `id` INTEGER
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
		DELETE FROM  `docps-dev`.`usuarios_grupos` WHERE idgrupo = id;
	COMMIT;
		SELECT 'GROUP MEMBERS DELETED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `ActiveMembersforGroupById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `ActiveMembersforGroupById` (
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
		COUNT(*) AS activeMembers        
	FROM grupos g
    JOIN usuarios_grupos ug ON g.idgrupo = ug.idgrupo
    JOIN usuarios u ON u.idusuario = ug.idusuario
    WHERE g.idgrupo = id
    AND u.estado_alta = 1;	
END$$
DELIMITER ;



USE `docps-dev`;
DROP procedure IF EXISTS `DeleteGroup`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteGroup` (
	IN `id` INTEGER
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
		DELETE FROM `docps-dev`.`usuarios_grupos` WHERE idusuario = id;
        DELETE FROM `docps-dev`.`grupos` WHERE idusuario = id;
	COMMIT;
		SELECT 'GROUP DELETED' AS message, 1 AS success;
END$$
DELIMITER ;



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