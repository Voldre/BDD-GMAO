
WITH
MYTABLE(StartDate,EndDate,EndDate2, NOM) AS
(SELECT MR.CREATIONDATE AS StartDate, 
    CASE 
      WHEN WO.WOEND IS NULL THEN TO_DATE( (SYSDATE - TO_CHAR(SYSDATE,'D') + 5) )
      ELSE WO.WOEND
    END   AS EndDate,
    CASE 
      WHEN WO2.WOEND IS NULL THEN TO_DATE( (SYSDATE - TO_CHAR(SYSDATE,'D') + 5) )
      ELSE WO2.WOEND
    END   AS EndDate2, 

	MAT.ID AS NOM

FROM CSWO_WO WO  
left join cswo_wolink wok on wok.WOLINK_ID = WO.ID
left join cswo_wo wo2 on wo2.id=wok.WOSOURCE_ID
   INNER JOIN CSWO_MR MR
   ON MR.WO_ID = WO2.ID
   INNER JOIN CSWO_WOEQPT WE
   ON WE.WO_ID = WO.ID  
     INNER JOIN CSEQ_EQUIPMENT EQ
     ON EQ.ID = WE.EQPT_ID
    INNER JOIN CSEQ_MATERIAL MAT
    ON MAT.ID = EQ.ID

-- WHERE MAT.CRITICALITY in ('A')  -- Pour l'instant pas besoin
 
  -- AND WO.STATUS_CODE = 'CLOSED' Peut ne pas être soldé! C'et le principe du WO.WOEND IS NULL

  AND ( MR.EQPTBROKEN = 1 OR WO2.EQPTBROKEN = 1 )
  AND MR.CREATIONDATE <= TO_DATE( (SYSDATE - TO_CHAR(SYSDATE,'D') + 5) ) -- Au plus tard Vendredi
  AND ( WO.WOEND >= TO_DATE( (SYSDATE - TO_CHAR(SYSDATE,'D') + 1) ) -- Au plus tôt Lundi
	OR WO.WOEND is null    )
 -- AND MR.CREATIONDATE < WO.WOEND 
)
, 

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

-- TABLE_R2 (Inutile car on ne dépasse pas les 5 jours) (0 week-end possible)

-- TABLE_R4 (Inutile car on ne dépasse pas les 5 jours) (0 week-end possible)

TABLE_R6(HEURES_A_SHORT, NOM) AS
(SELECT SUM( ( TO_CHAR(EndDate, 'DDD') -
               TO_CHAR(StartDate, 'DDD') ) * 14.4
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
      )   AS HEURES_A_SHORT   ,  NOM
   FROM MYTABLE2
WHERE  

-- Aucune condition parce qu'il n'y a aucune DI de plus de 4 jours

(  TO_CHAR(EndDate, 'DDD') - TO_CHAR(StartDate, 'DDD')  )<= 4 -- Condition sous-entendue avec les 2 en dessous

AND StartDate BETWEEN TO_DATE(  (SYSDATE - TO_CHAR(SYSDATE,'D') + 1)  ) AND TO_DATE(  (SYSDATE - TO_CHAR(SYSDATE,'D') + 5)  )
AND EndDate BETWEEN TO_DATE(  (SYSDATE - TO_CHAR(SYSDATE,'D') + 1)  ) AND TO_DATE(  (SYSDATE - TO_CHAR(SYSDATE,'D') + 5)  )
 GROUP BY NOM )
,  

TABLE_R7(HEURES_A_PREV, NOM) AS	   -- 	" Fin - Lundi  "
(SELECT SUM( (  TO_CHAR(EndDate, 'DDD') - TO_CHAR( (SYSDATE-TO_CHAR(SYSDATE,'D')+1),'DDD')  ) * 14.4 --* 5/7 Aucun week-end pour cette requête
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
            )    AS HEURES_A_PREV  ,  NOM
     FROM MYTABLE2 -- 2!
WHERE StartDate <  TO_DATE(  (SYSDATE - TO_CHAR(SYSDATE,'D') + 1)  ) -- <= ?
  AND EndDate >=  TO_DATE(  (SYSDATE - TO_CHAR(SYSDATE,'D') + 1)  )
 GROUP BY NOM )
,
TABLE_R8(HEURES_A_NEXT, NOM) AS	   --  " Vendredi -  Début  "
(SELECT SUM( ( TO_CHAR((SYSDATE-TO_CHAR(SYSDATE,'D')+5),'DDD') - TO_CHAR(StartDate, 'DDD') ) * 14.4 --* 5/7 Aucun week-end pour cette requête
   + TO_CHAR(EndDate,'HH')
   - TO_CHAR(StartDate,'HH')
           )    AS HEURES_A_NEXT   ,  NOM
     FROM MYTABLE2 -- 2!
WHERE  StartDate <= TO_DATE(  (SYSDATE - TO_CHAR(SYSDATE,'D') + 5)  )
  AND EndDate >  TO_DATE(  (SYSDATE - TO_CHAR(SYSDATE,'D') + 5)  ) -- >= ?
 GROUP BY NOM )


     --  NOM                         DISPO                                      HEURES                        NB_PANNES
SELECT  RR.NOM "Nom", 
               ROUND(100*(3168 - RR.HEURES)/3168,1) "Taux de dispo", ROUND(RR.HEURES,0) "Heures de pannes", RR.NB_DI "Nombre de pannes", 
     ROUND(RR.HEURES / RR.NB_DI,0) "MTTR" , ROUND((3168 - RR.HEURES) / RR.NB_DI,0) "MTBF"
             --         MTTR                                 MTBF
FROM
 (
 SELECT( -- COALESCE(SUM(R2.HEURES_A_LONG),0)  +
         -- COALESCE(SUM(R4.HEURES_A_MID ),0)  + 
        COALESCE(SUM(R6.HEURES_A_SHORT ),0)+
        COALESCE(SUM(R7.HEURES_A_PREV),0)  +  
        COALESCE(SUM(R8.HEURES_A_NEXT),0) )    AS HEURES
       , COALESCE(SUM(R0.NB_DI),0)  AS NB_DI , R0.NOM AS NOM
FROM
     TABLE_R0 R0
         -- LEFT JOIN TABLE_R2 R2 ON R2.NOM = R0.NOM
         -- LEFT JOIN TABLE_R4 R4 ON R4.NOM = R0.NOM
         LEFT JOIN TABLE_R6 R6 ON R6.NOM = R0.NOM
         LEFT JOIN TABLE_R7 R7 ON R7.NOM = R0.NOM
         LEFT JOIN TABLE_R8 R8 ON R8.NOM = R0.NOM

	GROUP BY R0.NOM   --, R2.NOM, R4.NOM, R6.NOM, R7.NOM, R8.NOM
 ) RR