/*Eliminazione dei domini se esistono*/
DROP DOMAIN IF EXISTS Valutation_type cascade;
DROP DOMAIN IF EXISTS CF_type cascade;
DROP DOMAIN IF EXISTS Elicopter_type cascade;
DROP DOMAIN IF EXISTS Brand_type cascade;
DROP DOMAIN IF EXISTS Meteo_type cascade;
DROP DoMAIN IF EXISTS Area_type cascade;

/*Eliminazione delle tabelle se esistono*/
DROP TABLE IF EXISTS Persona cascade;
DROP TABLE IF EXISTS Cliente cascade;
DROP TABLE IF EXISTS AreaMetropolitana cascade;
DROP TABLE IF EXISTS Eliporto cascade;
DROP TABLE IF EXISTS Modello cascade;
DROP TABLE IF EXISTS Elicottero cascade;
DROP TABLE IF EXISTS Pilota cascade;
DROP TABLE IF EXISTS Recensione cascade;
DROP TABLE IF EXISTS Richiesta cascade;
DROP TABLE IF EXISTS Ricezione cascade;
DROP TABLE IF EXISTS Offerta cascade;
DROP TABLE IF EXISTS OffertaAccettata cascade;
DROP TABLE IF EXISTS Volo cascade;

/*Creazione di domini utili*/
CREATE DOMAIN Valutation_type AS numeric(1) default 5 CHECK (Value>=0 AND Value<=5);
CREATE DOMAIN CF_type AS character(16) CHECK (CHAR_LENGTH(VALUE)=16 AND VALUE ~ '[A-Z][A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][A-Z][0-9][0-9][A-Z][0-9][0-9][0-9][A-Z]');
CREATE DOMAIN Area_type AS varchar(20) CHECK (VALUE IN ('Roma', 'Napoli', 'Torino', 'Palermo', 'Bari', 'Cagliari', 'Messina', 'Reggio Calabria', 'Bologna', 'Milano', 'Genova', 'Catania', 'Firenze', 'Venezia'));
CREATE DOMAIN Elicopter_type AS varchar(7) CHECK (VALUE IN ('leggero', 'medio', 'pesante'));
CREATE DOMAIN Brand_type AS varchar(20) CHECK (VALUE IN ('Bell Helicopter', 'Leonardo Helicopters', 'Airbus Helicopter'));
CREATE DOMAIN Meteo_type AS varchar(10) CHECK (VALUE IN ('sereno', 'nuvoloso', 'piovoso'));

/*Tabella di Persona*/
CREATE TABLE Persona(
    CodiceFiscale CF_type NOT NULL,
    Nome varchar(20) NOT NULL,
    Cognome varchar(20),
    NumeroTelefono numeric(10, 0) NOT NULL,
    Citta varchar(50) NOT NULL,
    Via varchar(50) NOT NULL,
    NumeroCivico SmallInt NOT NULL,
    DataNascita date NOT NULL,
    Tipo character(1) NOT NULL,
    PartitaIva numeric (11, 0),
    CONSTRAINT persona_pkey PRIMARY KEY (CodiceFiscale),
    CONSTRAINT unique_iva UNIQUE(PartitaIva),
    CONSTRAINT tipo_check CHECK (Tipo='F' AND PartitaIva IS NULL OR Tipo='G' AND Cognome IS NULL));

/*Tabella Cliente*/
CREATE TABLE Cliente(
    Email varchar(50) NOT NULL,
    Password varchar(255) NOT NULL,
    CodiceFiscalePersona CF_type NOT NULL,
    CONSTRAINT cliente_pkey PRIMARY KEY (Email),
    CONSTRAINT cliente_fkey FOREIGN KEY (CodiceFiscalePersona) REFERENCES Persona(CodiceFiscale) ON DELETE restrict ON UPDATE restrict);

/*Tabella Area Metropolitana*/
CREATE TABLE AreaMetropolitana(
    Nome Area_type NOT NULL,
    Sigla char(2) NOT NULL CHECK (CHAR_LENGTH(Sigla)=2),
    Superficie Int NOT NULL,
    CONSTRAINT areaMetropolitana_pkey PRIMARY KEY (Nome),
    CONSTRAINT unique_sigla UNIQUE(Sigla));

