SELECT R0."Date Début DI" , R0." DI", R0."  Intitulé", R0."N° Machine", R0." Nom Machine", R0."Date Début OT Interv.", 
R0."Date Fin OT Interv", R0."OT Interv", R0."OT Projet", R0."Panne?", R1."Heures d'Occupation", R0." Commentaire"

FROM

(SELECT  MR.ID AS DI,
	TO_CHAR(MR.CREATIONDATE, 'dd/mm/yy hh24:mi:ss') "Date Début DI", 
	MR.CODE " DI", MR.DESCRIPTION "  Intitulé", EQ.CODE "N° Machine", 
	EQ.DESCRIPTION " Nom Machine"	,
	TO_CHAR(WO.WOBEGIN, 'dd/mm/yy hh24:mi:ss') "Date Début OT Interv.", 
        TO_CHAR(WO.WOEND, 'dd/mm/yy hh24:mi:ss')  "Date Fin OT Interv", 
	WO.CODE "OT Interv", WO2.CODE "OT Projet", 
    CASE 
      WHEN MR.EQPTBROKEN=1 THEN ' Oui'
      WHEN MR.EQPTBROKEN=0 THEN ' Non'
    END   "Panne?", 
	
		--  STATUS.REASON "Histo", STATUS.ORIGIN_ID "Histo 2", 

	CAST(DESCR.RAWDESCRIPTION AS VARCHAR2(170)) " Commentaire"

	--TO_CHAR(DESCR.RAWDESCRIPTION) " Commentaire" -- .DESCRIPTION possède l'affichage HTML sans encodage (balises / &amp / ...)

	 -- SYMP.DESCRIPTION " Commentaire" -- Symptôme OT

FROM CSWO_WO WO
left outer join cswo_wolink wok on wok.WOLINK_ID = WO.ID
left outer join cswo_wo wo2 on wo2.id=wok.WOSOURCE_ID
   INNER JOIN CSWO_MR MR
   ON MR.WO_ID = WO2.ID
   
	-- LEFT pour prendre les DI sans commentaire et sans occupation

   FULL JOIN CSSY_DESCRIPTION DESCR
	ON DESCR.ID = WO."COMMENT"

  -- LEFT JOIN CSWO_OCCUPATION OCCUP
  --     ON  OCCUP.WO_ID = WO.ID


 INNER JOIN CSWO_WOEQPT WE
     ON WE.WO_ID = WO.ID
 INNER JOIN CSEQ_MATERIAL MAT
     ON MAT.ID = WE.EQPT_ID
 INNER JOIN CSEQ_EQUIPMENT EQ
     ON EQ.ID = MAT.ID

WHERE MR.CREATIONDATE < TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
  AND WO.WOEND > TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')				    -- SYMP.DESCRIPTION

-- GROUP BY MR.CREATIONDATE, MR.CODE, MR.DESCRIPTION, MAT.ID, WO.WOBEGIN, WO.WOEND, WO.CODE, WO2.CODE , MR.EQPTBROKEN ,  DESCR.RAWDESCRIPTION

ORDER BY MR.ID, MR.CREATIONDATE

)R0

,

(SELECT  MR.ID AS DI,
	COALESCE(SUM(OCCUP.DURATION),0) "Heures d'Occupation"

FROM CSWO_WO WO
left outer join cswo_wolink wok on wok.WOLINK_ID = WO.ID
left outer join cswo_wo wo2 on wo2.id=wok.WOSOURCE_ID
   INNER JOIN CSWO_MR MR
   ON MR.WO_ID = WO2.ID
   
	-- LEFT pour prendre les DI sans commentaire et sans occupation

    FULL JOIN CSSY_DESCRIPTION DESCR
	ON DESCR.ID = WO."COMMENT"

   FULL JOIN CSWO_OCCUPATION OCCUP
       ON  OCCUP.WO_ID = WO.ID


 INNER JOIN CSWO_WOEQPT WE
     ON WE.WO_ID = WO.ID
 INNER JOIN CSEQ_MATERIAL MAT
     ON MAT.ID = WE.EQPT_ID
 INNER JOIN CSEQ_EQUIPMENT EQ
     ON EQ.ID = MAT.ID


WHERE MR.CREATIONDATE < TO_DATE(CONCAT('31/12/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
  AND WO.WOEND > TO_DATE(CONCAT('01/01/',TO_CHAR(SYSDATE,'YYYY')),'DD/MM/YYYY')
--WHERE MR.CREATIONDATE < '31/12/2020'
--  AND WO.WOEND > '01/01/2020'	

GROUP BY MR.ID, MR.CREATIONDATE

ORDER BY MR.ID, MR.CREATIONDATE

)R1

WHERE R0.DI = R1.DI