SELECT DISTINCT
    process.name
  , listening.address
  , listening.port
  , process.pid
FROM processes AS process
JOIN listening_ports AS listening
    ON process.pid = listening.pid
WHERE listening.address IS NOT null
    AND listening.address <> '';
