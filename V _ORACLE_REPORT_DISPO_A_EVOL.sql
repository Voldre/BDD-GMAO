--SELECT EXTRACT(DAY FROM DATE '1998-03-07') FROM DUAL
--SELECT (TO_CHAR(SYSDATE, 'D'))-1 AS DAYOFWEEK, TO_CHAR(SYSDATE, 'DDD') AS DAYOFYEAR, TO_CHAR(SYSDATE,'HH') AS HOUR, TO_CHAR(SYSDATE,'YYYY'), 
--TO_CHAR(SYSDATE,'DDD')-TO_CHAR(SYSDATE,'DD') from DUAL WHERE SYSDATE > '01-jan-2020' and SYSDATE < '31-dec-2020'

WITH
MYTABLE(StartDate,EndDate,EndDate2, NOM) AS
(SELECT MR.CREATIONDATE AS StartDate, WO.WOEND AS EndDate,
WO2.WOEND AS EndDate2, MAT.ID AS NOM
-- ^ Verifie si year-1 ou +1 d'OT Projet même Year OT Inter
FROM CSWO_WO WO  
left outer join cswo_wolink wok on wok.WOLINK_ID = WO.ID
left outer join cswo_wo wo2 on wo2.id=wok.WOSOURCE_ID
   INNER JOIN CSWO_MR MR
   ON MR.WO_ID = WO2.ID
   INNER JOIN CSWO_WOEQPT WE
   ON WE.WO_ID = WO.ID  
     INNER JOIN CSEQ_EQUIPMENT EQ
     ON EQ.ID = WE.EQPT_ID
    INNER JOIN CSEQ_MATERIAL MAT
    ON MAT.ID = EQ.ID

WHERE MAT.CRITICALITY in ('A') -- bean.id
 
  AND WO.STATUS_CODE = 'CLOSED'
  AND ( MR.EQPTBROKEN = 1 OR WO2.EQPTBROKEN = 1 )
  AND MR.CREATIONDATE < TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
  AND WO.WOEND > TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
  AND MR.CREATIONDATE < WO.WOEND 
)
, 
-- OT Intervention ne se chevauche plus
MYTABLE2(StartDate,EndDate, NOM) AS
(SELECT   s1.StartDate,
      MIN(t1.EndDate) AS EndDate, s1.NOM
FROM MYTABLE s1 
INNER JOIN MYTABLE t1 ON s1.StartDate <= t1.EndDate
     AND NOT EXISTS(SELECT * FROM MYTABLE t2 
        WHERE t1.EndDate >= t2.StartDate AND t1.EndDate < t2.EndDate) 
WHERE NOT EXISTS(SELECT * FROM MYTABLE s2 
    WHERE s1.StartDate > s2.StartDate 
    AND s1.StartDate <= s2.EndDate ) 
GROUP BY s1.StartDate, s1.NOM)
,