/*Tabella Eliporto*/
CREATE TABLE Eliporto(
    Nome varchar(50) NOT NULL,
    Longitudine decimal (9, 6) NOT NULL,
    Latitudine decimal (9, 6) NOT NULL,
    Altitudine decimal (10, 2) NOT NULL,
    NomeAreaMetropolitana Area_type NOT NULL,
    CONSTRAINT eliporto_pkey PRIMARY KEY (Nome),
    CONSTRAINT unique_coordinate UNIQUE(Longitudine, Latitudine, Altitudine),
    CONSTRAINT eliporto_area_fkey FOREIGN KEY (NomeAreaMetropolitana) REFERENCES AreaMetropolitana(Nome) ON UPDATE restrict ON DELETE restrict
    DEFERRABLE INITIALLY DEFERRED);

/*Tabella Modello*/
CREATE TABLE Modello(
    Nome varchar(20) NOT NULL,
    Marca Brand_type NOT NULL,
    CONSTRAINT modello_pkey PRIMARY KEY (Nome));

/*Tabella Elicottero*/
CREATE TABLE Elicottero(
    Matricola character(6) NOT NULL,
    NomeModello varchar(50) NOT NULL,
    Tipo Elicopter_type NOT NULL,
    Motore varchar(50) NOT NULL,
    Colore varchar(50) NOT NULL,
    NumeroPostiPasseggeri numeric(1) NOT NULL,
    AutonomiaVolo decimal(3,2) NOT NULL,
    Potenza varchar(20) NOT NULL,
    CONSTRAINT elicottero_pkey PRIMARY KEY (Matricola),
    CONSTRAINT modello_elicottero_fkey FOREIGN KEY (NomeModello) REFERENCES Modello(Nome),
    CONSTRAINT matricola_check CHECK (Matricola LIKE 'I-____' AND CHAR_LENGTH(Matricola)=6),
    CONSTRAINT numeroposti_check CHECK (NumeroPostiPasseggeri>0 AND NumeroPostiPasseggeri<=6),
    CONSTRAINT potenza_check CHECK (Potenza LIKE '%cavalli' OR Potenza LIKE '%kW'));

/*Tabella Pilota*/
CREATE TABLE Pilota(
    Email varchar(50) NOT NULL,
    Password varchar(255) NOT NULL,
    NumeroLicenzaVolo character(8) NOT NULL CHECK (CHAR_LENGTH(NumeroLicenzaVolo)=8),
    CodiceFiscalePersona CF_type NOT NULL,
    NomeAreaMetropolitana Area_type NOT NULL,
    MatricolaElicottero character(6) NOT NULL CHECK (CHAR_LENGTH(MatricolaElicottero)=6),
    CONSTRAINT pilota_pkey PRIMARY KEY (Email),
    CONSTRAINT pilota_persona_fkey FOREIGN KEY (CodiceFiscalePersona) REFERENCES Persona(CodiceFiscale) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT pilota_area_fkey FOREIGN KEY (NomeAreaMetropolitana) REFERENCES AreaMetropolitana(Nome) ON UPDATE restrict ON DELETE restrict
    DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT pilota_elicottero_fkey FOREIGN KEY (MatricolaElicottero) REFERENCES Elicottero(Matricola) ON UPDATE cascade ON DELETE cascade,
    CONSTRAINT pilota_elicottero_check CHECK (MatricolaElicottero LIKE 'I-____'));

/*Tabella Recensione*/
CREATE TABLE Recensione(
    Codice serial NOT NULL,
    Descrizione varchar(255) NOT NULL,
    Valutazione Valutation_type NOT NULL,
    Data date NOT NULL,
    EmailCliente varchar(50) NOT NULL,
    EmailPilota varchar(50) NOT NULL,
    CONSTRAINT recensione_pkey PRIMARY KEY (Codice),
    CONSTRAINT recensione_cliente_fkey FOREIGN KEY (EmailCliente) REFERENCES Cliente(Email) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT recensione_pilota_fkey FOREIGN KEY (EmailPilota) REFERENCES Pilota(Email) ON UPDATE restrict ON DELETE restrict);

/*Tabella Richiesta*/
CREATE TABLE Richiesta(
    Codice serial NOT NULL,
    Data date NOT NULL,
    Orario time NOT NULL,
    NumeroPasseggeri numeric(1) NOT NULL,
    EliportoPartenza varchar(50) NOT NULL,
    EliportoArrivo varchar(50) NOT NULL,
    EmailCliente varchar(50) NOT NULL,
    CONSTRAINT richiesta_pkey PRIMARY KEY (Codice),
    CONSTRAINT richiesta_partenza_fkey FOREIGN KEY (EliportoPartenza) REFERENCES Eliporto(Nome) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT richiesta_arrivo_fkey FOREIGN KEY (EliportoArrivo) REFERENCES Eliporto(Nome) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT richiesta_cliente_fkey FOREIGN KEY (EmailCliente) REFERENCES Cliente(Email) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT numero_pass_check CHECK (NumeroPasseggeri>0 AND NumeroPasseggeri<=6));

