WITH
MYTABLE(StartDate,EndDate,EndDate2) AS
(SELECT MR.CREATIONDATE AS StartDate, WO.WOEND AS EndDate,
WO2.WOEND AS EndDate2 
-- ^ Verifie si year-1 ou +1 d'OT Projet même Year OT Inter
FROM CSWO_WO WO  
left outer join cswo_wolink wok on wok.WOLINK_ID = WO.ID
left outer join cswo_wo wo2 on wo2.id=wok.WOSOURCE_ID
   INNER JOIN CSWO_MR MR
   ON MR.WO_ID = WO2.ID
   INNER JOIN CSWO_WOEQPT WE
   ON WE.WO_ID = WO.ID  
WHERE WE.EQPT_ID = {bean.id}
  --AND wok.orderlink = 1
  AND WO.STATUS_CODE = 'CLOSED'
  AND ( MR.EQPTBROKEN = {true} OR WO2.EQPTBROKEN = {true} )
  AND MR.CREATIONDATE < {endOfYear}
  AND WO.WOEND > {startOfYear}
  AND MR.CREATIONDATE < WO.WOEND 
)
, -- OT Intervention ne se chevauche plus
MYTABLE2(StartDate,EndDate) AS
(SELECT   s1.StartDate,
      MIN(t1.EndDate) AS EndDate
FROM MYTABLE s1 
INNER JOIN MYTABLE t1 ON s1.StartDate <= t1.EndDate
     AND NOT EXISTS(SELECT * FROM MYTABLE t2 
        WHERE t1.EndDate >= t2.StartDate AND t1.EndDate < t2.EndDate) 
WHERE NOT EXISTS(SELECT * FROM MYTABLE s2 
    WHERE s1.StartDate > s2.StartDate 
    AND s1.StartDate <= s2.EndDate ) 
GROUP BY s1.StartDate
ORDER BY s1.StartDate )


SELECT COALESCE(SUM(R0.NB_PANNES),0)
FROM

(SELECT COUNT(*) AS NB_PANNES FROM MYTABLE) R0
