--------------------------------------------------------------------------------------------------------------------------------
/*                                                                                                                              *
A clustered index in SQL is a type of index that sorts and stores the data rows of a table based on the index key values.       *
It fundamentally changes the way data is physically stored in the database.                                                     *
Because the data is sorted and stored according to the clustered index, each table can have only one clustered index.           *
                                                                                                                                *
"clustered index seek" means performance gain through clustered index while "index seek" means performance gain through         *
non-clustered index.                                                                                                            *
                                                                                                                                *
A non-clustered index does not affect the physical order of the data in the table.                                              *
Instead, it creates a separate structure that points to the data rows.                                                          *
A table can have multiple non-clustered indexes (up to 999 in SQL Server),                                                      *
which means you can create indexes on different columns to support various types of queries.                                    *
                                                                                                                                *
Index/Indexes should be created on column(s) which have more number of distinct values, that's how indexing will benefit us.    *                                                                                               *                              
                                                                                                                                */
--------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM orders_temp;

drop table if exists orders;

CREATE TABLE orders (
    order_id int NOT NULL,
    order_date datetime NOT NULL,
    order_customer_id int NOT NULL,
    order_status varchar(45) NOT NULL,
    PRIMARY KEY (order_id)
);

insert into orders SELECT * from orders_temp;

select * from orders;
-- Since we've PK as order_id here, the data will be automatically sorted on the basis of order_id.

/************************************************************ CLUSTERED INDEX DEMO ************************************************************/

select * from orders where order_customer_id = 10;
-- for this query, if we check query plan, it says "Clustered Index Scan". 
-- Scan means whole table data is scanned i.e. no performance gain by indexing (here, PK constraint automatically creates clustered index).

select * from orders where order_id= 100;
-- for this query, if we check query plan, it says "Clustered Index Seek".
-- Seek means query got performance gains due to indexing.

-- BELOW CODE TO BE EXECUTED IF WE WANT TO DEMONSTRATE COMPOSITE CLUSTERED INDEX.
--------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE [dbo].[orders] DROP CONSTRAINT [PK__orders__46596229CCCF8B42] WITH ( ONLINE = OFF )
GO


-- Primary key is clustered index. We cannot create 2 clustered indices for one table.
-- But we can create composite clustered index like:
CREATE CLUSTERED INDEX IX_order_id_order_customer_id on orders (order_customer_id, order_id);

select * from orders;
-- If we check output of above query, the data will be sorted on order_customer_id and if there are same order_customer_id,
-- then data will be sorted based on order_id.

select * from orders where order_customer_id= 4;                     -- will get benefit from indexing.
select * from orders where order_id= 10;                             -- will NOT get benefit from indexing.
select * from orders where order_customer_id= 4 and order_id= 51157; -- will get benefit from indexing.
select * from orders where order_id= 51157 and order_customer_id= 4; -- will get benefit from indexing.
--------------------------------------------------------------------------------------------------------------------------------

/************************************************************ NON-CLUSTERED INDEX DEMO ************************************************************/
-- Execute below 3 statements i.e. drop, create and insert for non-clustered index demo.
drop table if exists orders;

CREATE TABLE orders (
    order_id int NOT NULL,
    order_date datetime NOT NULL,
    order_customer_id int NOT NULL,
    order_status varchar(45) NOT NULL,
    PRIMARY KEY (order_id)
);

insert into orders SELECT * from orders_temp;

CREATE NONCLUSTERED INDEX IX_order_customer_id ON orders (order_customer_id);

select * from orders where order_customer_id= 5;
-- Above query will take benefit from non-clustered_index directly.
-- If we check estimated plan of this query, it will have key lookup. It is to get order_date and order_status columns in result.

select order_id, order_customer_id from orders where order_customer_id= 5;
select order_id from orders where order_customer_id= 5;
-- Both the above queries will also take benefit from non-clustered_index directly.
-- But in estimated plan, it won't have key lookup since we are not fetching any unindexed column (order_date or order_status) in result.

-- BELOW CODE TO BE EXECUTED IF WE WANT TO DEMONSTRATE NON-CLUSTERED INDEX CREATED ON MULTIPLE COLUMNS.
--------------------------------------------------------------------------------------------------------------------------------
DROP INDEX [IX_order_customer_id] ON [dbo].[orders]
GO

CREATE NONCLUSTERED INDEX IX_order_customer_id on orders (order_customer_id) INCLUDE (order_status);

select order_id, order_customer_id, order_status from orders where order_customer_id= 5;
-- Above query will take benefit from non-clustered_index directly with no need of key lookup as we are not fetching unindexed column- order_date in select.

select order_id, order_customer_id, order_status, order_date from orders where order_customer_id= 5;
-- Above query will also take benefit from non-clustered_index directly but will need key lookup to get data of unindexed column- order_date.

select order_id, order_customer_id from orders where order_status like 'PROCE%';
-- Estimated plan for above query says "Index Scan" so query CAN'T take benefit from non-clustered_index directly as 
-- filter is applied only on later column present in non-clustered index,
-- while order_customer_id column should also present in filter to get indexing benefit.

select order_id, order_customer_id from orders where order_customer_id= 5 AND order_status like 'PROCE%';
-- Above query will take benefit from non-clustered_index directly as filter is applied on both the columns present in non-clustered index.

/************************************************************ HAPPY ENDING ************************************************************/