-- Somme des heures de pannes à l'année sur un moyen
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


SELECT (COALESCE(SUM(R2.HEURES_A_LONG),0)  +
        COALESCE(SUM(R4.HEURES_A_MID ),0)  + 
        COALESCE(SUM(R6.HEURES_A_SHORT ),0)+
        COALESCE(SUM(R7.HEURES_A_PREV),0)  +  
        COALESCE(SUM(R8.HEURES_A_NEXT),0)  )
FROM

(SELECT SUM( ( GET_DAYOFYEAR(EndDate) -
       GET_DAYOFYEAR(StartDate) ) * 14.4 * 5/7
   + GET_HOUR(EndDate)    
   - GET_HOUR(StartDate)
      )  AS HEURES_A_LONG
   FROM MYTABLE2
WHERE 
(GET_DAYOFYEAR(EndDate) - GET_DAYOFYEAR(StartDate) )>=10
AND StartDate BETWEEN {startOfYear} AND {endOfYear}
AND EndDate BETWEEN {startOfYear} AND {endOfYear}
) R2,

( SELECT SUM(( GET_DAYOFYEAR(EndDate) -
        GET_DAYOFYEAR(StartDate) ) * 14.4 - 28.8
    + GET_HOUR(EndDate)
    - GET_HOUR(StartDate)
      )    AS HEURES_A_MID
   FROM MYTABLE2
WHERE  
( ( GET_DAYOFYEAR(EndDate)- GET_DAYOFYEAR(StartDate) )
BETWEEN 5 AND 9  )
OR(
GET_DAYOFWEEK(EndDate) - GET_DAYOFWEEK(StartDate) < 0
AND GET_DAYOFYEAR(EndDate)-GET_DAYOFYEAR(StartDate) < 9
  )  
AND StartDate BETWEEN {startOfYear} AND {endOfYear}
AND EndDate BETWEEN {startOfYear} AND {endOfYear}
)R4,

( SELECT SUM( ( GET_DAYOFYEAR(EndDate) -
       GET_DAYOFYEAR(StartDate) ) * 14.4
   + GET_HOUR(EndDate)
   - GET_HOUR(StartDate)
      )   AS HEURES_A_SHORT
   FROM MYTABLE2
WHERE  
(GET_DAYOFYEAR(EndDate) - GET_DAYOFYEAR(StartDate))<= 4
AND
(GET_DAYOFWEEK(EndDate)- GET_DAYOFWEEK(StartDate) ) >= 0
AND StartDate BETWEEN {startOfYear} AND {endOfYear}
AND EndDate BETWEEN {startOfYear} AND {endOfYear}
 )R6,

(SELECT SUM( (GET_DAYOFYEAR(EndDate) - 2 ) * 14.4 *5/7
        + GET_HOUR(EndDate)
        - GET_HOUR(StartDate)
            )    AS HEURES_A_PREV
     FROM MYTABLE2 -- 2!
WHERE StartDate < {startOfYear} 
  AND EndDate > {startOfYear} 
 -- AND EndDate2 > {startofYear}
) R7,

(SELECT SUM( (365 - GET_DAYOFYEAR(StartDate) - 3 ) * 14.4 
        + GET_HOUR(EndDate)
        - GET_HOUR(StartDate)
           )    AS HEURES_A_NEXT
     FROM MYTABLE2 -- 2!
WHERE  StartDate < {endOfYear}
  AND EndDate > {endOfYear} 
 -- AND EndDate2 > {endofYear} 
) R8