-- Ratio pr�ventif sur le mois en cours (en %)
SELECT CASE WHEN S2.HEURES_TOTAL = 0 THEN 0
  ELSE GET_ROUND((S1.HEURES_PREV)*100 / S2.HEURES_TOTAL, 2)
       END
FROM 
    (SELECT SUM(OCCUP.DURATION) AS HEURES_PREV
      FROM CSWO_WO WO INNER JOIN
             CSWO_ACTIONTYPE ACT ON ACT.ID = WO.ACTIONTYPE_ID
                      INNER JOIN
             CSWO_OCCUPATION OCCUP ON OCCUP.WO_ID = WO.ID
      WHERE WOEND BETWEEN {startOfMonth} AND {sysdate}
      AND ACT.CODE not in ('COR_PLANIF','COR_PROD','CORREC','HORS_MAINTENANCE','INS_LEVANO','MISE_EN_SERVICE','MODI','RECONST','REG_LEVREM','SSE','TRNE','VIDANGE_APPOINTS') ) S1,

    (SELECT SUM(OCCUP.DURATION) AS HEURES_TOTAL
      FROM CSWO_WO WO INNER JOIN
               CSWO_OCCUPATION OCCUP ON OCCUP.WO_ID = WO.ID
      WHERE WOEND BETWEEN {startOfMonth} AND {sysdate} ) S2