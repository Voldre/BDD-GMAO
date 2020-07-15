-- Somme des heures de pannes au mois sur un moyen
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
  AND MR.CREATIONDATE < {endOfMonth}
  AND WO.WOEND > {startOfMonth}
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


SELECT (COALESCE(SUM(R2.HEURES_M_LONG),0)  +
        COALESCE(SUM(R4.HEURES_M_MID ),0)  + 
        COALESCE(SUM(R6.HEURES_M_SHORT ),0)+  
        COALESCE(SUM(R7.HEURES_M_PREV),0)  +
        COALESCE(SUM(R8.HEURES_M_NEXT),0)  )
FROM

(SELECT SUM( ( GET_DAYOFYEAR(EndDate) -
       GET_DAYOFYEAR(StartDate) ) * 14.4 * 5/7
   + GET_HOUR(EndDate)    
   - GET_HOUR(StartDate)
      )  AS HEURES_M_LONG
   FROM MYTABLE2
WHERE 
(GET_DAYOFYEAR(EndDate) - GET_DAYOFYEAR(StartDate) )>=10
AND StartDate BETWEEN {startOfMonth} AND {endOfMonth}
AND EndDate BETWEEN {startOfMonth} AND {endOfMonth}
) R2,

( SELECT SUM(( GET_DAYOFYEAR(EndDate) -
        GET_DAYOFYEAR(StartDate) ) * 14.4 - 28.8
    + GET_HOUR(EndDate)
    - GET_HOUR(StartDate)
      )    AS HEURES_M_MID
   FROM MYTABLE2
WHERE  
( ( GET_DAYOFYEAR(EndDate)- GET_DAYOFYEAR(StartDate) )
BETWEEN 5 AND 9  )
OR(
GET_DAYOFWEEK(EndDate) - GET_DAYOFWEEK(StartDate) < 0
AND GET_DAYOFYEAR(EndDate)-GET_DAYOFYEAR(StartDate) < 9
  )  
AND StartDate BETWEEN {startOfMonth} AND {endOfMonth}
AND EndDate BETWEEN {startOfMonth} AND {endOfMonth}
)R4,

( SELECT SUM( ( GET_DAYOFYEAR(EndDate) -
       GET_DAYOFYEAR(StartDate) ) * 14.4
   + GET_HOUR(EndDate)
   - GET_HOUR(StartDate)
      )   AS HEURES_M_SHORT
   FROM MYTABLE2
WHERE  
(GET_DAYOFYEAR(EndDate) - GET_DAYOFYEAR(StartDate))<= 4
AND
(GET_DAYOFWEEK(EndDate)- GET_DAYOFWEEK(StartDate) ) >= 0
AND StartDate BETWEEN {startOfMonth} AND {endOfMonth}
AND EndDate BETWEEN {startOfMonth} AND {endOfMonth}
 )R6,

(SELECT SUM( (GET_DAYOFYEAR(EndDate) - 
               GET_DAYOFYEAR({startOfMonth}) - 1 ) * 14.4 *5/7
        + GET_HOUR(EndDate)
        - GET_HOUR(StartDate)
            )    AS HEURES_M_PREV
     FROM MYTABLE -- 2!
WHERE StartDate < {startOfMonth} 
  AND EndDate > {startOfMonth} 
  AND EndDate2 > {startofMonth}
) R7,

(SELECT SUM( (GET_DAYOFYEAR({endOfMonth}) - 
              GET_DAYOFYEAR(StartDate) - 1 ) * 14.4 
        + GET_HOUR(EndDate)
        - GET_HOUR(StartDate)
           )    AS HEURES_M_NEXT
     FROM MYTABLE -- 2!
WHERE  StartDate < {endOfMonth}
  AND EndDate > {endOfMonth} 
  AND EndDate2 > {endofMonth} 
) R8