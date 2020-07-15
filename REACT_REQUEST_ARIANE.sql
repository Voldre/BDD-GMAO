-- Temps moyen de prise en charge des DI - Ariane (en jour)
SELECT AVG( 
           GET_DAYOFYEAR(CREATEDATE) -
           GET_DAYOFYEAR(CREATIONDATE)
          ) AS ECART_JOURS
            FROM CSWO_MR MR         
                INNER JOIN CSWO_WO WO
               ON MR.WO_ID = WO.ID

                INNER JOIN CSSY_ACTOR ACTOR
               ON MR.ADDRESSEE_ID = ACTOR.ID
               WHERE ACTOR.CODE in ('VER_MAINT_F_01')
 AND CREATIONDATE BETWEEN {startOfYear} AND {endOfYear}