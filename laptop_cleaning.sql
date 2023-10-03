SELECT * FROM campusx.laptopdata;

-- First of all create backup of your data
CREATE TABLE laptop_backup LIKE laptopdata;

INSERT INTO laptop_backup
SELECT * FROM laptopdata;

-- Count number of rows
SELECT COUNT(*) FROM laptopdata;

-- Check Memory Consumption
SELECT DATA_LENGTH/1024 FROM information_schema.TABLES
WHERE TABLE_SCHEMA = "campusx"
AND TABLE_NAME = "laptopdata";

-- Drop unwanted columns

-- Drop all null values
 ALTER TABLE laptopdata
 RENAME COLUMN `Unnamed: 0` to `index` ;

DELETE FROM `laptopdata` 
WHERE `index` IN (SELECT `index` FROM (SELECT `index` FROM `laptopdata`
	WHERE Company IS NULL AND TypeName IS NULL AND Inches IS NULL
	AND ScreenResolution IS NULL AND Cpu IS NULL AND Ram IS NULL
	AND Memory IS NULL AND Gpu IS NULL AND OpSys IS NULL AND
	Weight IS NULL AND Price IS NULL) as t);
    
-- Drop Duplicates
DELETE FROM campusx.laptopdata
WHERE `index` NOT IN ( SELECT `index` FROM(
SELECT MIN(`index`) FROM laptopdata
GROUP BY Company,TypeName,Inches,ScreenResolution,Cpu,Ram,Memory,Gpu,OpSys,Weight,Price) AS t);

-- Clean ram by changing data types of column
ALTER TABLE laptopdata MODIFY COLUMN Inches DECIMAL(10,1);

-- To replace the "GB" in ram column to ""
UPDATE laptopdata l1
SET Ram = (SELECT REPLACE(Ram,"GB","") FROM (SELECT * FROM laptopdata) l2 WHERE l2.index=l1.index);
-- To change the datatype of ram column to integer
ALTER TABLE laptopdata MODIFY COLUMN Ram INTEGER;

