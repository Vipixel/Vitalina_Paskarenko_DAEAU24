-- Created table

-- 602521600 bytes total_bytes 
-- 575 MB table text

-- DELETE 1/3

-- 601521600 bytes total_bytes 
-- 575 MB table text
-- Query returned successfully in 9 secs 945 msec.

-- VACUUM

-- Query returned successfully in 5 secs 240 msec.

-- 401580032 bytes total_bytes 
-- 383 MB table text

--------CREATE TABLE to delete by truncate function

-- TRUNCATE table_to_delete;
-- Query returned successfully in 72 msec.
-- 8192 bytes total_bytes 
-- 0 MB table text

---Conclusion: 

-- After creating the table and deleting 1/3 of the rows, the storage size didn’t change until we ran vacuum, what clean unused space.
-- Finally, using truncate emptied the table completely and reduced its size to almost zero.

-- My note that after deleting rows, it's important to run the `VACUUM` function to clean unused space and optimize database performance.
