CREATE OR REPLACE PROCEDURE CARD_REISSUE IS

CURSOR ClientsCards IS 
SELECT cl.name || ' ' || cl.otch, cl.clientid, cl.email, cr.cardnomer, cr.accountid, cr.cardid FROM Cards cr
JOIN accounts ac
ON cr.accountid = ac.accountid
JOIN clients cl
ON ac.clientid = cl.clientid
WHERE cr.expiremonth = extract (month from sysdate) + 1
AND cr.cardstatus = 1;

vFIO VARCHAR(100);
vEmail VARCHAR(100);
vClientID NUMBER;
vCardNumber VARCHAR2(16);
vAccountID NUMBER;
vCardID NUMBER;

BEGIN
    OPEN ClientsCards;
  LOOP
    FETCH ClientsCards
      INTO vFIO, vClientID, vEmail, vCardNumber, vAccountID, vCardID;
      EXIT WHEN ClientsCards%NOTFOUND;
    BEGIN
      CARD_INSERT(pClientID => vClientID, pIsOldNumber => 1, pOldNumberCard => vCardNumber, pAccountID => vAccountID);
      commit;
     email_send(
      vEmail, 
      'Выпущена новая карта',
      'Уважаемый (ая) ' || vFIO || 
      ', для вас выпущена новая карта. Обратитесь в отделение банка.');
    EXCEPTION 
      WHEN OTHERS THEN 
        DBMS_OUTPUT.put_line('Произошла ошибка ' || SQLERRM); 
    END;    

   END LOOP; 
    CLOSE ClientsCards;
END;


CREATE OR REPLACE PROCEDURE CARD_INSERT
(
pClientID NUMBER,
pCurrencyName VARCHAR2 DEFAULT 810,
pFilialID NUMBER DEFAULT 1,
pNumberOfCard NUMBER DEFAULT 1,
pIsOldNumber NUMBER DEFAULT 0,
pOldNumberCard VARCHAR2 DEFAULT 0,
pAccountID NUMBER DEFAULT 0
) IS

 vCardNumber VARCHAR2(16);
 vAccountID NUMBER;
 vNumberOfCard NUMBER;
BEGIN
  
  SELECT COUNT(*) 
  INTO vNumberOfCard
  FROM Cards c
  JOIN Accounts a
  ON c.accountid = a.accountid
  WHERE a.clientid = pClientID;
  
  IF pNumberOfCard = 1 AND pIsOldNumber = 0 THEN 
  vNumberOfCard := vNumberOfCard + 1;
  vCardNumber := '044525974' || RPAD(vNumberOfCard, 2, '0') || RPAD(pClientID, 5, '0');
  vAccountID := CARD_ACCOUNT_INSERT(pClientID, pCurrencyName, vCardNumber, pFilialID); 
     
     INSERT INTO Cards (
                               cardnomer, 
                               expiremonth, 
                               expireyear, 
                               cardholdername, 
                               cvc, 
                               cardstatus, 
                               accountid 
                          ) 
                          
      VALUES 
      (   
      vCardNumber,
      extract(month from sysdate),
      extract(year from sysdate) + 3,
      'cardholder name',
      TRUNC(DBMS_RANDOM.value(100,1000)),
      1,
      vAccountID
      );
  END IF;
  
  IF pNumberOfCard = 2 AND pIsOldNumber = 0 THEN 
  vNumberOfCard := vNumberOfCard + 1;
  vCardNumber := '044525974' || RPAD(vNumberOfCard, 2, '0') || RPAD(pClientID, 5, '0');
  vAccountID := CARD_ACCOUNT_INSERT(pClientID, pCurrencyName, vCardNumber, pFilialID);
      INSERT INTO Cards (
                               cardnomer, 
                               expiremonth, 
                               expireyear, 
                               cardholdername, 
                               cvc, 
                               cardstatus, 
                               accountid 
                          ) 
                          
      VALUES 
      (   
      vCardNumber,
      extract(month from sysdate),
      extract(year from sysdate) + 3,
      'cardholder name',
      TRUNC(DBMS_RANDOM.value(100,1000)),
      1,
      vAccountID
      );
      
      vNumberOfCard := vNumberOfCard + 1;
      vCardNumber := '044525974' || RPAD(vNumberOfCard, 2, '0') || RPAD(pClientID, 5, '0');
      
      INSERT INTO Cards (
                               cardnomer, 
                               expiremonth, 
                               expireyear, 
                               cardholdername, 
                               cvc, 
                               cardstatus, 
                               accountid 
                          ) 
                          
      VALUES 
      (   
      vCardNumber,
      extract(month from sysdate),
      extract(year from sysdate) + 3,
      'cardholder name',
      TRUNC(DBMS_RANDOM.value(100,1000)),
      1,
      vAccountID
      );
      END IF;
      
      IF pNumberOfCard >= 3 THEN 
      DBMS_OUTPUT.PUT_LINE('Слишком много карт для единовременного создания');
      END IF;
      
      IF pNumberOfCard = 1 AND pIsOldNumber = 1 THEN
        
      UPDATE cards c
      SET c.cardstatus = 2
      WHERE c.cardnomer = pOldNumberCard;
               
      INSERT INTO Cards (
                               cardnomer, 
                               expiremonth, 
                               expireyear, 
                               cardholdername, 
                               cvc, 
                               cardstatus, 
                               accountid 
                          ) 
                          
      VALUES 
      (   
      pOldNumberCard,
      extract(month from sysdate),
      extract(year from sysdate) + 3,
      'cardholder name',
      TRUNC(DBMS_RANDOM.value(100,1000)),
      1,
      pAccountID
      );
    
     END IF;
END;
