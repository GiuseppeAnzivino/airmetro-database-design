-------------------------------------------------------------------------TRIGGERS----------------------------------------------------------------------

/*Eliminazione delle funzioni e i triggers corrispondenti se esistenti*/
DROP FUNCTION IF EXISTS checkOffertaBEFORE() cascade;
DROP FUNCTION IF EXISTS AtLeastOnePilot() cascade;
DROP FUNCTION IF EXISTS AreaHaveOneEliport() cascade;
DROP TRIGGER IF EXISTS checkOfferta ON OFFERTA;
DROP TRIGGER IF EXISTS AtLeastOnePilot ON Ricezione;
DROP TRIGGER IF EXISTS AreaHaveOneEliport ON Eliporto;

/*
    ***Creazione Funzione per Trigger su Regole Aziendali (Rv(2), Rv(3) e Rv(4))***
        
        I dati riguardanti la data, l'eliporto di partenza, l'eliporto di destinazione,
        il numero di passeggeri e il cliente che riceve l'offerta devono essere gli stessi 
        della richiesta corrispondente.
*/
CREATE FUNCTION checkOffertaBEFORE() RETURNS trigger AS $$
BEGIN
    IF ( NOT EXISTS (SELECT * FROM Richiesta R
            WHERE R.Codice = new.CodiceRichiesta AND new.EliportoPartenza = R.EliportoPartenza AND new.EliportoArrivo = R.EliportoArrivo AND new.EmailCliente = R.EmailCliente 
            AND new.Data = R.Data AND R.NumeroPasseggeri = new.NumeroPasseggeri)) THEN
        RAISE EXCEPTION 'I dati dell''offerta devono essere gli stessi della richiesta a cui corrisponde';
    END IF;
	RETURN new;
END $$ LANGUAGE PLPGSQL;

/*
    ***Creazione Trigger su Regole Aziendali***

        Triggers che riguardano la funzione checkOffertaBefore()
*/
CREATE TRIGGER checkOfferta
BEFORE INSERT OR UPDATE ON Offerta 
FOR EACH ROW EXECUTE FUNCTION checkOffertaBEFORE();

/*
    ***Creazione Funzione per Trigger su Cardinalità minima della molti a molti***
        Una Richiesta deve essere ricevuta da almeno un pilota
        Richiesta--(1,N)--Ricezione--(0,N)--Pilota
*/
CREATE FUNCTION AtLeastOnePilot() RETURNS trigger AS $$
BEGIN
    IF(EXISTS (SELECT Codice FROM Richiesta WHERE Codice NOT IN 
        (SELECT CodiceRichiesta FROM Ricezione) ))THEN
        RAISE EXCEPTION 'ERRORE, Richiesta non viene ricevuta da nessun Pilota';
    END IF;
    RETURN NULL;
END $$ LANGUAGE PLPGSQL;

/*
    ***Creazione Trigger su cardinalità minima***

        Triggers che riguardano la funzione AtLeastOnePilot()
*/
CREATE TRIGGER AtLeastOnePilot
AFTER DELETE OR UPDATE ON Ricezione
FOR EACH ROW 
EXECUTE FUNCTION AtLeastOnePilot();

CREATE TRIGGER AtLeastOnePilot
AFTER INSERT ON Richiesta
FOR EACH ROW 
EXECUTE FUNCTION AtLeastOnePilot();

/*
    ***Creazione Funzione per Trigger su Cardinalità minima della uno a molti***
        Un' Area Metropolitana deve avere almeno un elicottero per esistere
        AreaMetropolitana--(1,N)--Composizione--(1,1)--Eliporto
*/
CREATE FUNCTION AreaHaveOneEliport() RETURNS trigger AS $$
BEGIN
    IF( EXISTS (SELECT AM.Nome FROM AreaMetropolitana AM
				WHERE AM.Nome NOT IN (SELECT E.NomeAreaMetropolitana FROM Eliporto E)))THEN
        RAISE EXCEPTION 'ERRORE, un Area deve avere almeno un'' eliporto ';
    END IF;
    RETURN NULL;
END $$ LANGUAGE PLPGSQL;

/*
    ***Creazione Triggers su cardinalità minima***

        Triggers che riguardano la funzione AreaHaveOneEliport
*/
CREATE TRIGGER AreaHaveOneEliport
AFTER DELETE OR UPDATE ON Eliporto
FOR EACH ROW EXECUTE FUNCTION AreaHaveOneEliport();

CREATE TRIGGER AreaHaveOneEliport
AFTER INSERT ON AreaMetropolitana
FOR EACH ROW EXECUTE FUNCTION AreaHaveOneEliport();

/*
    ***Creazione Funzione per Trigger su Regole Aziendali***
        Ogni area metropolitana deve avere almeno un pilota con un elicottero
        a capienza massima pari a 6
*/
CREATE OR REPLACE FUNCTION VerifyMaxPosti() RETURNS trigger AS $$
BEGIN
    IF(EXISTS (SELECT AM.Nome FROM AreaMetropolitana AM
        WHERE AM.Nome NOT IN (
            SELECT P.NomeAreaMetropolitana FROM Pilota P 
            WHERE P.MatricolaElicottero IN (
                SELECT E.Matricola FROM Elicottero E 
                WHERE E.NumeroPostiPasseggeri = 6
            )
        )))THEN
        RAISE EXCEPTION 'ERRORE, UN AREAMETROPOLITANA DEVE AVERE UN ELIOTTERO CON MAX POSTI = 6';
    END IF;
    RETURN NULL;
END $$ LANGUAGE PLPGSQL;

/*
    ***Creazione Trigger su Regole Aziendali***

        Triggers che riguardano la funzione verifyMaxPosti()
*/
CREATE TRIGGER VerifyMaxPosti
AFTER DELETE OR UPDATE ON Pilota
FOR EACH ROW EXECUTE FUNCTION VerifyMaxPosti();

CREATE TRIGGER VerifyMaxPosti
AFTER INSERT ON AreaMetropolitana
FOR EACH ROW EXECUTE FUNCTION VerifyMaxPosti();