/*Tabella Ricezione*/
CREATE TABLE Ricezione(
    CodiceRichiesta Int NOT NULL,
    EmailPilota varchar(50) NOT NULL,
    CONSTRAINT ricezione_pkey PRIMARY KEY (CodiceRichiesta, EmailPilota),
    CONSTRAINT ricezione_richiesta_fkey FOREIGN KEY (CodiceRichiesta) REFERENCES Richiesta(Codice) ON UPDATE cascade ON DELETE cascade
    DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT ricezione_pilota_fkey FOREIGN KEY (EmailPilota) REFERENCES Pilota(Email) ON UPDATE restrict ON DELETE restrict);

/*Tabella Offerta*/
CREATE TABLE Offerta(
    Codice serial NOT NULL, 
    Data date NOT NULL,
    OrarioPartenza time NOT NULL, 
    NumeroPasseggeri numeric(1) NOT NULL,
    Costo decimal (10, 2) NOT NULL, 
    EliportoPartenza varchar(50) NOT NULL,
    EliportoArrivo varchar(50) NOT NULL,
    EmailCliente varchar(50),
    EmailPIlota varchar(50) NOT NULL,
    CodiceRichiesta Int NOT NULL,
    CONSTRAINT offerta_pkey PRIMARY KEY (Codice),
    CONSTRAINT offerta_partenza_fkey FOREIGN KEY (EliportoPartenza) REFERENCES Eliporto(Nome) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT offerta_arrivo_fkey FOREIGN KEY (EliportoArrivo) REFERENCES Eliporto(Nome) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT offerta_cliente_fkey FOREIGN KEY (EmailCliente) REFERENCES Cliente(Email) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT offerta_pilota_fkey FOREIGN KEY (EmailPilota) REFERENCES Pilota(Email) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT offerta_richiesta_fkey FOREIGN KEY (CodiceRichiesta) REFERENCES Richiesta(Codice) ON UPDATE restrict ON DELETE restrict);

/*Tabella Offerta Accettata*/
CREATE TABLE OffertaAccettata(
    CodiceOfferta Int NOT NULL,
    NumeroTransazione serial NOT NULL,
    DataTransazione Date NOT NULL,
	Importo decimal (10, 2) NOT NULL,
    Metodo varchar(50) NOT NULL,
    CONSTRAINT offertaAccettata_pkey PRIMARY KEY (CodiceOfferta),
    CONSTRAINT offertaAccettata_offerta_fkey FOREIGN KEY (CodiceOfferta) REFERENCES Offerta(Codice) ON UPDATE restrict ON DELETE restrict,
    CONSTRAINT metodo_check CHECK (Metodo IN ('Carta Di Credito', 'Carta Prepagata')));

/*Tabella Volo*/
CREATE TABLE Volo(
    OrarioPartenzaEffettivo time NOT NULL,
    CodiceOfferta Int NOT NULL,
    MeteoPartenza Meteo_type NOT NULL,
    Durata INTERVAL,
    Ritardo INTERVAL,
    MotivazioneRitardo varchar(50),
    Tipo character(1) NOT NULL,
    DataEffettiva date NOT NULL,
    Distanza Int NOT NULL,
    CONSTRAINT volo_pkey PRIMARY KEY (OrarioPartenzaEffettivo, CodiceOfferta),
    CONSTRAINT volo_offerta_fkey FOREIGN KEY (CodiceOfferta) REFERENCES OffertaAccettata(CodiceOfferta),
    CONSTRAINT tipo_check CHECK (Tipo='C'  AND Durata IS NULL AND Ritardo IS NULL AND MotivazioneRitardo IS NULL OR Tipo='P' AND Ritardo='0 minutes' AND MotivazioneRitardo IS NULL OR Tipo='P'));

----------------------------------------------------------POPOLAMENTO------------------------------------------------------------------

