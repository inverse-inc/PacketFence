--
-- category of temporary_password is not mandatory
--

ALTER TABLE `temporary_password` MODIFY category int DEFAULT NULL;

--
-- access_level of temporary_password is now a string instead of a bit string
--

ALTER TABLE temporary_password CHANGE access_level access_level varchar(255) DEFAULT 'NONE';
UPDATE temporary_password SET access_level = 'ALL' WHERE access_level = '4294967295';
UPDATE temporary_password SET access_level = 'NONE' WHERE access_level = '0';