TABLE_R0(NOM, NB_DI) AS
(SELECT NOM , COUNT(*) AS NB_DI  
FROM MYTABLE GROUP BY NOM)
,
TABLE_R2(HEURES_A_LONG, NOM) AS
(SELECT SUM( ( TO_CHAR(EndDate, 'DDD') -
               TO_CHAR(StartDate, 'DDD') ) * 14.4 * 5/7
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
           )  AS HEURES_A_LONG    , NOM
FROM MYTABLE2
WHERE 
(TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD') )>=10
AND StartDate BETWEEN TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
AND EndDate BETWEEN TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
 GROUP BY NOM )
,
TABLE_R4(HEURES_A_MID, NOM) AS
(SELECT SUM( ( TO_CHAR(EndDate, 'DDD') -
               TO_CHAR(StartDate, 'DDD') ) * 14.4 - 28.8
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
      )    AS HEURES_A_MID     ,  NOM
   FROM MYTABLE2
WHERE  
( ( TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD') )
BETWEEN 5 AND 9  )
OR(
TO_CHAR(EndDate, 'D') - TO_CHAR(StartDate, 'D') < 0
AND TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD') < 9
  )  
AND StartDate BETWEEN TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
AND EndDate BETWEEN TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
 GROUP BY NOM )
,
TABLE_R6(HEURES_A_SHORT, NOM) AS
(SELECT SUM( ( TO_CHAR(EndDate, 'DDD') -
               TO_CHAR(StartDate, 'DDD') ) * 14.4
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
      )   AS HEURES_A_SHORT   ,  NOM
   FROM MYTABLE2
WHERE  
(TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD') )<= 4
AND
(TO_CHAR(EndDate, 'D') - TO_CHAR(StartDate, 'D') ) >= 0
AND StartDate BETWEEN TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
AND EndDate BETWEEN TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
 GROUP BY NOM )
,  
TABLE_R7(HEURES_A_PREV, NOM) AS
(SELECT SUM( (TO_CHAR(EndDate, 'DDD') - 2 ) * 14.4 *5/7
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
            )    AS HEURES_A_PREV  ,  NOM
     FROM MYTABLE2 -- 2!
WHERE StartDate < TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
  AND EndDate > TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
 GROUP BY NOM )
,
TABLE_R8(HEURES_A_NEXT, NOM) AS
(SELECT SUM( (365 - TO_CHAR(StartDate, 'DDD') - 2) * 14.4 * 5/7
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
           )    AS HEURES_A_NEXT   ,  NOM
     FROM MYTABLE2 -- 2!
WHERE  StartDate < TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
  AND EndDate > TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
 GROUP BY NOM )
 
,
                 ---------------------
         -- Tables B (année/mois précédent)
                 ---------------------
 
MYTABLEB(StartDate,EndDate,EndDate2, NOM) AS
(SELECT MR.CREATIONDATE AS StartDate, WO.WOEND AS EndDate,
WO2.WOEND AS EndDate2, MAT.ID AS NOM
FROM CSWO_WO WO  
left outer join cswo_wolink wok on wok.WOLINK_ID = WO.ID
left outer join cswo_wo wo2 on wo2.id=wok.WOSOURCE_ID
   INNER JOIN CSWO_MR MR
   ON MR.WO_ID = WO2.ID
   INNER JOIN CSWO_WOEQPT WE
   ON WE.WO_ID = WO.ID  
     INNER JOIN CSEQ_EQUIPMENT EQ
     ON EQ.ID = WE.EQPT_ID
    INNER JOIN CSEQ_MATERIAL MAT
    ON MAT.ID = EQ.ID

WHERE MAT.CRITICALITY in ('A') -- bean.id
 
  AND WO.STATUS_CODE = 'CLOSED'
  AND ( MR.EQPTBROKEN = 1 OR WO2.EQPTBROKEN = 1 )
  AND MR.CREATIONDATE < TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
  AND WO.WOEND > TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
  AND MR.CREATIONDATE < WO.WOEND
)
, 
MYTABLE2B(StartDate,EndDate, NOM) AS
(SELECT   s1.StartDate,
      MIN(t1.EndDate) AS EndDate, s1.NOM
FROM MYTABLEB s1 
INNER JOIN MYTABLEB t1 ON s1.StartDate <= t1.EndDate
     AND NOT EXISTS(SELECT * FROM MYTABLEB t2 
        WHERE t1.EndDate >= t2.StartDate AND t1.EndDate < t2.EndDate) 
WHERE NOT EXISTS(SELECT * FROM MYTABLEB s2 
    WHERE s1.StartDate > s2.StartDate 
    AND s1.StartDate <= s2.EndDate ) 
GROUP BY s1.StartDate, s1.NOM)
,

TABLE_R0B(NOM, NB_DI) AS
(SELECT NOM , COUNT(*) AS NB_DI  
FROM MYTABLEB GROUP BY NOM)
,
TABLE_R2B(HEURES_A_LONG, NOM) AS
(SELECT SUM( ( TO_CHAR(EndDate, 'DDD') -
               TO_CHAR(StartDate, 'DDD') ) * 14.4 * 5/7
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
           )  AS HEURES_A_LONG    , NOM
FROM MYTABLE2B
WHERE 
(TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD') )>=10
AND StartDate BETWEEN TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
AND EndDate BETWEEN TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
 GROUP BY NOM )
,
TABLE_R4B(HEURES_A_MID, NOM) AS
(SELECT SUM( ( TO_CHAR(EndDate, 'DDD') -
               TO_CHAR(StartDate, 'DDD') ) * 14.4 - 28.8
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
      )    AS HEURES_A_MID     ,  NOM
   FROM MYTABLE2B
WHERE  
( ( TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD') )
BETWEEN 5 AND 9  )
OR(
TO_CHAR(EndDate, 'D') - TO_CHAR(StartDate, 'D') < 0
AND TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD') < 9
  )  
AND StartDate BETWEEN TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
AND EndDate BETWEEN TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
 GROUP BY NOM )
,
TABLE_R6B(HEURES_A_SHORT, NOM) AS
(SELECT SUM( ( TO_CHAR(EndDate, 'DDD') -
               TO_CHAR(StartDate, 'DDD') ) * 14.4
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
      )   AS HEURES_A_SHORT   ,  NOM
   FROM MYTABLE2B
WHERE  
(TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD') )<= 4
AND
(TO_CHAR(EndDate, 'D') - TO_CHAR(StartDate, 'D') ) >= 0
AND StartDate BETWEEN TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
AND EndDate BETWEEN TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY') AND TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
 GROUP BY NOM )
,  
TABLE_R7B(HEURES_A_PREV, NOM) AS
(SELECT SUM( (TO_CHAR(EndDate, 'DDD') - 2 ) * 14.4 *5/7
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
            )    AS HEURES_A_PREV  ,  NOM
     FROM MYTABLE2B -- 2!
WHERE StartDate < TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
  AND EndDate > TO_DATE(CONCAT('01/01/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
 GROUP BY NOM )
,
TABLE_R8B(HEURES_A_NEXT, NOM) AS
(SELECT SUM( (365 - TO_CHAR(StartDate, 'DDD') - 2) * 14.4 * 5/7
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
           )    AS HEURES_A_NEXT   ,  NOM
     FROM MYTABLE2B -- 2!
WHERE StartDate < TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
  AND EndDate > TO_DATE(CONCAT('31/12/',EXTRACT(YEAR from sysdate)-1),'DD/MM/YYYY')
 GROUP BY NOM )


     --  NOM                         DISPO                                      HEURES                        NB_PANNES
SELECT  RR.NOM "Nom", 
               ROUND(100*(3168 - RR.HEURES)/3168,1) "Taux de dispo", ROUND(RR.HEURES,0) "Heures de pannes", RR.NB_DI "Nombre de pannes", 
     ROUND(RR.HEURES / RR.NB_DI,0) "MTTR" , ROUND((3168 - RR.HEURES) / RR.NB_DI,0) "MTBF" , RR.HEURES - RRB.HEURES "Evolution", RRB.HEURES , RRB.NB_DI
             --         MTTR                                 MTBF				       EVOLUTION		    (A SUPPRIMER)
FROM
 (
 SELECT(COALESCE(SUM(R2.HEURES_A_LONG),0)  +
        COALESCE(SUM(R4.HEURES_A_MID ),0)  + 
        COALESCE(SUM(R6.HEURES_A_SHORT ),0)+
        COALESCE(SUM(R7.HEURES_A_PREV),0)  +  
        COALESCE(SUM(R8.HEURES_A_NEXT),0) )    AS HEURES
       , COALESCE(SUM(R0.NB_DI),0)  AS NB_DI , R0.NOM AS NOM
FROM
     TABLE_R0 R0
         LEFT JOIN TABLE_R2 R2 ON R2.NOM = R0.NOM
         LEFT JOIN TABLE_R4 R4 ON R4.NOM = R0.NOM
         LEFT JOIN TABLE_R6 R6 ON R6.NOM = R0.NOM
         LEFT JOIN TABLE_R7 R7 ON R7.NOM = R0.NOM
         LEFT JOIN TABLE_R8 R8 ON R8.NOM = R0.NOM

	GROUP BY R0.NOM   --, R2.NOM, R4.NOM, R6.NOM, R7.NOM, R8.NOM
 ) RR
,
 (
 SELECT(COALESCE(SUM(R2B.HEURES_A_LONG),0)  +
        COALESCE(SUM(R4B.HEURES_A_MID ),0)  + 
        COALESCE(SUM(R6B.HEURES_A_SHORT ),0)+
        COALESCE(SUM(R7B.HEURES_A_PREV),0)  +  
        COALESCE(SUM(R8B.HEURES_A_NEXT),0) )    AS HEURES
       , COALESCE(SUM(R0B.NB_DI),0)  AS NB_DI , R0B.NOM AS NOM
FROM
     TABLE_R0B R0B
         LEFT JOIN TABLE_R2B R2B ON R2B.NOM = R0B.NOM
         LEFT JOIN TABLE_R4B R4B ON R4B.NOM = R0B.NOM
         LEFT JOIN TABLE_R6B R6B ON R6B.NOM = R0B.NOM
         LEFT JOIN TABLE_R7B R7B ON R7B.NOM = R0B.NOM
         LEFT JOIN TABLE_R8B R8B ON R8B.NOM = R0B.NOM

	GROUP BY R0B.NOM 
 ) RRB
 
 WHERE RR.NOM = RRB.NOM