/*Popolamento Persone che diventano Clienti*/
INSERT INTO Persona (CodiceFiscale, Nome, Cognome, NumeroTelefono, Citta, Via, NumeroCivico, DataNascita, Tipo, PartitaIva)
VALUES 
    ('RSSMRA85M15H501X', 'PizzaMania', NULL, 3475469309, 'Roma', 'Via Roma', 10, '1990-05-20', 'G', 12345678901),
    ('ZYXWVU01T27S234K', 'Da Giovanni', NULL, 3475469310, 'Nocera', 'Via Antonio Gramsci', 15, '1985-10-15', 'G', 23456789012),
    ('RSSLNG85M01H501Z', 'Marco', 'Rossi', 3475469308, 'Pagani', 'Via Cauciello', 20, '1978-03-12', 'F', NULL),
    ('BNCLRA92R45H502F', 'Paola', 'Bianchi', 3475469311, 'Castellammare', 'Via Vincenzo', 25, '1995-07-08', 'F', NULL),
    ('PLLMRC75D22H503Y', 'Luca e Figli', NULL, 3475469330, 'Firenze', 'Via Vittorio Emanuele', 30, '1980-12-25', 'G', 34567890123),
    ('VRDLGI60C15H504T', 'Hair&Style', NULL, 3475469300, 'Bologna', 'Via Roma', 35, '1998-09-30', 'G', 45678901234),
    ('FRRLNZ88S12H505N', 'Roberto', 'Gallo', 3475469409, 'Palermo', 'Via Palermo', 40, '1975-06-18', 'F', NULL),
    ('MRRMRA90B10H506L', 'Giulia', 'Moretti', 3475469589, 'Genova', 'Via Genova', 45, '1989-04-05', 'F', NULL),
    ('SMMGNN95E05H507R', 'AndreaTatoo', NULL, 3455566345, 'Catania', 'Via Catania', 50, '1993-11-15', 'G', 56789012345),
    ('MRGRRT80H01H508Q', 'Laura', 'Ricci', 3435764354, 'Venezia', 'Via Venice', 55, '1987-08-20', 'F', NULL),
    ('GNTLRT82C15H509X', 'Ale e figli', NULL, 3473262365, 'Torino', 'Via Turin', 60, '1997-02-10', 'G', 67890123456),
    ('BRBMRI73D09H510B', 'Sara', 'Ferrari', 3475468330, 'Firenze', 'Via Florence', 65, '1992-12-05', 'F', NULL),
    ('CRDLSE91M12H511J', 'PcExpert', NULL, 3345390274, 'Verona', 'Via Verona', 70, '1986-05-30', 'G', 78901234567),
    ('DNLMLL84T08H512P', 'BobAggiustatutto', NULL, 3475445650, 'Napoli', 'Via Napoli', 75, '1990-09-25', 'G', 89012345678),
    ('LNDGPP79R15H513D', 'Marco', 'Ferrari', 3475349306, 'Milano', 'Via Milano', 101, '1992-12-26', 'F', NULL);

/*Popolamento Persone che diventano Piloti*/
INSERT INTO Persona (CodiceFiscale, Nome, Cognome, NumeroTelefono, Citta, Via, NumeroCivico, DataNascita, Tipo, PartitaIva)
VALUES 
    ('VRDMRA90S23H514Z', 'Francesca', 'Verdi', 3475469321, 'Roma', 'Via Appia', 10, '1985-06-15', 'F', NULL),
    ('BNCTZN82A15H515F', 'Aquila', NULL, 3475469322, 'Milano', 'Via Montenapoleone', 20, '1990-04-25', 'G', 90123456789),
    ('RSSGLC88R05H516X', 'Martina', 'Bianchi', 3475469323, 'Torino', 'Via Garibaldi', 30, '1993-03-10', 'F', NULL),
    ('MRRLSA92M18H517L', 'Re del Cielo', NULL, 3475469324, 'Firenze', 'Via dei Tornabuoni', 40, '1988-12-12', 'G', 01234567890),
    ('PLLMNG85T10H518Y', 'Alessia', 'Ricci', 3475469325, 'Napoli', 'Via Toledo', 50, '1992-07-01', 'F', NULL),
    ('VRCMRL85T01H222Z', 'Raffaele', 'De Bellis', 3334445555, 'Salerno', 'Via Giulio Cesare', 10, '1990-03-23', 'F', NULL),
    ('BNCGRR92A23H501F', 'Giulia', 'Galli', 3475469326, 'Bologna', 'Via Rizzoli', 60, '1995-01-15', 'F', NULL),
    ('PLLMND79D17H501Y', 'HumanFly', NULL, 3475469327, 'Verona', 'Corso Porta Borsari', 70, '1987-04-12', 'G', 55566677788),
    ('RSSMRT88S05H501X', 'Chiara', 'Moretti', 3475469328, 'Genova', 'Via XX Settembre', 80, '1991-11-25', 'F', NULL),
    ('MRGRCL83M22H501L', 'AirLuca', NULL, 3475469329, 'Palermo', 'Via Libertà', 10, '1984-09-18', 'G', 99911122233);

