-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema docps-dev
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `docps-dev` ;

-- -----------------------------------------------------
-- Schema docps-dev
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `docps-dev` DEFAULT CHARACTER SET utf8 ;
USE `docps-dev` ;

-- -----------------------------------------------------
-- Table `docps-dev`.`archivos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`archivos` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`archivos` (
  `idarchivo` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(255) NULL,
  `bytes` INT NULL,
  PRIMARY KEY (`idarchivo`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`usuarios`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`usuarios` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`usuarios` (
  `idusuario` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(45) NULL,
  `apellido` VARCHAR(45) NULL,
  `estado_alta` BIT(1) NULL DEFAULT 0,
  `fecha_alta` DATETIME NULL,
  `es_admin` BIT(1) NULL DEFAULT 0,
  `idarchivo_img` INT NULL,
  `dni` VARCHAR(45) NULL,
  `calle` VARCHAR(45) NULL,
  `num_calle` VARCHAR(10) NULL,
  `direccion_extra` VARCHAR(45) NULL,
  `puesto` VARCHAR(45) NULL,
  PRIMARY KEY (`idusuario`),
  INDEX `fk_usuario_archivos1_idx` (`idarchivo_img` ASC),
  CONSTRAINT `fk_usuario_archivos1`
    FOREIGN KEY (`idarchivo_img`)
    REFERENCES `docps-dev`.`archivos` (`idarchivo`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`cuentas`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`cuentas` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`cuentas` (
  `idcuenta` INT NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(255) NOT NULL,
  `clave` VARCHAR(255) NULL,
  `email` VARCHAR(255) NULL,
  `fecha_creacion` DATETIME NULL,
  `idusuario` INT NOT NULL,
  `eliminada` BIT(1) NULL DEFAULT 0,
  PRIMARY KEY (`idcuenta`, `idusuario`),
  UNIQUE INDEX `username_UNIQUE` (`username` ASC),
  UNIQUE INDEX `fk_cuentas_usuario_idx` (`idusuario` ASC),
  INDEX `email_idx` (`email` ASC),
  CONSTRAINT `fk_cuentas_usuario`
    FOREIGN KEY (`idusuario`)
    REFERENCES `docps-dev`.`usuarios` (`idusuario`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`default_avatar`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`default_avatar` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`default_avatar` (
  `iddefavatar` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NULL,
  PRIMARY KEY (`iddefavatar`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`grupos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`grupos` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`grupos` (
  `idgrupo` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(45) NOT NULL,
  `estado_alta` BIT(1) NULL DEFAULT 0,
  `fecha_alta` DATETIME NULL,
  `fecha_baja` DATETIME NULL,
  `idarchivo_img` INT NULL,
  `iddefavatar` INT NULL,
  PRIMARY KEY (`idgrupo`),
  INDEX `fk_grupos_archivos1_idx` (`idarchivo_img` ASC),
  INDEX `fk_grupos_default_avatar1_idx` (`iddefavatar` ASC),
  CONSTRAINT `fk_grupos_archivos1`
    FOREIGN KEY (`idarchivo_img`)
    REFERENCES `docps-dev`.`archivos` (`idarchivo`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_grupos_default_avatar1`
    FOREIGN KEY (`iddefavatar`)
    REFERENCES `docps-dev`.`default_avatar` (`iddefavatar`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`proyectos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`proyectos` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`proyectos` (
  `idproyecto` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(45) NOT NULL,
  `fecha_creacion` DATETIME NULL,
  `idgrupo` INT NOT NULL,
  PRIMARY KEY (`idproyecto`, `idgrupo`),
  INDEX `fk_proyectos_grupos1_idx` (`idgrupo` ASC),
  UNIQUE INDEX `nombre_proyecto_grupo` (`nombre` ASC, `idgrupo` ASC),
  CONSTRAINT `fk_proyectos_grupos1`
    FOREIGN KEY (`idgrupo`)
    REFERENCES `docps-dev`.`grupos` (`idgrupo`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`usuarios_grupos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`usuarios_grupos` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`usuarios_grupos` (
  `idgrupo` INT NOT NULL,
  `idusuario` INT NOT NULL,
  `admin_grupo` BIT(1) NULL DEFAULT 0,
  `fecha_alta` DATETIME NULL,
  PRIMARY KEY (`idgrupo`, `idusuario`),
  INDEX `fk_grupos_has_usuario_usuario1_idx` (`idusuario` ASC),
  INDEX `fk_grupos_has_usuario_grupos1_idx` (`idgrupo` ASC),
  CONSTRAINT `fk_grupos_has_usuario_grupos1`
    FOREIGN KEY (`idgrupo`)
    REFERENCES `docps-dev`.`grupos` (`idgrupo`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_grupos_has_usuario_usuario1`
    FOREIGN KEY (`idusuario`)
    REFERENCES `docps-dev`.`usuarios` (`idusuario`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`planes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`planes` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`planes` (
  `idplan` INT NOT NULL AUTO_INCREMENT,
  `fecha_creacion` DATETIME NULL,
  `nombre` VARCHAR(255) NULL,
  `descripcion` VARCHAR(1000) NULL,
  `idproyecto` INT NOT NULL,
  `idgrupo` INT NOT NULL,
  PRIMARY KEY (`idplan`, `idproyecto`, `idgrupo`),
  UNIQUE INDEX `nombre_plan_proyecto` (`nombre` ASC, `idproyecto` ASC, `idgrupo` ASC),
  INDEX `fk_planes_proyectos1_idx` (`idproyecto` ASC, `idgrupo` ASC),
  CONSTRAINT `fk_planes_proyectos1`
    FOREIGN KEY (`idproyecto` , `idgrupo`)
    REFERENCES `docps-dev`.`proyectos` (`idproyecto` , `idgrupo`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`casos_prueba`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`casos_prueba` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`casos_prueba` (
  `idcaso` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(255) NULL,
  `descripcion` VARCHAR(255) NULL,
  `precondiciones` VARCHAR(512) NULL,
  `idplan` INT NOT NULL,
  `idproyecto` INT NOT NULL,
  `idgrupo` INT NOT NULL,
  `prioridad` INT NULL,
  `fecha_creacion` DATETIME NULL,
  `fecha_ultima_modificacion` DATETIME NULL,
  `exportado` BIT(1) NULL DEFAULT 0,
  PRIMARY KEY (`idcaso`, `idplan`, `idproyecto`, `idgrupo`),
  INDEX `fk_casos_prueba_planes1_idx` (`idplan` ASC, `idproyecto` ASC, `idgrupo` ASC),
  UNIQUE INDEX `nombre_casos_planes` (`nombre` ASC, `idproyecto` ASC, `idplan` ASC, `idgrupo` ASC),
  CONSTRAINT `fk_casos_prueba_planes1`
    FOREIGN KEY (`idplan` , `idproyecto` , `idgrupo`)
    REFERENCES `docps-dev`.`planes` (`idplan` , `idproyecto` , `idgrupo`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`pasos`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`pasos` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`pasos` (
  `idpaso` INT NOT NULL AUTO_INCREMENT,
  `idcaso` INT NOT NULL,
  `idplan` INT NOT NULL,
  `idproyecto` INT NOT NULL,
  `idgrupo` INT NOT NULL,
  `accion` VARCHAR(100) NULL,
  `datos` VARCHAR(100) NULL,
  `resultado` VARCHAR(100) NULL,
  PRIMARY KEY (`idpaso`, `idcaso`, `idplan`, `idproyecto`, `idgrupo`),
  CONSTRAINT `fk_pasos_casos_prueba1`
    FOREIGN KEY (`idcaso` , `idplan` , `idproyecto` , `idgrupo`)
    REFERENCES `docps-dev`.`casos_prueba` (`idcaso` , `idplan` , `idproyecto` , `idgrupo`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`variables`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`variables` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`variables` (
  `idvariable` INT NOT NULL AUTO_INCREMENT,
  `valor` JSON NOT NULL,
  `idpaso` INT NOT NULL,
  `idcaso` INT NOT NULL,
  `idplan` INT NOT NULL,
  `idproyecto` INT NOT NULL,
  `idgrupo` INT NOT NULL,
  PRIMARY KEY (`idvariable`, `idpaso`, `idcaso`, `idplan`, `idproyecto`, `idgrupo`),
  INDEX `fk_variables_pasos1_idx` (`idcaso` ASC, `idplan` ASC, `idproyecto` ASC, `idgrupo` ASC, `idpaso` ASC),
  CONSTRAINT `fk_variables_pasos1`
    FOREIGN KEY (`idcaso` , `idplan` , `idproyecto` , `idgrupo` , `idpaso`)
    REFERENCES `docps-dev`.`pasos` (`idcaso` , `idplan` , `idproyecto` , `idgrupo` , `idpaso`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`ejecuciones`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`ejecuciones` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`ejecuciones` (
  `idejecucion` INT NOT NULL AUTO_INCREMENT,
  `estado` INT NOT NULL DEFAULT 0,
  `comentario` VARCHAR(255) NULL,
  `idcaso` INT NOT NULL,
  `idplan` INT NOT NULL,
  `idproyecto` INT NOT NULL,
  `idgrupo` INT NOT NULL,
  `idusuario` INT NULL,
  PRIMARY KEY (`idejecucion`, `idcaso`, `idplan`, `idproyecto`, `idgrupo`),
  INDEX `fk_ejecuciones_casos_prueba1_idx` (`idcaso` ASC, `idplan` ASC, `idproyecto` ASC, `idgrupo` ASC),
  INDEX `fk_ejecuciones_usuarios1_idx` (`idusuario` ASC),
  CONSTRAINT `fk_ejecuciones_casos_prueba1`
    FOREIGN KEY (`idcaso` , `idplan` , `idproyecto` , `idgrupo`)
    REFERENCES `docps-dev`.`casos_prueba` (`idcaso` , `idplan` , `idproyecto` , `idgrupo`)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT `fk_ejecuciones_usuarios1`
    FOREIGN KEY (`idusuario`)
    REFERENCES `docps-dev`.`usuarios` (`idusuario`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`etiquetas`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`etiquetas` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`etiquetas` (
  `idetiqueta` INT NOT NULL AUTO_INCREMENT,
  `valor` VARCHAR(32) NOT NULL,
  PRIMARY KEY (`idetiqueta`),
  UNIQUE INDEX `valor_UNIQUE` (`valor` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`planes_etiquetas`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`planes_etiquetas` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`planes_etiquetas` (
  `idplan` INT NOT NULL,
  `idetiqueta` INT NOT NULL,
  PRIMARY KEY (`idplan`, `idetiqueta`),
  INDEX `fk_planes_has_etiquetas_etiquetas1_idx` (`idetiqueta` ASC),
  INDEX `fk_planes_has_etiquetas_planes1_idx` (`idplan` ASC),
  CONSTRAINT `fk_planes_has_etiquetas_planes1`
    FOREIGN KEY (`idplan`)
    REFERENCES `docps-dev`.`planes` (`idplan`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_planes_has_etiquetas_etiquetas1`
    FOREIGN KEY (`idetiqueta`)
    REFERENCES `docps-dev`.`etiquetas` (`idetiqueta`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`operaciones_exportacion`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`operaciones_exportacion` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`operaciones_exportacion` (
  `idoperacion` INT NOT NULL AUTO_INCREMENT,
  `idgrupo` INT NOT NULL,
  `fecha_operacion` DATETIME NULL,
  `total_casos_generados` INT NULL,
  `estado` INT NULL DEFAULT 0,
  PRIMARY KEY (`idoperacion`, `idgrupo`),
  INDEX `fk_operaciones_exportacion_grupos1_idx` (`idgrupo` ASC),
  CONSTRAINT `fk_operaciones_exportacion_grupos1`
    FOREIGN KEY (`idgrupo`)
    REFERENCES `docps-dev`.`grupos` (`idgrupo`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`tipo_reporte`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`tipo_reporte` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`tipo_reporte` (
  `idtipo_reporte` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(45) NULL,
  PRIMARY KEY (`idtipo_reporte`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `docps-dev`.`reportes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `docps-dev`.`reportes` ;

CREATE TABLE IF NOT EXISTS `docps-dev`.`reportes` (
  `idreporte` INT NOT NULL AUTO_INCREMENT,
  `idtipo` INT NULL,
  `fecha_descarga` DATETIME NULL,
  `idgrupo` INT NULL,
  `idarchivo` INT NULL,
  PRIMARY KEY (`idreporte`),
  INDEX `fk_reportes_tipo_reporte1_idx` (`idtipo` ASC),
  INDEX `fk_reportes_grupos1_idx` (`idgrupo` ASC),
  INDEX `fk_reportes_archivos1_idx` (`idarchivo` ASC),
  CONSTRAINT `fk_reportes_tipo_reporte1`
    FOREIGN KEY (`idtipo`)
    REFERENCES `docps-dev`.`tipo_reporte` (`idtipo_reporte`)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT `fk_reportes_grupos1`
    FOREIGN KEY (`idgrupo`)
    REFERENCES `docps-dev`.`grupos` (`idgrupo`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_reportes_archivos1`
    FOREIGN KEY (`idarchivo`)
    REFERENCES `docps-dev`.`archivos` (`idarchivo`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB;

USE `docps-dev`;

DELIMITER $$

USE `docps-dev`$$
DROP TRIGGER IF EXISTS `docps-dev`.`validar_cuenta_insert` $$
USE `docps-dev`$$
CREATE DEFINER = CURRENT_USER TRIGGER `docps-dev`.`validar_cuenta_insert` BEFORE INSERT ON `cuentas` FOR EACH ROW
BEGIN
    DECLARE validEmail INT DEFAULT 1; 
    DECLARE validUsername INT DEFAULT 1;     
	SELECT CASE WHEN (C.CUENTAS = 0) THEN 1 ELSE 0 END 
    INTO validEmail
	FROM (
		SELECT COUNT(*) AS CUENTAS
		FROM cuentas c
		WHERE c.email = new.email
		AND c.eliminada = 0
    ) C;
     
	SELECT CASE WHEN (C.NOMBREUSUARIO = 0) THEN 1 ELSE 0 END 
    INTO validUsername
	FROM (
		SELECT COUNT(*) AS NOMBREUSUARIO
		FROM cuentas c
		WHERE c.username = new.username
		AND c.eliminada = 0
    ) C;
    
    IF validEmail = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EXISTING EMAIL';
	END IF;
    
    IF validUsername = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EXISTING NAME';
	END IF; 
END$$


USE `docps-dev`$$
DROP TRIGGER IF EXISTS `docps-dev`.`validar_cuenta_update` $$
USE `docps-dev`$$
CREATE DEFINER = CURRENT_USER TRIGGER `docps-dev`.`validar_cuenta_update` BEFORE UPDATE ON `cuentas` FOR EACH ROW
BEGIN
    DECLARE validEmail INT DEFAULT 1; 
    DECLARE validUsername INT DEFAULT 1;     
	SELECT CASE WHEN (C.CUENTAS = 0) THEN 1 ELSE 0 END 
    INTO validEmail
	FROM (
		SELECT COUNT(*) AS CUENTAS
		FROM cuentas c
		WHERE c.email = new.email
		AND c.eliminada = 0
        AND c.idusuario != old.idusuario
        AND c.idcuenta != old.idcuenta
    ) C;
     
	SELECT CASE WHEN (C.NOMBREUSUARIO = 0) THEN 1 ELSE 0 END 
    INTO validUsername
	FROM (
		SELECT COUNT(*) AS NOMBREUSUARIO
		FROM cuentas c
		WHERE c.username = new.username
		AND c.eliminada = 0
        AND c.idusuario != old.idusuario
        AND c.idcuenta != old.idcuenta
    ) C;
    
    IF validEmail = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EXISTING EMAIL';
	END IF;
    
    IF validUsername = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EXISTING NAME';
	END IF;
END$$


USE `docps-dev`$$
DROP TRIGGER IF EXISTS `docps-dev`.`validar_grupos_insert` $$
USE `docps-dev`$$
CREATE DEFINER = CURRENT_USER TRIGGER `docps-dev`.`validar_grupos_insert` BEFORE INSERT ON `grupos` FOR EACH ROW
BEGIN
    DECLARE validName INT DEFAULT 1;
     
	SELECT CASE WHEN (C.NOMBREGRUPO = 0) THEN 1 ELSE 0 END 
    INTO validName
	FROM (
		SELECT COUNT(*) AS NOMBREGRUPO
		FROM grupos 
		WHERE nombre = new.nombre
    ) C;
    
    IF validName = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EXISTING NAME';
	END IF;
END$$


USE `docps-dev`$$
DROP TRIGGER IF EXISTS `docps-dev`.`validar_grupos_update` $$
USE `docps-dev`$$
CREATE DEFINER = CURRENT_USER TRIGGER `docps-dev`.`validar_grupos_update` BEFORE UPDATE ON `grupos` FOR EACH ROW
BEGIN
    DECLARE validName INT DEFAULT 1;     
	SELECT CASE WHEN (C.NOMBREGRUPO = 0) THEN 1 ELSE 0 END 
    INTO validName
	FROM (
		SELECT COUNT(*) AS NOMBREGRUPO
		FROM grupos
		WHERE nombre = new.nombre
        AND idgrupo != old.idgrupo
    ) C;
    
    IF validName = 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'EXISTING NAME';
	END IF;

END$$


USE `docps-dev`$$
DROP TRIGGER IF EXISTS `docps-dev`.`validar_grupos_delete` $$
USE `docps-dev`$$
CREATE DEFINER = CURRENT_USER TRIGGER `docps-dev`.`validar_grupos_delete` BEFORE DELETE ON `grupos` FOR EACH ROW
BEGIN
    DECLARE hasProjects INT DEFAULT 0;     
	SELECT CASE WHEN (C.PROYECTOS > 0) THEN 1 ELSE 0 END 
    INTO hasProjects
	FROM (
		SELECT COUNT(*) AS PROYECTOS
		FROM proyectos
		WHERE idgrupo = old.idgrupo
    ) C;
    
    IF hasProjects = 1 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'HAS PROJECTS';
	END IF;

END$$


DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- -----------------------------------------------------
-- Data for table `docps-dev`.`usuarios`
-- -----------------------------------------------------
START TRANSACTION;
USE `docps-dev`;
INSERT INTO `docps-dev`.`usuarios` (`idusuario`, `nombre`, `apellido`, `estado_alta`, `fecha_alta`, `es_admin`, `idarchivo_img`, `dni`, `calle`, `num_calle`, `direccion_extra`, `puesto`) VALUES (1, 'Agustin', 'Juan', 1, '2021-04-13 21:00:00', 1, NULL, '38900000', 'Calle1', '1812', 'Barrio1', 'Software Engineer III');
INSERT INTO `docps-dev`.`usuarios` (`idusuario`, `nombre`, `apellido`, `estado_alta`, `fecha_alta`, `es_admin`, `idarchivo_img`, `dni`, `calle`, `num_calle`, `direccion_extra`, `puesto`) VALUES (2, 'Admin', 'Test', 1, '2021-04-13 21:00:00', 1, NULL, '38900000', 'Calle1', '1812', 'Barrio1', 'Software Engineer III');

COMMIT;


-- -----------------------------------------------------
-- Data for table `docps-dev`.`cuentas`
-- -----------------------------------------------------
START TRANSACTION;
USE `docps-dev`;
INSERT INTO `docps-dev`.`cuentas` (`idcuenta`, `username`, `clave`, `email`, `fecha_creacion`, `idusuario`, `eliminada`) VALUES (1, 'agusdev', '123', 'agustingarcia@gmail.com', '2021-04-13 21:00:00', 1, 0);
INSERT INTO `docps-dev`.`cuentas` (`idcuenta`, `username`, `clave`, `email`, `fecha_creacion`, `idusuario`, `eliminada`) VALUES (2, 'testadmin', '123', 'test@admin.docps', '2021-04-13 21:00:00', 2, 0);

COMMIT;


-- -----------------------------------------------------
-- Data for table `docps-dev`.`default_avatar`
-- -----------------------------------------------------
START TRANSACTION;
USE `docps-dev`;
INSERT INTO `docps-dev`.`default_avatar` (`iddefavatar`, `name`) VALUES (1, 'defred');
INSERT INTO `docps-dev`.`default_avatar` (`iddefavatar`, `name`) VALUES (2, 'defyellow');
INSERT INTO `docps-dev`.`default_avatar` (`iddefavatar`, `name`) VALUES (3, 'defgreen');
INSERT INTO `docps-dev`.`default_avatar` (`iddefavatar`, `name`) VALUES (4, 'defblue');
INSERT INTO `docps-dev`.`default_avatar` (`iddefavatar`, `name`) VALUES (5, 'defpurple');

COMMIT;


-- -----------------------------------------------------
-- Data for table `docps-dev`.`grupos`
-- -----------------------------------------------------
START TRANSACTION;
USE `docps-dev`;
INSERT INTO `docps-dev`.`grupos` (`idgrupo`, `nombre`, `estado_alta`, `fecha_alta`, `fecha_baja`, `idarchivo_img`, `iddefavatar`) VALUES (1, 'Panteras', 1, '2021-04-13 21:00:00', NULL, NULL, 1);
INSERT INTO `docps-dev`.`grupos` (`idgrupo`, `nombre`, `estado_alta`, `fecha_alta`, `fecha_baja`, `idarchivo_img`, `iddefavatar`) VALUES (2, 'Lobos', 1, '2021-05-10 20:00:00', NULL, NULL, 2);
INSERT INTO `docps-dev`.`grupos` (`idgrupo`, `nombre`, `estado_alta`, `fecha_alta`, `fecha_baja`, `idarchivo_img`, `iddefavatar`) VALUES (3, 'Pumas', 1, '2021-05-10 20:00:00', NULL, NULL, 3);

COMMIT;


-- -----------------------------------------------------
-- Data for table `docps-dev`.`usuarios_grupos`
-- -----------------------------------------------------
START TRANSACTION;
USE `docps-dev`;
INSERT INTO `docps-dev`.`usuarios_grupos` (`idgrupo`, `idusuario`, `admin_grupo`, `fecha_alta`) VALUES (1, 1, 1, '2021-04-13 21:00:00');
INSERT INTO `docps-dev`.`usuarios_grupos` (`idgrupo`, `idusuario`, `admin_grupo`, `fecha_alta`) VALUES (2, 1, 0, '2021-05-20 21:00:00');
INSERT INTO `docps-dev`.`usuarios_grupos` (`idgrupo`, `idusuario`, `admin_grupo`, `fecha_alta`) VALUES (3, 1, 0, '2021-05-20 21:00:00');

COMMIT;


-- -----------------------------------------------------
-- Data for table `docps-dev`.`tipo_reporte`
-- -----------------------------------------------------
START TRANSACTION;
USE `docps-dev`;
INSERT INTO `docps-dev`.`tipo_reporte` (`idtipo_reporte`, `nombre`) VALUES (1, 'num_casos_prueba');
INSERT INTO `docps-dev`.`tipo_reporte` (`idtipo_reporte`, `nombre`) VALUES (2, 'num_ejecuciones');

COMMIT;

