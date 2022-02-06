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
	DECLARE active INT;
	DECLARE exit handler for SQLEXCEPTION
	 BEGIN
	  GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	   @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
	  SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
	  SELECT @full_error;
	 END;	
	
	IF EXISTS (
		SELECT *
		FROM `docps-dev`.`cuentas` c
		JOIN `docps-dev`.`usuarios` u ON u.idusuario = c.idusuario
		WHERE c.username = username 
		AND c.clave = clave 
		)
	THEN
		SELECT u.estado_alta INTO active 
		FROM `docps-dev`.`cuentas` c
		JOIN `docps-dev`.`usuarios` u ON u.idusuario = c.idusuario
		WHERE c.username = username 
		AND c.clave = clave;
		
		IF active = 1 THEN
			SELECT
				1 AS success, 
				u.idusuario AS id,
				CONCAT(u.nombre,' ',u.apellido) AS name,
				g.idgrupo AS groupid,
				g.nombre AS groupname,
		        u.es_admin AS isAdmin,
				CAST(ug.admin_grupo AS UNSIGNED) AS isGroupAdmin,
				CASE 
					WHEN u.es_admin = 1 THEN 'admin'
					ELSE 
						CASE 
							WHEN EXISTS (
								SELECT NULL FROM usuarios_grupos ug1
								WHERE	ug1.admin_grupo = 1 AND ug1.idusuario = u.idusuario
								) THEN 'groupAdmin'
							ELSE 'user'
						END		
				END AS `role`
		    FROM cuentas c 
		    LEFT JOIN usuarios u ON u.idusuario = c.idusuario
			LEFT JOIN usuarios_grupos ug ON u.idusuario = ug.idusuario
			LEFT JOIN grupos g ON g.idgrupo = ug.idgrupo
		   WHERE c.username = username AND c.clave = clave;
	   ELSE 
	   	SELECT 'INACTIVE' AS message, 0 AS success;
	   END IF;
	ELSE 
		SELECT 'NOT_EXISTS' AS message, 0 AS success;
	END IF;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `ChangePassword`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `ChangePassword` (
	IN `id` INTEGER,
	IN `actualIngresada` VARCHAR(255),
	IN `nuevaIngresada` VARCHAR(255)
   )