/*Popolamento dei Clienti*/
INSERT INTO Cliente (Email, Password, CodiceFiscalePersona) 
VALUES
    ('cliente1@example.com', 'password123', 'RSSMRA85M15H501X'),
    ('cliente2@example.com', 'securepass', 'ZYXWVU01T27S234K'),
    ('cliente3@example.com', 'mypassword', 'RSSLNG85M01H501Z'),
    ('cliente4@example.com', 'secretword', 'BNCLRA92R45H502F'),
    ('cliente5@example.com', 'pass123', 'PLLMRC75D22H503Y'),
    ('cliente6@example.com', 'letmein', 'VRDLGI60C15H504T'),
    ('cliente7@example.com', '123456', 'FRRLNZ88S12H505N'),
    ('cliente8@example.com', 'iloveyou', 'MRRMRA90B10H506L'),
    ('cliente9@example.com', 'qwerty', 'SMMGNN95E05H507R'),
    ('cliente10@example.com', '654321', 'MRGRRT80H01H508Q'),
    ('cliente11@example.com', 'password12345', 'GNTLRT82C15H509X'),
    ('cliente12@example.com', 'abcdef', 'BRBMRI73D09H510B'),
    ('cliente13@example.com', '12345678', 'CRDLSE91M12H511J'),
    ('cliente14@example.com', 'changeme', 'DNLMLL84T08H512P'),
    ('cliente15@example.com', 'football', 'LNDGPP79R15H513D');

/*Popolamento dei Modelli di Elicotteri*/
INSERT INTO Modello (Nome, Marca) 
VALUES
    ('Bell 206', 'Bell Helicopter'),
    ('Bell 206B', 'Bell Helicopter'),
    ('Bell 407', 'Bell Helicopter'),
    ('AS350 Ecureiuil', 'Airbus Helicopter'),
    ('EC130', 'Airbus Helicopter'),
    ('AW109', 'Leonardo Helicopters');

/*Popolamento degli Elicotteri*/
INSERT INTO Elicottero (Matricola, NomeModello, Tipo, Motore, Colore, NumeroPostiPasseggeri, AutonomiaVolo, Potenza) 
VALUES
    ('I-ABCD', 'Bell 206', 'medio', 'Pratt & Whitney Canada PT6', 'verde', 6, 7, '700 cavalli'),
    /*
        ***Controllo funzionamento del Trigger sulla Regola Aziendale RV(6)***
            Area Metropolitana senza pilota con elicottero a capienza pari a 6
            ('I-ABCD', 'Bell 206', 'medio', 'Pratt & Whitney Canada PT6', 'verde', 5, 7, '700 cavalli'),
            Naturalmente commentare l'ononimo.
    */
    ('I-BCDE', 'EC130', 'leggero', 'GE Aviation T700', 'blu', 6, 5, '500 cavalli'),
    ('I-CDEF', 'Bell 407', 'leggero', 'Rotax 914', 'bianco', 6, 6, '540 kW'),
    ('I-DEFG', 'AS350 Ecureiuil', 'pesante', 'Rolls-Royce RTM322', 'nero', 6, 8, '600 cavalli'),
    ('I-EFGH', 'EC130', 'medio', 'Pratt & Whitney Canada PT6', 'giallo', 6, 6, '1500 kW'),
    ('I-FGHI', 'Bell 206B', 'leggero', 'GE Aviation T700', 'rosso', 4, 5, '600 kW'),
    ('I-GHIJ', 'Bell 407', 'leggero', 'Rotax 914', 'grigio', 5, 7, '800 cavalli'),
    ('I-HIJK', 'AW109', 'medio', 'Rolls-Royce RTM322', 'azzurro', 5, 9, '1200 kW'), 
    ('I-IJKL', 'Bell 206', 'medio', 'Pratt & Whitney Canada PT6', 'rosa', 4, 8, '600 cavalli'),
    ('I-JKLM', 'AW109', 'pesante', 'Rolls-Royce RTM322', 'viola', 5, 7, '540 kW');

