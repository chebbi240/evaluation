--A réaliser à partir de base de données complète de gescom, gescom_afpa.
--Vues
/*Créez une vue qui affiche le catalogue produits. L'id,la référence et le nom
 des produits,ainsi que l'id et le nom de la catégorie doivent apparaître. */
CREATE VIEW v_pro_cat
AS
SELECT pro_id,pro_ref,pro_name,cat_id,cat_name FROM products
JOIN categories
ON products.pro_cat_id=categories.cat_id;
--Procédures stockées
/*Créez la procédure stockée facture qui permet d'afficher les informations nécessaires à une facture en fonction d'un numéro de commande.
 Cette procédure doit sortir le montant total de la commande.*/
 DELIMITER ;;

CREATE PROCEDURE facture()
BEGIN
SELECT ord_id,ord_order_date,ord_payment_date,sum((ode_unit_price-(ode_unit_price*ode_discount/100))*ode_quantity) as total_commande,cus_id,CONCAT(cus_lastname,'  ',cus_firstname) 
FROM orders_details
JOIN orders
ON ode_ord_id=ord_id
JOIN customers
ON ord_cus_id=cus_id
group by ord_id;
END ;;
DELIMITER ;
--Triggers:
/* Créer un déclencheur after_products_update sur la table products : 
la condition :lorsque le stock physique devient inférieur au stock d'alerte dans le table products,
une nouvelle ligne est insérée dans la table commander_articles 
pour tester , on prend le produit 8 (barbecue'Athos') ,
pour valeur de départ pro_stock_alert=5*/
DDELIMITER |

Create TRIGGER after_products_update 
After update 
on products
for each row 
BEGIN
    IF NEW.pro_stock < NEW.pro_stock_alert THEN
    INSERT  INTO commander_articles (qte,codart,datedujr) VALUES ((NEW.pro_stock_alert - NEW.pro_stock),NEW.pro_id,NOW());
    END IF;
END|
DELIMITER;

--LES TESTS 

UPDATE products
SET pro_stock = 6
WHERE pro_id = 8;

SELECT *
FROM commander_articles;
--retour>>>MySQL a retourné un résultat vide (c'est à dire aucune ligne).

UPDATE products
SET pro_stock = 4
WHERE pro_id = 8;

SELECT *
FROM commander_articles;
--retour >>> une ligne était rajouté dans le table commander_articles avec codart(8),qte(5-4=1),date(2021-07-23)

UPDATE products
SET pro_stock = 3
WHERE pro_id = 8;

SELECT *
FROM commander_articles;

 --Transactions
 /* TRANSACTIONS :
 La base de données ne contient actuellement que des employés en postes. 
 Il nous a demandé de rajoutée à notre base une liste des anciens 
 collaborateurs de l'entreprise partis en retraite. 
 il faut donc ajouter une ligne dans la table posts pour distanguer  les employés à la retraite.*/

INSERT into posts (pos_libelle) VALUES ('retraite');

/*modifier la poste de Madame HANAH et mettre 'retraite'*/ 
UPDATE employees 
SET emp_pos_id = (
SELECT pos_id FROM posts WHERE pos_libelle='retraite') 
WHERE emp_lastname='HANNAH'
AND emp_firstname='Amity';

/*Ecrire les requêtes correspondant à ces opéarations.*/

-- la requette pour selectionner l'employéé qui va remplacer Madame Amity HANAH:

SELECT emp_id,emp_salary,emp_enter_date, CONCAT(emp_lastname,'  ',emp_firstname) as emp_name 
FROM employees
JOIN posts on emp_pos_id=pos_id 
where emp_enter_date =(SELECT min(emp_enter_date)
FROM employees 
JOIN shops on emp_sho_id=sho_id 
where emp_pos_id=14 AND sho_city = 'Arras' 
);

-- requette pour changer la poste de de l'employé de pépiniériste a manager:
UPDATE employees
SET emp_pos_id = '2'
WHERE emp_id = 10


-- modifier le salare de l'employé qui va remplaser Madame Amity/
UPDATE employees
SET emp_superior_id = 10
WHERE emp_pos_id = 14 AND emp_sho_id = 2

--La transaction 
START Transaction;

UPDATE employees
SET emp_pos_id =(
    SELECT pos_id
    FROM  posts
    WHERE  pos_libelle = 'retraite'
)
WHERE emp_lastname = 'HANNAH' AND emp_firstname = 'Amity';

UPDATE employees
SET emp_pos_id = '2'
WHERE emp_id = 10;


UPDATE employees
SET emp_superior_id = 10
WHERE emp_pos_id = 14 AND emp_sho_id = 2

commit 
