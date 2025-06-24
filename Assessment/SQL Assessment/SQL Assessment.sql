create table country (
    countryid int primary key,
    countryname varchar(100),
    countrynameeng varchar(100)
);


create table city (
    cityid int primary key,
    cityname varchar(100),
    countryid int,
    foreign key (countryid) references country(countryid)
);

create table customer (
    customerid int primary key,
    customername varchar(100),
    cityid int,
foreign key (cityid) references city(cityid)
);

insert into country values 
(1,'Deutschland','Germany'),
(2,'Srbija','Serbia'),
(3,'Hrvatska','Croatia'),
(4,'United States of America','Unite States of America'),
(5,'Polska','Poland'),
(6,'Espana','Spain'),
(7,'Russiya','Russia');


insert into city values
(1,'Berlin',1),
(2,'Belgrade',2),
(3,'Zagreb',3),
(4,'New York',4),
(5,'Los Angeles',4),
(6,'Warsaw',5);

insert into customer values
(1,'Jewelry Store',4),
(2,'Bakery',1),
(3,'Cafe',1),
(4,'Restaurant',3);

-- Task 1
select c.countrynameeng,ct.cityname,cs.customername
from country c
left join city ct
on c.countryid= ct.countryid
left join customer cs
on ct.cityid=cs.cityid;

-- Task 2
select c.countrynameeng,ct.cityname,cs.customername
from country c
join city ct
on c.countryid= ct.countryid
left join customer cs
on ct.cityid=cs.cityid;