/*Popolamento dei Piloti*/
INSERT INTO Pilota (Email, Password, NumeroLicenzaVolo, CodiceFiscalePersona, NomeAreaMetropolitana, MatricolaElicottero) 
VALUES
    ('pilota1@example.com', 'password1', 'CAA12345', 'VRDMRA90S23H514Z', 'Milano', 'I-ABCD'),
    ('pilota2@example.com', 'password2', 'CAA23456', 'BNCTZN82A15H515F', 'Roma', 'I-BCDE'),
    ('pilota3@example.com', 'password3', 'CAA34567', 'RSSGLC88R05H516X', 'Napoli', 'I-CDEF'),
    ('pilota4@example.com', 'password4', 'CAA45678', 'MRRLSA92M18H517L', 'Torino', 'I-DEFG'),
    ('pilota5@example.com', 'password5', 'CAA56789', 'PLLMNG85T10H518Y', 'Palermo', 'I-EFGH'),
    ('pilota6@example.com', 'password6', 'CAA66666', 'VRCMRL85T01H222Z', 'Milano', 'I-FGHI'),
    ('pilota7@example.com', 'password7', 'CAA77777', 'BNCGRR92A23H501F', 'Roma', 'I-GHIJ'),
    ('pilota8@example.com', 'password8', 'CAA88888', 'PLLMND79D17H501Y', 'Napoli', 'I-HIJK'),
    ('pilota9@example.com', 'password9', 'CAA99999', 'RSSMRT88S05H501X', 'Torino', 'I-IJKL'),
    ('pilota10@example.com', 'password10', 'CAA00000', 'MRGRCL83M22H501L', 'Palermo', 'I-JKLM');
/*
    ***Controllo funzionamento del Trigger sulla Regola Aziendale RV(6)***
        Eliminazione di un pilota con elicottero a capienza pari a 6 da un area metropolitana
        DELETE FROM PILOTA WHERE MatricolaElicottero = 'I-ABCD';
*/

/*Popolamento degli Eliporti*/
INSERT INTO Eliporto (Nome, Longitudine, Latitudine, Altitudine, NomeAreaMetropolitana) 
VALUES
    ('Milano', 45.4507, 9.2777, 102.00, 'Milano'),
    ('Roma', 41.7994, 12.5917, 130.00, 'Roma'),
    ('Napoli', 40.8840, 14.2908, 122.00, 'Napoli'),
    ('Torino', 45.1986, 7.6516, 275.00, 'Torino'),
    ('Palermo', 38.1817, 13.1050, 24.00, 'Palermo'),
    ('Latina', 45.8275, 13.4817, 4.00, 'Roma'),
    ('Bergamo', 39.2535, 9.0556, 4.00, 'Milano'),
    ('Capri', 43.6839, 10.3956, 2.00, 'Napoli');
/*
    ***Controllo funzionamento del Trigger sulla Cardinalità minima della Uno a Molti***
        Eliminazione degli eliporti associati a Palermo
        DELETE FROM ELIPORTO WHERE NOMEAREAMETROPOLITANA = 'Palermo';
*/

/*Popolamento delle Aree Metropolitane*/
INSERT INTO AreaMetropolitana (Nome, Sigla, Superficie) 
VALUES
    ('Roma', 'RM', 5363),
    ('Napoli', 'NA', 1171),
    ('Torino', 'TO', 6827),
    ('Palermo', 'PA', 5009),
/*
    ***Controllo funzionamento del Trigger sulla Cardinalità minima della Uno a Molti***
        Inserimento di un area senza eliporti.
        ('Genova', 'GN', 1839),
*/
    ('Milano', 'MI', 1575);

/*Popolamento delle Recensioni*/
INSERT INTO Recensione (Descrizione, Valutazione, Data, EmailCliente, EmailPilota)
VALUES
    ('Molto professionale', 5, '2024-05-15', 'cliente1@example.com', 'pilota1@example.com'),
    ('Servizio eccellente', 5, '2024-05-14', 'cliente2@example.com', 'pilota2@example.com'),
    ('Molto cortese', 4, '2024-05-13', 'cliente3@example.com', 'pilota3@example.com'),
    ('Puntuale e affidabile', 5, '2024-05-12', 'cliente4@example.com', 'pilota4@example.com'),
    ('Ottima esperienza', 5, '2024-05-11', 'cliente5@example.com', 'pilota5@example.com'),
    ('Consigliato', 5, '2024-05-10', 'cliente6@example.com', 'pilota6@example.com'),
    ('Efficiente', 4, '2024-05-09', 'cliente7@example.com', 'pilota7@example.com'),
    ('Molto competente', 5, '2024-05-08', 'cliente8@example.com', 'pilota8@example.com'),
    ('Discreto', 3, '2024-05-07', 'cliente9@example.com', 'pilota9@example.com'),
    ('Buon servizio', 4, '2024-05-06', 'cliente10@example.com', 'pilota10@example.com'),
    ('Da migliorare', 2, '2024-05-05', 'cliente11@example.com', 'pilota1@example.com'),
    ('Non soddisfacente', 1, '2024-05-04', 'cliente12@example.com', 'pilota2@example.com'),
    ('Pessima esperienza', 1, '2024-05-03', 'cliente13@example.com', 'pilota3@example.com'),
    ('Servizio scadente', 2, '2024-05-02', 'cliente14@example.com', 'pilota4@example.com'),
    ('Da evitare', 1, '2024-05-01', 'cliente15@example.com', 'pilota5@example.com');

