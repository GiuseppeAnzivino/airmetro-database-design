--------------------------------------------------------------------QUERY--------------------------------------------------------------------

/*
    ***Query 1: Query con Join e Operatore di Aggregazione***
        
        Seleziona i dati riguardanti i pilota e la media dei costi delle offerte che generano
        
*/
SELECT P.Email AS Pilota, P.NumeroLicenzaVolo AS Licenza, P.MatricolaElicottero AS Elicottero, 
P.NomeAreaMetropolitana AS Area_Lavoro, AVG(O.Costo) AS Media_Costi
FROM Offerta O JOIN Eliporto E ON (O.EliportoPartenza = E.Nome)
JOIN Pilota P ON (P.NomeAreaMetropolitana = E.NomeAreaMetropolitana) 
GROUP BY P.Email
ORDER BY P.NomeAreaMetropolitana;

/*
    ***Query 2: Query Nidificata***

        Seleziona il modello, il motore e la potenza dell'elicottero che viene usato dai piloti
        che generano un offerta che parte da Napoli
*/
SELECT DISTINCT E.NomeModello AS MODELLO, E.Motore, E.Potenza
FROM Elicottero E
WHERE E.Matricola IN (
    SELECT P.MatricolaElicottero
    FROM Pilota P
    WHERE P.Email IN (
        SELECT O.EmailPilota
        FROM Offerta O
        WHERE O.EliportoPartenza = 'Napoli'
          AND O.CodiceRichiesta IN (
              SELECT R.Codice
              FROM Richiesta R
              WHERE R.EliportoPartenza = 'Napoli'
          )
    )
);

/*
    ***Query 3: Query insiemistica***
        
        Seleziona i dati riguardanti i piloti identificati come persona fisica,
        eccetto coloro che hanno avuto una valutazione media minore di 3 nelle recensioni
*/
SELECT Per.CodiceFiscale AS CF, Per.nome AS Persona, Per.Tipo AS Giuridica_o_Fisica, ROUND(AVG(R.valutazione), 2) AS Media_Punteggio 
FROM Persona Per JOIN Pilota Pil ON (Pil.CodiceFiscalePersona = Per.CodiceFiscale) 
JOIN Recensione R ON (Pil.Email = R.EmailPilota)
WHERE Per.Tipo = 'F'
GROUP BY CF
EXCEPT
SELECT Per.CodiceFiscale AS CF, Per.nome AS Persona, Per.Tipo AS Giuridica_o_Fisica, ROUND(AVG(R.valutazione), 2) AS Media_Punteggio
FROM Persona Per JOIN Pilota Pil ON (Pil.CodiceFiscalePersona = Per.CodiceFiscale) 
JOIN Recensione R ON (Pil.Email = R.EmailPilota)
GROUP BY CF
HAVING AVG(R.Valutazione) < 3
ORDER BY Persona;

/*
    ***Altra Query: Query Insiemistica***

        Seleziona i dati riguardanti le offerte generate dai piloti
        con un elicottero leggero che costano meno di 5000(euro).   
*/
SELECT O.Codice AS Offerta, O.Costo AS Costo_Offerta, 
P.Email AS Pilota, E.Matricola AS Elicottero, E.NomeModello AS Modello
FROM OFFERTA O JOIN Pilota P ON (O.EmailPilota=P.Email) 
JOIN Elicottero E ON (P.MatricolaElicottero = E.Matricola)
WHERE E.Tipo = 'leggero'
EXCEPT
SELECT O.Codice AS Offerta, O.Costo AS Costo_Offerta, 
P.Email AS Pilota, E.Matricola AS Elicottero, E.NomeModello AS Modello
FROM OFFERTA O JOIN Pilota P ON (O.EmailPilota=P.Email) 
JOIN Elicottero E ON (P.MatricolaElicottero = E.Matricola)
WHERE O.Costo > 5000;

/*
    ***Altra Query: Query Nidificata***

        Seleziona i piloti le cui offerte sono state pagate con Carta Prepagata
*/
SELECT P.Email AS Pilota
FROM Pilota P
WHERE P.Email IN(
    SELECT O.EmailPilota 
    FROM OFFERTA O
    WHERE O.Codice IN(
        SELECT OA.CodiceOfferta 
        FROM OffertaAccettata OA 
        WHERE OA.Metodo='Carta Prepagata'
    ) 
);

---------------------------------------------------------------------------VISTE-----------------------------------------------------

/*
    ***Vista 1***
	    
        Creazione di una vista con i piloti che operano nel meridione e con i guadagni 
	    dalle offerte che sono state accettate 
*/ 
CREATE VIEW GuadagniPiloti AS 
SELECT P.Email, P.NomeAreaMetropolitana, SUM(O.Costo) AS Guadagno 
FROM Pilota P 
JOIN Offerta O ON (O.EmailPilota = P.Email)
JOIN OffertaAccettata OA ON (OA.CodiceOfferta = O.Codice)
WHERE P.NomeAreaMetropolitana IN ('Napoli', 'Palermo', 'Cagliari', 'Bari', 'Messina', 'Reggio Calabria', 'Catania')
GROUP BY P.Email;

/*
    ***Query sulla Vista 1: Query Nidificata***
	    
        Seleziona il pilota che opera nel meridione che ha guadagnato di più
	    dalle offerte accettate
*/
SELECT GP.Email AS Pilota, GP.NomeAreaMetropolitana, GP.Guadagno 
FROM GuadagniPiloti AS GP
WHERE GP.Guadagno IN(
	SELECT MAX(GP.Guadagno) 
    FROM GuadagniPiloti GP
);

/*
    ***Vista 2***
	    
        Creazione di una vista con i piloti che ritardano nei voli
        e con la somma dei ritardi accumulati finora
*/ 
CREATE VIEW PilotiRitardatari AS 
SELECT P.Email, P.MatricolaElicottero, SUM(V.Ritardo) AS Ritardo
FROM Volo V 
JOIN Offerta O ON (V.CodiceOfferta=O.Codice) 
JOIN Pilota P ON (P.Email = O.EmailPilota)
GROUP BY P.Email
HAVING SUM(V.Ritardo) IS NOT NULL AND SUM(V.Ritardo) <> '0 minutes';

/*
    ***Query sulla Vista 1: Query Nidificata***
	    
        Seleziona il pilota che ha fatto più ritardi
*/
SELECT PR.Email AS Pilota, PR.MatricolaElicottero AS Elicottero, PR.Ritardo 
FROM PilotiRitardatari AS PR
WHERE PR.Ritardo IN(
	SELECT MAX(PR.Ritardo) 
    FROM PilotiRitardatari PR
);