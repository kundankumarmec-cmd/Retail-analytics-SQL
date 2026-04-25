use rtcs;
describe Customer_profiles;
describe sales_transaction;
alter table customer_profiles change ï»¿CustomerID  CustomerID int;
alter table product_inventory change ï»¿ProductID  ProductID int;
alter table sales_transaction change ï»¿TransactionID  TransactionID int;
select * from customer_profiles;
select * from product_inventory;
select * from sales_transaction ;

-- REMOVED DUPLICATE AND CREATED NEW TABLE
select TransactionID , COUNT(*) from sales_transaction
group by TransactionID 
having count(*) > 1;
create table sales_transaction1 as select distinct * from sales_transaction;
drop table sales_transaction;
alter table sales_transaction1 rename to sales_transaction;
select * from sales_transaction ;

-- DESCREPIENCIES IN PRICE 
select st.TransactionID, st.price as transaction_price ,pi.price as inventory_price from sales_transaction st
join
product_inventory pi on st.ProductID = pi.ProductID
where st.price <> pi.price;

-- IT MAY REPLACE ALL ROWS BY MISTAKE IF YOU RUNED WRONGLY -  'SET SQL_SAFE_UPDATES = 0;' IT MEANS SAFE UPDATE SHOULD BE DISABLED THEN ONLY IT WILL WORK
update sales_transaction st 
set 
price = (select pi.price from product_inventory pi where pi.ProductID = st.ProductID)
where st.ProductID in 
(select pi.ProductID from product_inventory pi where st.price <> pi.price);

select * from sales_transaction;

-- Identify the null values 
select count(*) from customer_profiles 
where location is null;
update customer_profiles  
set Location = "unknown"
where Location is null  or TRIM(Location) = '';

select * from customer_profiles;

-- clean the DATE column 
create table abc like sales_transaction;
insert into abc (select * from sales_transaction);

alter table abc add column transactiondate_updated date;
alter table abc
drop  column transactio_date_updated;

update abc 
set transactiondate_updated = str_to_date(transactiondate,"%d/%m/%Y");
drop table sales_transaction;
alter table abc rename to sales_transaction;

select * from sales_transaction;

-- summarize the total sales and quantities sold per product by the company
select ProductID, sum(QuantityPurchased)  as Total_unitsold,
sum(QuantityPurchased * Price) as Total_sales
 from sales_transaction
group by ProductID 
order by Total_sales desc;

-- count the number of transactions per customer to understand purchase frequency
select CustomerID, count(TransactionID) as Transactionper_customer from sales_transaction
group by CustomerID
order by Transactionper_customer desc;
-- OR
Select CustomerID, 
      Count(*) AS   Transactionper_customer
From sales_transaction
Group By CustomerID
Order By  Transactionper_customer Desc;

-- performance of the product categories based on the total sales 

select pi.Category as Category, 
sum(st.QuantityPurchased) as TotalUnitSold,
sum(st.QuantityPurchased * st.price) as TotalSales
from sales_transaction st 
join
product_inventory pi on st.ProductID = pi.ProductID
group by pi.Category
order by TotalSales desc;

-- the top 10 products with the highest total sales revenue 
select ProductID, sum(QuantityPurchased * Price) as TotalRevenue
from sales_transaction
group by ProductID
order by TotalRevenue desc
limit 10;


-- the 10 products with the least amount of units sold 

select ProductID , sum(QuantityPurchased) as TotalUnitSold 
from sales_transaction
group by ProductID
having TotalUnitSold > 0
order by TotalUnitSold asc
limit 10;

-- OR 
select ProductID , sum(QuantityPurchased) as TotalUnitSold 
from sales_transaction
group by ProductID
order by TotalUnitSold asc
limit 10;

-- identify the sales trend to understand the revenue pattern of the company.

select	cast(TransactionDate as Date) as Datetrains,
count(*) as TransactionCount,
sum(QuantityPurchased) as TotalUnitSold,
round(sum(QuantityPurchased * Price),2) as TotalSales
from sales_transaction
group by Datetrains
order by Datetrains desc;

--  the month on month growth rate of sales of the company which will help understand the growth trend of the company.
with Monthaly_sales as (
select extract(month from TransactionDate) as Month,
round(sum(QuantityPurchased * Price),2) as Total_Sales 
from sales_transaction 
group by extract(month from TransactionDate)
)

select Month ,Total_Sales,
lag(Total_Sales) over(order by Month) as Previous_Month_Sales,
round((
(Total_Sales - lag(Total_Sales) over (order by Month))/
(lag(Total_Sales) over(order by Month))
) * 100,2) as MOM_growth_percentage
from Monthaly_sales
order by month;

--  number of transaction along with the total amount spent by each customer and customer purchase frequency

select CustomerID, count(TransactionID) as No_of_Transactions, round(sum(QuantityPurchased * Price),2) as Total_spent 
from sales_transaction
group by CustomerID
having No_of_Transactions > 10 and
Total_spent >1000
order by Total_spent desc;

-- the number of transaction along with the total amount spent by each customer , occasional customer

select CustomerID, count(TransactionID) as No_of_Transaction, round(sum(QuantityPurchased * Price),2) as Total_spent 
from sales_transaction
group by CustomerID
having No_of_Transaction <= 2 
order by No_of_Transaction asc ,
Total_spent desc;

-- REPEAT PURCHASE - total number of purchases made by each customer against each productID

select CustomerID, ProductID, count(*) as Times_purchased
from sales_transaction 
group by CustomerID, ProductID
having Times_purchased >1
order by Times_purchased desc;


-- LOYALTY OF CUSTOMER  - the duration between the first and the last purchase of the customer 

With ConvertedDate as 
(
select CustomerID,
str_to_date(TransactionDate, '%d/%m/%Y') as converted_date 
from sales_transaction 
)

select CustomerID, 
min(converted_date) as first_purchase,
max(converted_date) as last_purchase,
datediff(max(converted_date),min(converted_date)) as Days_between_purchases
from ConvertedDate
group by CustomerID
having Days_between_purchases > 0
order by Days_between_purchases desc;


-- segments customers based on the total quantity of products they have purchased.

create table CUSTOMER_SEGMENT as 
select CustomerID,
case 
when TotalQuantity > 30 then 'High'
when TotalQuantity between 10 and 30 then 'Med'
when TotalQuantity between 1 and 10 then 'Low'
else 'None'
end as CustomerSegment 
from (
select a.CustomerID,
sum(b.QuantityPurchased) as TotalQuantity
from customer_profiles a 
join sales_transaction b
on a.CustomerID = b.CutomerID
group by a.CustomerID 
) as TOTAL_QUANTITY;

select CustomerSegment, count(*)  from CUSTOMER_SEGMENT 
group by CustomerSegment;

