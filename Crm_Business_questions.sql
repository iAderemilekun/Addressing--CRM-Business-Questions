

select * from crm.cust_info_view civ 

select * from crm.loc_a101_view lav 

--Normalizing location table
update crm.loc_a101_view 
set cid = replace (cid, '-', '');

--Joining Customer information to Location table
create view crm.cust_info_view_new as
select * 
from crm.cust_info_view c
left join crm.loc_a101_view l
on c.cst_key = l.cid;



select * from crm.prd_info_view piv 

select * from crm.px_cat_g1v2_view pcgvv; 

-- Joining Product information to Product category
create view crm.prd_info_view_new as 
select 
*
from crm.prd_info_view p
left join crm.px_cat_g1v2_view px
on P.cat_id = px.id;


select * from crm.sales_details_view sdv;

-- Creating a Join Big Table
create view crm.sales_big_table as  
select 
*
from crm.sales_details_view s
left join crm.cust_info_view_new c
on s.sls_cust_id  = c.cst_id
left join crm.prd_info_view_new p
on s.sls_prd_key = p.prd_key;


--Responding to Business Questions 
select * from crm.sales_big_table sbt ; 

-- 1. Top rated customers based on total sales and total quantity
select 
sls_cust_id,
cst_firstname,
cst_lastname,
sum (sls_sales) as total_sales,
count (sls_quantity) as total_quantity
from crm.sales_big_table sbt 
group by sls_cust_id, cst_firstname, cst_lastname
order by total_sales desc, total_quantity desc;


--2. Top rated customers based on sales region 
select 
sls_cust_id,
country,
sum (sls_quantity * sls_sales) as tota_sae
from crm.sales_big_table sbt 
group by sls_cust_id, country 
order by tota_sae desc;


--3. Top Selling Products based on sales and quantity
select
prd_id,
prd_nm,
sum(sls_sales) as total_sales,
count(sls_quantity) as no_quantity
from crm.sales_big_table sbt 
group by prd_id, prd_nm 
order by total_sales desc, no_quantity desc;


--4. Overall Best selling Product Categories
select 
category,
subcategory,
sum(sls_sales) as total_sales,
count(sls_quantity) as no_quantity
from crm.sales_big_table sbt
group by category, subcategory 
order by total_sales desc;

--5. Year on Year Sales Profit Growth
with temp_table as(
select 
extract (year from sls_order_dt) as sales_year,
sum(sls_quantity * sls_price) as total_revenue
from crm.sales_big_table sbt 
group by 1
order by 1
)
select 
sales_year,
total_revenue,
lag(total_revenue) over () as last_year_revenue,
total_revenue - lag(total_revenue) over () as year_revenuegrowth,
round((total_revenue - lag(total_revenue) over ()) * 100 / lag(total_revenue) over (), 1) as percent_revgrowth
from temp_table;



--6. best selling products in each sales region
select * from( 
with temp_table as (
select 
country,
prd_id,
prd_nm,
sum(sls_sales) as total_sales,
count(sls_quantity) as no_quantity
from crm.sales_big_table sbt
group by 
country, prd_id, prd_nm
)
select 
country,
prd_id,
prd_nm,
total_sales,
no_quantity,
row_number() over (partition by country order by no_quantity desc) as product_rank
from temp_table
)t
where product_rank =1;


--7. Number of orders per product category
select 
category,
count(sls_ord_num) as no_orders
from crm.sales_big_table sbt 
group by 1
order by 2 desc;