BEGIN
	DECLARE actual VARCHAR(255);
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;

	START TRANSACTION;
		SELECT clave INTO actual FROM `docps-dev`.`cuentas` WHERE idusuario=id;
		
		IF actual = actualIngresada THEN
			UPDATE `docps-dev`.`cuentas` SET clave = nuevaIngresada WHERE idusuario=id;
			SELECT 'PASSWORD_CHANGED' AS message, 1 AS success;
		ELSE
			SELECT 'WRONG_CURRENT_PASSWORD' AS message, 0 AS success;
		END IF;
	COMMIT;
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
	DECLARE hashCode CHAR(32);
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
        
	START TRANSACTION;
		SELECT iddefavatar INTO @iddefavatar FROM `default_avatar` WHERE `category` = 'group' ORDER BY RAND() LIMIT 1;
		INSERT INTO `docps-dev`.`usuarios`(`nombre`,`apellido`,`estado_alta`,`dni`,`calle`,`num_calle`,`direccion_extra`,`puesto`,`iddefavatar`)
		VALUES(nombre,apellido,0,dni,calle,num_calle,direccion_extra,puesto,@iddefavatar); 
        INSERT INTO `docps-dev`.`cuentas`(`username`,`clave`,`email`,`fecha_creacion`,`idusuario`)
		VALUES(username,clave,email,SYSDATE(),last_insert_id());
		INSERT INTO `docps-dev`.`codigos`(`idcuenta`,`hash`,`fecha_expiracion`)
		VALUES(last_insert_id(),MD5(CONCAT_WS(last_insert_id(),email,username)),DATE_ADD(SYSDATE(), INTERVAL 1 DAY));
		SET hashCode = MD5(CONCAT_WS(last_insert_id(),email,username));
	COMMIT;
		SELECT 'USER CREATED' AS message, 1 AS success, hashCode;
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
	  SELECT @full_error, 0 AS success;
	 END;
    
	SET @daterange = CASE WHEN desde != '' AND hasta != '' THEN CONCAT(" AND c.fecha_creacion BETWEEN STR_TO_DATE('",desde,"','%Y-%m-%d') AND STR_TO_DATE('",hasta,"','%Y-%m-%d')") WHEN desde != '' AND hasta = '' THEN CONCAT(" AND c.fecha_creacion > STR_TO_DATE('",desde,"','%Y-%m-%d')") ELSE '' END;
                        
	SET @email = CASE WHEN email != '' THEN CONCAT(" AND c.email LIKE '%",email,"%'") ELSE '' END;
	
	SET @nombre = CASE WHEN nombre != '' THEN REPLACE(" AND u.nombre LIKE '%<nom>%' OR u.apellido LIKE '%<nom>%' ", "<nom>", nombre) ELSE '' END;
	
	SET @estado = CASE WHEN estado != '' THEN CONCAT(" AND u.estado_alta = ",estado) ELSE '' END;
                    
	SET @getUsuarios = CONCAT("    
		SELECT
			1 AS success
			,@curRank := @curRank + 1 AS `key`
			,u.idusuario AS id
			,DATE_FORMAT(c.fecha_creacion, '%Y-%m-%d %H:%i') AS createdOn
			,c.email AS email
			,CONCAT(u.nombre,' ',u.apellido) AS `name`
			,case when u.estado_alta = 1 then 'active' else 'inactive' end AS status
			,da.name AS defAvatar
		FROM usuarios u 
		JOIN cuentas c on u.idusuario = c.idusuario
		LEFT JOIN default_avatar da on u.iddefavatar = da.iddefavatar
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
			UPDATE `docps-dev`.`usuarios` SET `nombre`=nombre,`apellido`=apellido,`dni`=dni,`calle`=calle,`num_calle`=num_calle,`direccion_extra`=direccion_extra,`puesto`=puesto
			WHERE `docps-dev`.`usuarios`.idusuario = id;
			UPDATE `docps-dev`.`cuentas` SET `username`=username,`clave`=clave,`email`=email
			WHERE `docps-dev`.`cuentas`.idusuario = id;
	COMMIT;
		SELECT 'USER UPDATED' AS message, 1 AS success;
END$$
DELIMITER ;

USE `docps-dev`;
DROP procedure IF EXISTS `ActivateUser`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `ActivateUser` (
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
		UPDATE `docps-dev`.`usuarios` SET `estado_alta`=1,`fecha_alta`=SYSDATE()
		WHERE `docps-dev`.`usuarios`.idusuario = id;
	COMMIT;
		SELECT 'USER ACTIVATED' AS message, 1 AS success;
END$$
DELIMITER ;

USE `docps-dev`;
DROP procedure IF EXISTS `DeactivateUser`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeactivateUser` (
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
			UPDATE `docps-dev`.`usuarios` SET `estado_alta`=0 WHERE `docps-dev`.`usuarios`.idusuario = id;
	COMMIT;
		SELECT 'USER DEACTIVATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteUserById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteUserById` (
	IN `id` INTEGER
   )
BEGIN
	DECLARE isActive INT;
	DECLARE hasGroups INT;
	DECLARE hasExecutions INT;
	
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
		
	START TRANSACTION;
	
	SELECT estado_alta INTO isActive FROM `docps-dev`.`usuarios` WHERE idusuario = id;
	SELECT COUNT(*) INTO hasGroups FROM `docps-dev`.`usuarios_grupos` WHERE idusuario = id;
	SELECT COUNT(*) INTO hasExecutions FROM `docps-dev`.`ejecuciones` WHERE idusuario = id;	
	
	IF (isActive = 1) OR (hasGroups > 0) OR (hasExecutions > 0) THEN
		SELECT 'DENIED OPERATION' AS message, 0 AS success;
	ELSE	
		DELETE FROM `docps-dev`.`cuentas` WHERE idusuario = id;
		DELETE FROM `docps-dev`.`usuarios` WHERE idusuario = id;
		SELECT 'USER DELETED' AS message, 1 AS success;
	END IF;
	
	COMMIT;
	
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

USE `docps-dev`;
DROP procedure IF EXISTS `VerifyUser`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `VerifyUser` (
	IN `hashCode` CHAR(32)
   )
BEGIN
	DECLARE numFilas INT;
	DECLARE vigente INT;
	DECLARE estado VARCHAR(15);
	DECLARE idu INT;
	DECLARE idc INT;
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;

	SELECT COUNT(*) INTO numFilas FROM `docps-dev`.`codigos` WHERE `hash` = hashCode;

	IF numFilas = 1 THEN
		SELECT DATE_SUB(fecha_expiracion, INTERVAL 1 DAY) < SYSDATE() INTO vigente FROM `docps-dev`.`codigos` WHERE `hash` = hashCode;
		SET estado = CASE WHEN vigente = 1 THEN 'verified' ELSE 'expired' END;		
	ELSE
		SET estado = 'failed';
	END IF;
	
	IF estado = 'verified' THEN
		SELECT idcuenta INTO idc FROM `codigos` WHERE `hash` = hashCode;
		SELECT idusuario INTO idu FROM `cuentas` WHERE `idcuenta` = idc;
		UPDATE `docps-dev`.`usuarios` SET `estado_alta` = 1 , `fecha_alta` = SYSDATE() WHERE `idusuario` = idu;
		DELETE FROM `docps-dev`.`codigos` WHERE `hash` = hashCode;
	END IF;	
	
	SELECT 'USER VERIFIED' AS message, 1 AS success, estado AS `status`;
END$$
DELIMITER ;

USE `docps-dev`;
DROP procedure IF EXISTS `InsertVerificationCode`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertVerificationCode` (
	IN `id` INTEGER,
	IN `email` VARCHAR(255)
   )
BEGIN
	DECLARE idc INT;
	DECLARE hashCode CHAR(32);
	DECLARE emailUsuario VARCHAR(255);

	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
        
	START TRANSACTION;
		SELECT c.`idcuenta`,c.`email` INTO idc,emailUsuario FROM `docps-dev`.`cuentas` AS c WHERE `idusuario` = id;
		
		IF ( emailUsuario = email ) THEN
		
			DELETE FROM `docps-dev`.`codigos` WHERE `idcuenta` = idc;
		
			INSERT INTO `docps-dev`.`codigos`(`idcuenta`,`hash`,`fecha_expiracion`)
			VALUES(idc,MD5(CONCAT_WS(idc,email,id)),DATE_ADD(SYSDATE(), INTERVAL 1 DAY));
			
			SET hashCode = MD5(CONCAT_WS(idc,email,id));
			
			SELECT 'CODE CREATED' AS message, 1 AS success, hashCode;
		ELSE
			SELECT 'WRONG EMAIL' AS message, 0 AS success;
		END IF;
	COMMIT;
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
	IN estado VARCHAR(1),
	IN idu INT,
	IN rol VARCHAR(20)
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

	SET @soloAdminGrupo = CASE WHEN rol != 'admin' THEN REPLACE("
		AND g.idgrupo IN (
			SELECT idgrupo
			FROM usuarios_grupos 
			WHERE idusuario = <idusuario> AND admin_grupo = 1
		)"
		,"<idusuario>", idu)
	ELSE '' END;
                    
	SET @getUsuarios = CONCAT("    
		SELECT
			@curRank := @curRank + 1 AS `key`
			,idgrupo AS id
			,DATE_FORMAT(g.fecha_alta, '%Y-%m-%d %H:%i') AS createdOn
			,g.nombre AS `name`
			,case when g.estado_alta = 1 then 'active' else 'inactive' end AS status
			,a.nombre AS avatar
			,da.name AS defaultAvatar
		FROM grupos g
		LEFT JOIN archivos a ON g.idarchivo_img = a.idarchivo
		LEFT JOIN default_avatar da ON g.iddefavatar = da.iddefavatar
		,(SELECT @curRank := 0) r
		WHERE 0 = 0"
		,@nombre
		,@estado
		,@soloAdminGrupo
		," ORDER BY g.fecha_alta DESC");
        
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
		SELECT iddefavatar INTO @iddefavatar FROM `default_avatar` WHERE `category` = 'group' ORDER BY RAND() LIMIT 1;
		INSERT INTO `docps-dev`.`grupos`(`nombre`,`estado_alta`,`fecha_alta`,`iddefavatar`)
		VALUES(name,1,SYSDATE(),@iddefavatar);
	COMMIT;
		SELECT 'GROUP CREATED' AS message, 1 AS success, last_insert_id() AS id;
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
        CONCAT(u.nombre,' ',u.apellido) AS completeName,
		da.name AS `defAvatar`
	FROM usuarios u
    JOIN cuentas c ON u.idusuario = c.idusuario
	LEFT JOIN default_avatar da ON da.iddefavatar = u.iddefavatar
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
        DATE_FORMAT(g.fecha_alta, '%Y-%m-%d %H:%i') AS createdOn,
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
		UPDATE `docps-dev`.`grupos` SET `nombre`=nombre
		WHERE `docps-dev`.`grupos`.idgrupo = id;
	COMMIT;
		SELECT 'GROUP UPDATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `UpdateGroupMembers`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateGroupMembers` (
	IN `idg` INTEGER,
	IN `valuesInsert` VARCHAR(512),
	IN `eliminar` INTEGER
   )
BEGIN
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
		
		SET @insertarMiembros = CONCAT("INSERT INTO `docps-dev`.`usuarios_grupos`(`idgrupo`,`idusuario`,`admin_grupo`,`fecha_alta`) VALUES ", valuesInsert);
		
		DELETE FROM `docps-dev`.`usuarios_grupos` WHERE `idgrupo` = idg;
		
		IF eliminar != 1 THEN
			PREPARE insertQuery FROM @insertarMiembros;
			EXECUTE insertQuery;
		END IF;
		
		SELECT 'MEMBERS UPDATED' AS message, 1 AS success;
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
	DECLARE isActive INT;
	DECLARE hasUsers INT;
	DECLARE hasProyects INT;
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
		
	START TRANSACTION;
		SELECT estado_alta INTO isActive FROM `docps-dev`.`grupos` WHERE idgrupo = id;
		SELECT COUNT(*) INTO hasUsers FROM `docps-dev`.`usuarios_grupos` WHERE idgrupo = id;
		SELECT COUNT(*) INTO hasProyects FROM `docps-dev`.`proyectos` WHERE idgrupo = id;	
		
		IF (isActive = 1) OR (hasUsers > 0) OR (hasProyects > 0) THEN
			SELECT 'DENIED OPERATION' AS message, 0 AS success;
		ELSE
	      DELETE FROM `docps-dev`.`grupos` WHERE idgrupo = id;
			SELECT 'GROUP DELETED' AS message, 1 AS success;
	   END IF;
	COMMIT;
END$$
DELIMITER ;



USE `docps-dev`;
DROP procedure IF EXISTS `ChangeGroupStatusById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `ChangeGroupStatusById` (
	IN `id` INTEGER,
	IN `estado` VARCHAR(10)
   )
BEGIN
	DECLARE estadoActual INT;
	
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;

	START TRANSACTION;
		SELECT `estado_alta` INTO estadoActual FROM `docps-dev`.`grupos` WHERE `idgrupo` = id;
		
		IF ( estadoActual = IF(estado = 'active',1,0) ) THEN
			UPDATE `docps-dev`.`grupos` SET `estado_alta` = NOT estadoActual  WHERE `idgrupo` = id;
			
			IF estadoActual = 0 THEN
				SELECT 'ACTIVATE' AS message, 1 AS success;
			ELSE
				SELECT 'DEACTIVATE' AS message, 1 AS success;
			END IF;
			
		ELSE
			SELECT 'INCONSISTENT STATUS' AS message, 0 AS success;
		END IF;
		
	COMMIT;
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
    WHERE ug.idusuario = id
	AND g.estado_alta = 1
	;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetProjectsDropdown`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetProjectsDropdown` (
	IN idg INTEGER
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
			p.idproyecto AS id,
        p.nombre AS name
	FROM proyectos p
    WHERE p.idgrupo = idg
    ORDER BY p.fecha_creacion DESC;
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
				,DATE_FORMAT(pp.fecha_creacion, '%Y-%m-%d %H:%i') AS tpCreatedOn
        ,ep.status AS tpStatus
		,da.name AS `defaultAvatar`
	FROM proyectos p
    JOIN grupos g ON g.idgrupo = p.idgrupo
	LEFT JOIN default_avatar da ON g.iddefavatar = da.iddefavatar
    LEFT JOIN planes pp ON pp.idgrupo = p.idgrupo AND pp.idproyecto = p.idproyecto
    LEFT JOIN estado_planes ep ON ep.idgrupo = pp.idgrupo AND ep.idproyecto = pp.idproyecto AND ep.idplan = pp.idplan
    WHERE p.idgrupo = idgrupo
    AND p.idproyecto = idproyecto
	ORDER BY pp.fecha_creacion DESC
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
				,DATE_FORMAT(p.fecha_creacion, '%Y-%m-%d %H:%i') AS createdOn
				,ep.status AS `status`
				,pr.nombre AS projectName
				,pr.idproyecto AS projectId
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
			ORDER BY p.idgrupo, p.idproyecto, p.fecha_creacion DESC
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
        ,GROUP_CONCAT(e.valor) AS tags
			,DATE_FORMAT(pp.fecha_creacion, '%Y-%m-%d %H:%i') AS createdOn
        ,estp.status
			,CONCAT(pp.idgrupo,'.',pp.idproyecto) AS projectId
        ,p.nombre AS projectName
        ,pp.idgrupo AS groupId
        ,g.nombre AS groupName        
	FROM planes pp
    JOIN grupos g ON pp.idgrupo = g.idgrupo
    JOIN proyectos p ON pp.idgrupo = p.idgrupo AND pp.idproyecto = p.idproyecto
    LEFT JOIN planes_etiquetas pe ON pe.idgrupo = pp.idgrupo AND pe.idproyecto = pp.idproyecto AND pe.idplan = pp.idplan
    LEFT JOIN etiquetas e ON e.idetiqueta = pe.idetiqueta
    LEFT JOIN estado_planes estp ON estp.idgrupo = pp.idgrupo AND estp.idproyecto = pp.idproyecto AND estp.idplan = pp.idplan
    WHERE pp.idgrupo = idgrupo
    AND pp.idproyecto = idproyecto
    AND pp.idplan = idplan
	 GROUP BY pp.idgrupo,pp.idproyecto,pp.idplan
    ;
    
   SELECT 
     CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS id
     ,CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS `key`
     ,CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS caseId
     ,cp.nombre AS caseName
     ,estc.estado_del_caso AS `status`
     ,CASE 
			WHEN estc.estado_del_caso = 'Not executed' THEN 1
			WHEN estc.estado_del_caso = 'In progress' THEN 2
		   WHEN estc.estado_del_caso = 'Failed' THEN 3
		   WHEN estc.estado_del_caso = 'Passed' THEN 4
		END AS ordenEstados
     ,DATE_FORMAT(cp.fecha_ultima_modificacion, '%Y-%m-%d %H:%i') AS modifiedOn
   FROM casos_prueba cp 
   LEFT JOIN estado_casos estc ON estc.caso = CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso)
	WHERE cp.idgrupo = idgrupo
	AND cp.idproyecto = idproyecto
	AND cp.idplan = idplan
	ORDER BY ordenEstados
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
	IN `descripcion` VARCHAR(255),
	IN `arrEtiquetas` VARCHAR(1024),
	IN `cuentaEtiquetas` INT
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
        
      DELETE FROM `docps-dev`.`planes_etiquetas` 
		WHERE `planes_etiquetas`.`idgrupo` = idgrupo 
		AND `planes_etiquetas`.`idproyecto` = idproyecto 
		AND `planes_etiquetas`.`idplan` = idplan;
      
      IF cuentaEtiquetas > 0 THEN
	      SET @i = 1;
			WHILE @i <= cuentaEtiquetas DO
				
				SET @getElemento = REPLACE(REPLACE("SELECT ELT(<i>,<arrEtiquetas>) INTO @elemento"
					,"<i>",@i)
					,"<arrEtiquetas>", arrEtiquetas);
				PREPARE stmt FROM @getElemento;
				EXECUTE stmt;
				
				INSERT IGNORE INTO `docps-dev`.`etiquetas`(`valor`) VALUES (@elemento);
				
				INSERT INTO `docps-dev`.`planes_etiquetas`(`idplan`,`idproyecto`,`idgrupo`,`idetiqueta`)
				VALUES (idplan, idproyecto, idgrupo, (SELECT idetiqueta FROM `docps-dev`.`etiquetas` WHERE `valor`=@elemento) );
				
				SET @i = @i + 1;					
			END WHILE;			
		END IF;
      
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
		-- DELETE FROM  `docps-dev`.`planes_etiquetas` 
        -- WHERE idgrupo = idg
        -- AND idproyecto = idp
        -- AND idplan = idpp
        -- ;		
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
		COUNT(*)
	INTO @casesCount 
    FROM casos_prueba
    WHERE idgrupo = idg
    AND idproyecto = idp
    AND idplan = idpp
    AND exportado = 0;
    
    SELECT @casesCount AS totalCases;
    
    IF (@casesCount > 0) THEN 
		SELECT 
			cp.idcaso AS caseId,
			CONCAT(pp.nombre,' | ',cp.nombre) AS `name`,
			CONCAT(pp.descripcion,' | ',cp.descripcion) AS `description`,
			cp.precondiciones AS preconditions,
			pr.nombre AS priority        
		FROM planes pp
		LEFT JOIN casos_prueba cp ON pp.idgrupo = cp.idgrupo AND pp.idproyecto = cp.idproyecto AND pp.idplan = cp.idplan
		LEFT JOIN prioridades pr ON pr.idprioridad = cp.idprioridad
		WHERE pp.idgrupo = idg
		AND pp.idproyecto = idp
		AND pp.idplan = idpp
        AND cp.exportado = 0
		ORDER BY cp.idcaso
		;
		
		SELECT 
			steps.caseId,
			steps.stepId,
			steps.`order`,
			steps.`action`,
			steps.result,
			steps.`data`,
			v.acN,
			v.acV,
			v.reN,
			v.reV,
			v.daN,
			v.daV
		FROM
		(
			SELECT 
				pa.idcaso AS caseId,
				concat(pa.idcaso,'.',pa.idpaso) AS stepId,
				pa.accion AS `action`,
				pa.datos AS `data`,
				pa.resultado AS `result`,
				pa.orden AS `order`        
			FROM pasos pa 
            JOIN casos_prueba casos ON pa.idgrupo = casos.idgrupo AND pa.idproyecto = casos.idproyecto AND pa.idplan = casos.idplan AND pa.idcaso = casos.idcaso
			WHERE pa.idgrupo = idg
			AND pa.idproyecto = idp
			AND pa.idplan = idpp
            AND casos.exportado = 0
			ORDER BY pa.idcaso, pa.orden
		) steps
		LEFT JOIN 
		(
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
		) v ON v.stepId = steps.stepId
		ORDER By steps.caseId, steps.order
		;		
    END IF;
END$$
DELIMITER ;



USE `docps-dev`;
DROP procedure IF EXISTS `MarkTestcasesAsExported`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `MarkTestcasesAsExported` (
	IN idg INTEGER,
	IN idp INTEGER,
	IN idpp INTEGER,
	IN statusExportado INTEGER,
    IN cuentaCasos INTEGER
)
BEGIN    
	DECLARE exit handler for SQLEXCEPTION
		BEGIN
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = @text;
			SELECT @full_error AS message, FALSE AS success;
			ROLLBACK;
		END;
	
	IF (cuentaCasos = -1) THEN
		SET cuentaCasos = 0;
	END IF;
    
	START TRANSACTION;
		UPDATE `docps-dev`.`casos_prueba` SET `exportado`=statusExportado 
        WHERE `idplan` = idpp
        AND `idproyecto` = idp
        AND `idgrupo` = idg;
        
        IF (statusExportado = 1) THEN
			INSERT INTO `docps-dev`.`operaciones_exportacion`(`idgrupo`,`fecha_operacion`,`total_casos_generados`,`estado`)
			VALUES(idg,SYSDATE(),cuentaCasos,1);
		END IF;
	COMMIT;
		SELECT 'TESTPLAN MARKED AS EXPORTED' AS message, 1 AS success;
END$$
DELIMITER ;


-- WORKSPACE STORED PROCEDURES

USE `docps-dev`;
DROP procedure IF EXISTS `GetTestcaseById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTestcaseById` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
	IN idcaso INTEGER
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
		CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS id
        ,cp.nombre AS `name`
        ,cp.descripcion AS description
        ,cp.precondiciones AS preconditions
        ,pr.nombre AS priority
        ,DATE_FORMAT(cp.fecha_ultima_modificacion, '%Y-%m-%d %H:%i') AS modifiedOn
        ,CAST(cp.exportado AS UNSIGNED) AS isExported
        ,CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan) AS testplanId
        ,pp.nombre AS testplanName
        ,CONCAT(cp.idgrupo,'.',cp.idproyecto) AS projectId
        ,p.nombre AS projectName
        ,cp.idgrupo AS groupId
        ,g.nombre AS groupName
        ,pa.accion AS stAction
        ,pa.resultado AS stResult
        ,pa.datos AS stData
        ,pa.orden AS stOrder
        ,tv.nombre AS vType
        ,v.nombre AS vName
        ,v.valor AS vValues
        ,ec.estado_del_caso AS `status`
	FROM casos_prueba cp
    JOIN planes pp ON pp.idgrupo = cp.idgrupo AND pp.idproyecto = cp.idproyecto AND pp.idplan = cp.idplan
    JOIN proyectos p ON cp.idgrupo = p.idgrupo AND cp.idproyecto = p.idproyecto 
    JOIN grupos g ON cp.idgrupo = g.idgrupo
    LEFT JOIN estado_casos ec ON ec.caso = CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso)
    LEFT JOIN pasos pa ON pa.idgrupo = cp.idgrupo AND pa.idproyecto = cp.idproyecto AND pa.idplan = cp.idplan AND pa.idcaso = cp.idcaso
    LEFT JOIN variables v ON v.idgrupo = cp.idgrupo AND v.idproyecto = cp.idproyecto AND v.idplan = cp.idplan AND v.idcaso = cp.idcaso AND pa.idpaso = v.idpaso
    LEFT JOIN tipoVariable tv ON tv.idtipov = v.idtipov
    LEFT JOIN prioridades pr ON cp.idprioridad = pr.idprioridad
    WHERE cp.idgrupo = idgrupo
    AND cp.idproyecto = idproyecto
    AND cp.idplan = idplan
    AND cp.idcaso = idcaso
    ORDER BY cp.idcaso, pa.idpaso, pa.orden    
    ;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InsertTestcase`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertTestcase` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
    IN nombre VARCHAR(255),
    IN precondiciones VARCHAR(512),
    IN prioridad INTEGER,
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
        INSERT INTO `docps-dev`.`casos_prueba`(`nombre`,`descripcion`,`precondiciones`,`idplan`,`idproyecto`,`idgrupo`,`fecha_creacion`,`fecha_ultima_modificacion`,`idprioridad`)
		VALUES (nombre,descripcion,precondiciones,idplan,idproyecto,idgrupo,SYSDATE(),SYSDATE(),prioridad);

	COMMIT;
		SELECT  
			CONCAT(idgrupo,'.',idproyecto,'.',idplan,'.',idcaso) 
        INTO @id
        FROM casos_prueba c WHERE c.idgrupo = idgrupo AND c.idproyecto = idproyecto AND c.idplan = idplan AND c.idcaso = last_insert_id();
		
        SELECT 'TESTCASE CREATED' AS message, 1 AS success, @id AS id;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `UpdateTestcase`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateTestcase` (
	IN `idgrupo` INTEGER,
    IN `idproyecto` INTEGER,
    IN `idplan` INTEGER,
    IN `idcaso` INTEGER,
	IN `nombre` VARCHAR(255),
	IN `descripcion` VARCHAR(255),
	IN `precondiciones` VARCHAR(255),
	IN `idprioridad` INTEGER
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
		UPDATE `docps-dev`.`casos_prueba` SET
		`nombre` = nombre,
		`descripcion` = descripcion,
		`precondiciones` = precondiciones,
		`idprioridad` = idprioridad,
		`fecha_ultima_modificacion` = SYSDATE(),
		`exportado` = 0
		WHERE `casos_prueba`.`idcaso` = idcaso 
		AND `casos_prueba`.`idplan` = idplan
		AND `casos_prueba`.`idproyecto` = idproyecto 
		AND `casos_prueba`.`idgrupo` = idgrupo;
	COMMIT;
		SELECT 'TESTCASE UPDATED' AS message
        , 1 AS success
        , nombre AS testcaseName
        , descripcion AS description
        , precondiciones AS preconditions
        , (SELECT p.nombre FROM prioridades p WHERE p.idprioridad = idprioridad) AS priority;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `InsertStepWithVariables`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertStepWithVariables` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
    IN idcaso INTEGER,
    IN acc VARCHAR(255),
    IN acc_var_n VARCHAR(255),
    IN acc_var_v VARCHAR(255),
    IN dat VARCHAR(255),
    IN dat_var_n VARCHAR(255),
    IN dat_var_v VARCHAR(255),
    IN res VARCHAR(255),
    IN res_var_n VARCHAR(255),
    IN res_var_v VARCHAR(255),
    IN ord INTEGER
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
        INSERT INTO `docps-dev`.`pasos`(`idcaso`,`idplan`,`idproyecto`,`idgrupo`,`accion`,`datos`,`resultado`,`orden`)
		VALUES(idcaso,idplan,idproyecto,idgrupo,acc,dat,res,ord);
        
        SET @nuevo_paso = last_insert_id();
		
        IF acc_var_n != '' AND acc_var_n IS NOT NULL THEN
			INSERT INTO `docps-dev`.`variables`(`idtipov`,`nombre`,`valor`,`idpaso`,`idcaso`,`idplan`,`idproyecto`,`idgrupo`)
			VALUES(1,acc_var_n,acc_var_v,@nuevo_paso,idcaso,idplan,idproyecto,idgrupo);
        END IF;

        IF dat_var_n != '' AND dat_var_n IS NOT NULL THEN
			INSERT INTO `docps-dev`.`variables`(`idtipov`,`nombre`,`valor`,`idpaso`,`idcaso`,`idplan`,`idproyecto`,`idgrupo`)
			VALUES(3,dat_var_n,dat_var_v,@nuevo_paso,idcaso,idplan,idproyecto,idgrupo);
		END IF;
        
        IF res_var_n != '' AND res_var_n IS NOT NULL THEN
			INSERT INTO `docps-dev`.`variables`(`idtipov`,`nombre`,`valor`,`idpaso`,`idcaso`,`idplan`,`idproyecto`,`idgrupo`)
			VALUES(2,res_var_n,res_var_v,@nuevo_paso,idcaso,idplan,idproyecto,idgrupo);
		END IF;

		UPDATE `docps-dev`.`casos_prueba` SET `fecha_ultima_modificacion`=SYSDATE() 
		WHERE `idgrupo`=idgrupo AND `idproyecto`=idproyecto AND `idplan`=idplan AND `idcaso`=idcaso;
    COMMIT;		
        SELECT 'STEP CREATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteStepsAndVariables`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteStepsAndVariables` (
	IN idgrupo INTEGER,
    IN idproyecto INTEGER,
    IN idplan INTEGER,
    IN idcaso INTEGER
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
		DELETE FROM `docps-dev`.`variables` 
					WHERE `variables`.`idcaso`=idcaso
					AND `variables`.`idplan`=idplan
					AND `variables`.`idproyecto`=idproyecto
			AND  `variables`.`idgrupo`=idgrupo;
					
			DELETE FROM `docps-dev`.`pasos` 
					WHERE `pasos`.`idcaso`=idcaso
					AND `pasos`.`idplan`=idplan
					AND `pasos`.`idproyecto`=idproyecto
			AND  `pasos`.`idgrupo`=idgrupo;
	COMMIT;
		SELECT 'STEPS DELETED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetTestplansDropdown`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTestplansDropdown` (
	IN idg INTEGER
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
		CONCAT(pp.idgrupo,'.',pp.idproyecto,'.',pp.idplan) AS id,
        pp.nombre AS title
	FROM planes pp 
    WHERE pp.idgrupo = idg
    ORDER BY pp.nombre ASC;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetTestcasesDropdown`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetTestcasesDropdown` (
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
		CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS id,
        cp.nombre AS title
	FROM casos_prueba cp
    WHERE cp.idgrupo=idg
    AND cp.idproyecto=idp
    AND cp.idplan=idpp
    ORDER BY cp.nombre ASC;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetStepsDropdown`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetStepsDropdown` (
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
		CONCAT(cp.idgrupo,'.',cp.idproyecto,'.',cp.idplan,'.',cp.idcaso) AS id,
        cp.nombre AS title
	FROM casos_prueba cp
    WHERE cp.idgrupo=idg
    AND cp.idproyecto=idp
    AND cp.idplan=idpp
    ORDER BY cp.nombre ASC;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `GetStepsDropdown`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetStepsDropdown` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER,
    IN idcp INTEGER
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
		CONCAT(pa.idgrupo,'.',pa.idproyecto,'.',pa.idplan,'.',pa.idcaso,'.',pa.idpaso) AS id,
        pa.accion AS `action`,
        pa.datos AS `data`,
        pa.resultado AS `result`,
        pa.orden AS `order`
	FROM pasos pa
    WHERE pa.idgrupo=idg
    AND pa.idproyecto=idp
    AND pa.idplan=idpp
    AND pa.idcaso=idcp
    ORDER BY pa.orden ASC;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteTestcase`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteTestcase` (
	IN `idg` INTEGER,
    IN `idp` INTEGER,
    IN `idpp` INTEGER,
    IN `idcp` INTEGER
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
		DELETE FROM `docps-dev`.`variables` WHERE idgrupo = idg AND idproyecto = idp AND idplan = idpp AND idcaso = idcp;
		DELETE FROM `docps-dev`.`pasos` WHERE idgrupo = idg AND idproyecto = idp AND idplan = idpp AND idcaso = idcp;
		DELETE FROM `docps-dev`.`casos_prueba` WHERE idgrupo = idg AND idproyecto = idp AND idplan = idpp AND idcaso = idcp;
	COMMIT;
		SELECT 'TESTCASE DELETED' AS message, 1 AS success;
END$$
DELIMITER ;


-- EXECUTIONS STORED PROCEDURES

USE `docps-dev`;
DROP procedure IF EXISTS `GetExecutionsForTestcase`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `GetExecutionsForTestcase` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER,
    IN idc INTEGER
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
		CONCAT(e.idgrupo,'.',e.idproyecto,'.',e.idplan,'.',e.idcaso,'.',idejecucion) AS id,
        CASE WHEN e.idestadoejecucion IS NULL THEN
			'Not executed'
		ELSE
			s.nombre
		END AS `status`,
        e.comentario AS commentary,
        DATE_FORMAT(e.fecha_ejecucion, '%Y-%m-%d %H:%i') AS createdOn
	FROM ejecuciones e
    LEFT JOIN estado_ejecuciones s ON e.idestadoejecucion = s.idestadoejecucion
    WHERE e.idgrupo = idg
    AND e.idproyecto = idp
    AND e.idplan = idpp
    AND e.idcaso = idc
    ORDER BY e.fecha_ejecucion DESC;
END$$
DELIMITER ;

USE `docps-dev`;
DROP procedure IF EXISTS `InsertExecution`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `InsertExecution` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER,
    IN idc INTEGER,
    IN idu INTEGER
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
        INSERT INTO `docps-dev`.`ejecuciones`(`idcaso`,`idplan`,`idproyecto`,`idgrupo`,`idusuario`,`fecha_ejecucion`)
		VALUES(idc,idpp,idp,idg,idu,SYSDATE());

	COMMIT;		
        SELECT 'EXECUTION CREATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `UpdateExecutionById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `UpdateExecutionById` (
	IN idg INTEGER,
    IN idp INTEGER,
    IN idpp INTEGER,
    IN idc INTEGER,
    IN ide INTEGER,
    IN comm VARCHAR(1024),
    IN idestado INTEGER
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
		IF idestado = 0 THEN
			UPDATE `docps-dev`.`ejecuciones`
			SET `comentario` = comm,`fecha_ejecucion` = SYSDATE(),`idestadoejecucion` = NULL
			WHERE `idejecucion` = ide
			AND `idcaso` = idc
			AND `idplan` = idpp
			AND `idproyecto` = idp
			AND `idgrupo` = idg;
		ELSE        
			UPDATE `docps-dev`.`ejecuciones`
			SET `comentario` = comm,`fecha_ejecucion` = SYSDATE(),`idestadoejecucion` = idestado
			WHERE `idejecucion` = ide
			AND `idcaso` = idc
			AND `idplan` = idpp
			AND `idproyecto` = idp
			AND `idgrupo` = idg;        
        END IF;
	COMMIT;		
        SELECT 'EXECUTION UPDATED' AS message, 1 AS success;
END$$
DELIMITER ;


USE `docps-dev`;
DROP procedure IF EXISTS `DeleteExecutionById`;
DELIMITER $$
USE `docps-dev`$$
CREATE PROCEDURE `DeleteExecutionById` (
	IN `idg` INTEGER,
    IN `idp` INTEGER,
    IN `idpp` INTEGER,
    IN `idc` INTEGER,
    IN `ide` INTEGER
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
		DELETE FROM `docps-dev`.`ejecuciones` WHERE idgrupo = idg AND idproyecto = idp AND idplan = idpp AND idcaso = idc AND idejecucion = ide;		
	COMMIT;
		SELECT 'EXECUTION DELETED' AS message, 1 AS success;
END$$
DELIMITER ;



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