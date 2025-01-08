create database item_sales;


-- Create Tables

create table supplier(
Supplier_id Varchar(50),
Supplier_name Varchar(50),
Contact_number varchar(30),
Email_address varchar(50),
Address varchar(50),
primary key(Supplier_id)
);

create table Customer(
Customer_id Varchar(50),
Customer_name Varchar(50),
Contact_number varchar(30),
Email_address varchar(50),
primary key(Customer_id)
);

create table Categories(
Categories_id Varchar(50),
Categories_name Varchar(50),
primary key(Categories_id)
);

create table products(
Products_id Varchar(50),
Product_name Varchar(50),
Category Varchar(50),
Current_stock int,
Reorder_level int,
Unit_price int,
Supplier_id Varchar(50),
primary key(Products_id),
foreign key(Supplier_id)
references supplier(Supplier_id)
);

create table transactions(
Transactions_id Varchar(50),
Transactions_date Date,
Products_id Varchar(50),
Quantity int,
Transaction_type Varchar(50),
Supplier_id Varchar(50),
Customer_id Varchar(50),
primary key(Transactions_id),
foreign key(Supplier_id)
references supplier(Supplier_id),
foreign key(Customer_id)
references Customer(Customer_id)
);

create table shops(
Shops_id Varchar(50) primary key,
Shops_name Varchar(100),
Location Varchar(150)
);

create table sales(
Sales_id Varchar(50) primary key,
Shops_id Varchar(50),
Products_id Varchar(50),
Quantity int,
Sales_date date,
Total_sales decimal
);

-- Insert data

select * from categories;

Insert into categories(Categories_id,Categories_name) 
       values ('CAT001','Machinery'),('CAT002','Accessories');
       
select * from customer;

Insert into customer(Customer_id,Customer_name,Contact_number,Email_address) 
       values('C001','John Doe','01409609597','john.doe@email.com'),('C002','Shagor','01609678597','Shagor@gmail.com');