-- To replace the "Kg" from Weight column to ""
UPDATE laptopdata l1
SET Weight = (SELECT REPLACE(Weight,"kg","") FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
-- To replace the "?" from Weight column to "0"
UPDATE laptopdata l1
SET Weight = (SELECT REPLACE(Weight,"null","0") FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
-- To change the datatype of Weight column to Decimal
ALTER TABLE laptopdata MODIFY COLUMN Weight DECIMAL(10,2);

-- To round of the value of price column
UPDATE laptopdata l1
SET Price = (SELECT ROUND(Price) FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
-- To change the datatype of Price column to Integer
ALTER TABLE laptopdata MODIFY COLUMN Price INTEGER;

-- Now we categorize "OpSys" column
UPDATE laptopdata
SET OpSys=CASE 
	WHEN OpSys LIKE "%mac%" THEN "macos"
    WHEN OpSys LIKE "%Windows%" THEN "windows"
    ELSE "others"
END;

-- Now we select gpu column and make it into two columns gpu_brand and gpu_name and then fill those values
ALTER  TABLE laptopdata
ADD COLUMN gpu_brand VARCHAR(255) AFTER gpu,
ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;
-- Here we fill the value of gpu_brand
UPDATE laptopdata l1
SET gpu_brand = (SELECT SUBSTRING_INDEX(gpu," ",1) FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
-- Here we fill the value of gpu_name
UPDATE laptopdata l1
SET gpu_name = (SELECT REPLACE(gpu,gpu_brand,"") FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
-- now we drop the gpu column
ALTER TABLE laptopdata DROP COLUMN gpu;


-- Now we select cpu column and make it into three columns cpu_brand, cpu_name and cpu_speed and then fill those values
ALTER TABLE laptopdata
ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed VARCHAR(255) AFTER cpu_name;
-- here we update cpu_speed column then replace ghz with nothing and then change its datatype to decimal 
UPDATE laptopdata l1
SET cpu_speed = (SELECT SUBSTRING_INDEX(Cpu," ",-1) FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
UPDATE laptopdata l1
SET cpu_speed = (SELECT REPLACE(cpu_speed,"GHz","") FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
ALTER TABLE laptopdata MODIFY COLUMN cpu_speed DECIMAL(10,2);
-- Here we update cpu_brand column 
UPDATE laptopdata l1
SET cpu_brand = (SELECT SUBSTRING_INDEX(Cpu," ",1) FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
-- Now we update cpu_name column in this first we replace cpu with cpu_brand and cpu_speed and then put "" at their places
UPDATE laptopdata l1
SET cpu_name = (SELECT REPLACE(Cpu,cpu_brand,"") FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
UPDATE laptopdata l1
SET cpu_name = (SELECT REPLACE(cpu_name,SUBSTRING_INDEX(Cpu," ",-1),"") FROM (SELECT * FROM laptopdata) l2 WHERE l1.index=l2.index);
-- Then we convert cpu_speed column to decimal
ALTER TABLE laptopdata MODIFY COLUMN cpu_speed DECIMAL(10,2);
-- Then we drop cpu column
ALTER TABLE laptopdata DROP COLUMN Cpu;

-- Now we are going to handle ScreenResolution column 
-- In this first we are going to find out resolution_height and resolution_width
ALTER TABLE laptopdata
ADD COLUMN width VARCHAR(255) AFTER ScreenResolution,
ADD COLUMN height VARCHAR(255) AFTER width;
ALTER TABLE laptopdata
ADD COLUMN touchscreen VARCHAR(255) AFTER height;
-- Here we fill the value 0f width and height
UPDATE laptopdata
SET width = (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution," ",-1),"x",1)  ),
height = (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution," ",-1),"x",-1) );

-- Here we make 5 new columns to categorize the screenresolution column and to extract more info out of it
ALTER TABLE laptopdata
ADD COLUMN fullhd INTEGER AFTER height,
ADD COLUMN quadhd INTEGER AFTER fullhd,
ADD COLUMN retina INTEGER AFTER quadhd,
ADD COLUMN `4k` INTEGER AFTER retina,
ADD COLUMN touchscreen INTEGER AFTER `4k`;

-- Then we fill the values in those columns
UPDATE laptopdata
SET fullhd = ScreenResolution LIKE "%Full HD%",
quadhd = ScreenResolution LIKE "%Quad HD%",
retina = ScreenResolution LIKE "%Retina%",
`4k` = ScreenResolution LIKE "%4K%",
touchscreen = ScreenResolution LIKE "%Touch%";
-- Then we drop the column screen resolution
ALTER TABLE laptopdata DROP COLUMN ScreenResolution;

-- Now we are going to modify Memory column
ALTER TABLE laptopdata
ADD COLUMN ssd VARCHAR(255) AFTER Memory,
ADD COLUMN hdd VARCHAR(255) AFTER ssd,
ADD COLUMN flash_storage VARCHAR(255) AFTER hdd,
ADD COLUMN hybrid VARCHAR(255) AFTER flash_storage;

-- Fill the value in those columns 
UPDATE laptopdata
SET ssd= SUBSTRING_INDEX(Memory,"+",1),
 hdd= SUBSTRING_INDEX(Memory,"+",-1);
 
 UPDATE laptopdata
SET flash_storage = (
CASE WHEN ssd LIKE "%Flash%" THEN ssd
	WHEN hdd LIKE "%Flash%" THEN hdd
    ELSE 0
END);

UPDATE laptopdata
SET hybrid = (
CASE WHEN ssd LIKE "%Hybrid%" THEN ssd
	WHEN hdd LIKE "%Hybrid%" THEN hdd
    ELSE 0
END);

UPDATE laptopdata
SET ssd = (
CASE WHEN ssd LIKE "%SSD%" THEN ssd
    ELSE 0
END);
UPDATE laptopdata
SET ssd = SUBSTRING_INDEX(ssd," ",1),
ssd= REPLACE(ssd,"GB",""),
ssd= REPLACE(ssd,"TB","");
UPDATE laptopdata
SET ssd=CASE WHEN ssd<3 THEN ssd*1024
ELSE ssd
END;


UPDATE laptopdata
SET hdd = (
CASE WHEN hdd LIKE "%HDD%" THEN hdd
    ELSE 0
END);
UPDATE laptopdata
SET hdd = SUBSTRING_INDEX(hdd," ",1),
hdd= REPLACE(hdd,"GB",""),
hdd= REPLACE(hdd,"TB","");
UPDATE laptopdata
SET hdd=CASE WHEN hdd<3 THEN hdd*1024
ELSE hdd
END;

UPDATE laptopdata
SET flash_storage = SUBSTRING_INDEX(flash_storage," ",1),
flash_storage= REPLACE(flash_storage,"GB",""),
flash_storage= REPLACE(flash_storage,"TB","");
UPDATE laptopdata
SET flash_storage=CASE WHEN flash_storage<3 THEN flash_storage*1024
ELSE flash_storage
END;

UPDATE laptopdata
SET hybrid = SUBSTRING_INDEX(hybrid ," ",1),
hybrid = REPLACE(hybrid ,"GB",""),
hybrid = REPLACE(hybrid ,"TB","");
UPDATE laptopdata
SET hybrid =CASE WHEN hybrid<3 THEN hybrid *1024
ELSE hybrid 
END;
-- finally drop the memory column
ALTER TABLE laptopdata DROP COLUMN Memory;





 
 









