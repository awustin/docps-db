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
		CONCAT(u.nombre,' ',u.apellido) AS name,
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