/*Popolamento delle Ricezioni*/
INSERT INTO Ricezione (CodiceRichiesta, EmailPilota)
VALUES
    (1, 'pilota1@example.com'),
    (1, 'pilota6@example.com'),
    (2, 'pilota3@example.com'),
    (2, 'pilota8@example.com'),
    (3, 'pilota5@example.com'),
    (3, 'pilota10@example.com'),
    (4, 'pilota4@example.com'),
    (4, 'pilota9@example.com'),
    (5, 'pilota2@example.com'),
    (5, 'pilota7@example.com'),
    (6, 'pilota5@example.com'),
    (6, 'pilota10@example.com'),
    (7, 'pilota1@example.com'),
    (7, 'pilota6@example.com'),
    (8, 'pilota3@example.com'),
    (8, 'pilota8@example.com'),
    (9, 'pilota2@example.com'),
    (9, 'pilota7@example.com'),
    (10, 'pilota4@example.com'),
    (10, 'pilota9@example.com');
/*
    ***Controllo funzionamento del trigger sulla cardinalità minima della molti a molti***
        
        DELETE FROM Ricezione WHERE CodiceRichiesta = 10;
*/

/*Popolamento delle Richieste*/
INSERT INTO Richiesta (Data, Orario, NumeroPasseggeri, EliportoPartenza, EliportoArrivo, EmailCliente)
VALUES 
    ('2024-05-16', '12:00', 4, 'Milano', 'Roma', 'cliente1@example.com'),
    ('2024-05-17', '10:30', 2, 'Napoli', 'Torino', 'cliente2@example.com'),
    ('2024-05-18', '15:45', 3, 'Palermo', 'Torino', 'cliente3@example.com'),
    ('2024-05-19', '14:15', 5, 'Torino', 'Capri', 'cliente4@example.com'),
    ('2024-05-20', '11:00', 2, 'Roma', 'Palermo', 'cliente5@example.com'),
    ('2024-05-21', '16:30', 3, 'Palermo', 'Latina', 'cliente6@example.com'),
    ('2024-05-22', '09:45', 4, 'Milano', 'Bergamo', 'cliente7@example.com'),
    ('2024-05-23', '13:20', 5, 'Napoli', 'Capri', 'cliente8@example.com'),
    ('2024-05-24', '17:00', 2, 'Roma', 'Napoli', 'cliente9@example.com'),
    /*
        ***Controllo funzionamento del trigger sulla cardinalità minima della molti a molti***
            
            ('2024-05-25', '10:15', 3, 'Torino', 'Milano', 'cliente10@example.com'),
    */
    ('2024-05-25', '10:15', 3, 'Torino', 'Milano', 'cliente10@example.com');

