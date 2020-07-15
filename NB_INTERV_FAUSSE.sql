-- Nb interventions soldées et incomplètes (pas de durée)
SELECT  R2.I_TOT - R1.I_COUNT
FROM
 (SELECT COUNT(DISTINCT WO.ID) AS I_COUNT FROM CSWO_WO WO
                  INNER JOIN
                 CSWO_OCCUPATION OCCUP ON OCCUP.WO_ID = WO.ID
                 WHERE OCCUP.DURATION != 0
                 AND  WO.STATUS_CODE in ('FINISHED','CLOSED')
                 AND WOEND > {sysdate} - 365
 ) R1,

( SELECT COUNT(*) AS I_TOT FROM CSWO_WO WO
WHERE  WO.STATUS_CODE in ('FINISHED','CLOSED')
                 AND WOEND > {sysdate} - 365 ) R2