/*Popolamento delle Offerte*/
INSERT INTO Offerta (Data, OrarioPartenza, NumeroPasseggeri, EliportoPartenza, EliportoArrivo, Costo, EmailCliente, CodiceRichiesta, EmailPilota)
VALUES 
    ('2024-05-16', '12:15', 4, 'Milano', 'Roma', 6000, 'cliente1@example.com', 1, 'pilota1@example.com'),
    ('2024-05-16', '12:00', 4, 'Milano', 'Roma', 6400, 'cliente1@example.com', 1, 'pilota6@example.com'),
    ('2024-05-17', '11:30', 2, 'Napoli', 'Torino', 3000, 'cliente2@example.com', 2, 'pilota3@example.com'),
    ('2024-05-17', '11:00', 2, 'Napoli', 'Torino', 4000, 'cliente2@example.com', 2, 'pilota8@example.com'),
    ('2024-05-18', '16:15', 3, 'Palermo', 'Torino', 5000, 'cliente3@example.com', 3, 'pilota5@example.com'),
    ('2024-05-18', '16:00', 3, 'Palermo', 'Torino', 4800, 'cliente3@example.com', 3, 'pilota10@example.com'),    
    ('2024-05-19', '14:15', 5, 'Torino', 'Capri', 5000, 'cliente4@example.com', 4, 'pilota4@example.com'),
    ('2024-05-19', '14:20', 5, 'Torino', 'Capri', 5500, 'cliente4@example.com', 4, 'pilota9@example.com'),    
    ('2024-05-20', '11:15', 2, 'Roma', 'Palermo', 3200, 'cliente5@example.com', 5, 'pilota2@example.com'),
    ('2024-05-20', '11:00', 2, 'Roma', 'Palermo', 3100, 'cliente5@example.com', 5, 'pilota7@example.com'),      
    ('2024-05-21', '16:45', 3, 'Palermo', 'Latina', 4300, 'cliente6@example.com', 6, 'pilota5@example.com'),
    ('2024-05-21', '17:00', 3, 'Palermo', 'Latina', 4200, 'cliente6@example.com', 6, 'pilota10@example.com'),       
    ('2024-05-22', '09:50', 4, 'Milano', 'Bergamo', 7000, 'cliente7@example.com', 7, 'pilota1@example.com'),
    ('2024-05-22', '09:55', 4, 'Milano', 'Bergamo', 7400, 'cliente7@example.com', 7, 'pilota6@example.com'),  
    ('2024-05-23', '13:25', 5, 'Napoli', 'Capri', 3200, 'cliente8@example.com', 8, 'pilota3@example.com'),
    ('2024-05-23', '13:20', 5, 'Napoli', 'Capri', 3000, 'cliente8@example.com', 8, 'pilota8@example.com'), 
    ('2024-05-24', '17:15', 2, 'Roma', 'Napoli', 3300, 'cliente9@example.com', 9, 'pilota2@example.com'),
    ('2024-05-24', '17:00', 2, 'Roma', 'Napoli', 3400, 'cliente9@example.com', 9, 'pilota7@example.com'), 
    ('2024-05-25', '10:15', 3, 'Torino', 'Milano', 4200, 'cliente10@example.com', 10, 'pilota4@example.com'),
    ('2024-05-25', '10:20', 3, 'Torino', 'Milano', 4250, 'cliente10@example.com', 10, 'pilota9@example.com');

/*Popolamento Offerta Accettata*/
INSERT INTO OffertaAccettata (CodiceOfferta, DataTransazione, Importo, Metodo)
VALUES
    (1, '2024-05-16', 6000, 'Carta Prepagata'),
    (4, '2024-05-17', 4000, 'Carta Prepagata'),
    (6, '2024-05-18', 4800, 'Carta Di Credito'),
    (7, '2024-05-19', 5000, 'Carta Di Credito'),
    (10, '2024-05-20', 3100, 'Carta Prepagata'),
    (11, '2024-05-21', 4300, 'Carta Prepagata'),
    (13, '2024-05-22', 7000, 'Carta Di Credito'),
    (16, '2024-05-23', 3000, 'Carta Prepagata'),
    (17, '2024-05-24', 3300, 'Carta Di Credito'),
    (19, '2024-05-25', 4200, 'Carta Di Credito');

/*Popolamento Volo*/
INSERT INTO Volo (OrarioPartenzaEffettivo, CodiceOfferta, MeteoPartenza, Durata, Ritardo, MotivazioneRitardo, Tipo, DataEffettiva, Distanza)
VALUES
    ('12:40', 1, 'sereno', NULL, NULL, NULL, 'C', '2024-05-16', 480),
    ('11:10', 4, 'nuvoloso', '45 minutes', '10 minutes', 'Ritardo dovuto al traffico aereo', 'P', '2024-05-17', 712),
    ('16:01', 6, 'piovoso', NULL, NULL, NULL, 'C', '2024-05-18', 905),
    ('14:15', 7, 'sereno','60 minutes', '0 minutes', NULL, 'P', '2024-05-19', 733),
    ('11:15', 10, 'nuvoloso', '55 minutes', '15 minutes', 'Guasto tecnico al mezzo', 'P', '2024-05-20', 423),
    ('17:00', 11, 'sereno', '40 minutes', '15 minutes', 'Ritardo dovuto al controllo del mezzo', 'P', '2024-05-21', 372),
    ('10:04', 13, 'piovoso', '57 minutes', '14 minutes', 'Ritardo dovuto al cliente', 'P', '2024-05-22', 50),
    ('14:00', 16, 'nuvoloso', '61 minutes', '30 minutes', 'Ritardo dovuto al pilota', 'P', '2024-05-23', 34),
    ('17:24', 17, 'sereno', '43 minutes', '9 minutes', 'Ritardo dovuto al traffico aereo', 'P', '2024-05-24', 186),
    ('10:30', 19, 'nuvoloso', NULL, NULL, NULL, 'C', '2024-05-25', 125);
