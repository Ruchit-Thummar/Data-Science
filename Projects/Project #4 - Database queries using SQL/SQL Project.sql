create schema db1;
select * from books;
use db1;
-- remove duplicates from unique id 

-- check if any duplicates

select uniq_id, count(*) 
from books
group by uniq_id
having count(*) > 1;

-- remove duplicates 
set sql_safe_updates = 0;

with ranked as (
  select *, 
         row_number() over (partition by uniq_id order by uniq_id) as rn
  from books
)
delete from books
where uniq_id in (
  select uniq_id from ranked where rn > 1
);


-- make a unique id is primary key 
alter table books
modify uniq_id varchar(255);

alter table books
add primary key (uniq_id);

-- change column datatype
alter table books
modify column selling_price decimal(10,2);

alter table books
modify column list_price decimal(10,2);

alter table books
modify column amtsave decimal(10,2);

-- normalize colums 
alter table books
add column genre varchar(100) 
    generated always as (
        trim(substring_index(substring_index(breadcrumbs, '|', 2), '|', -1))
    ) stored,

add column subgenre varchar(200)
    generated always as (
        trim(substring_index(substring_index(breadcrumbs, '|', 3), '|', -1))
    ) stored,

add column authoredby varchar(100)
    generated always as (
        case
            when `desc` like '%"Authored By"=>"%' 
            then trim(substring_index(substring_index(`desc`, '"Authored By"=>"', -1), '"', 1))
            else 'not provided'end
    ) stored,

add column language varchar(50)
    generated always as (
        case
            when `desc` like '%"Language"=>"%' 
            then trim(substring_index(substring_index(`desc`, '"Language"=>"', -1), '"', 1))
            else 'not provided'end
    ) stored,

add column publicationyear varchar(50)
    generated always as (
        case
            when `desc` like '%"Publication Year"=>"%' 
            then trim(substring_index(substring_index(`desc`, '"Publication Year"=>"', -1), '"', 1))
            else 'not provided'end
    ) stored,

add column publishername varchar(150)
    generated always as (
        case
            when `desc` like '%"Publisher Name"=>"%' 
            then trim(substring_index(substring_index(`desc`, '"Publisher Name"=>"', -1), '"', 1))
            else 'not provided'end
    ) stored;

alter table books
add column binding varchar(100)
    generated always as (
        case when specifications like '%"binding"=>"%'
        then trim(substring_index(substring_index(specifications, '"binding"=>"', -1), '"', 1))
            else 'not provided' end
    ) stored;

update books
set genre = 'others'
where genre not in (
    'academic & professional',
    'biographies & auto biographies',
    'business & management',
    'children & teens',
    'literature & fiction',
    'non fiction',
    'regional books',
    'religion & spirituality',
    'self help'
);

SET SQL_SAFE_UPDATES = 0;

-- make a 1 table of all usefull colums 

select * from books;
create view books_view as
select 
  b1.no as no,
  b1.model as model,
  b1.book_name as bookname,
  b1.uniq_id as uniqueid,
  b1.language as language,
  b1.brand as brand,
  b1.authoredby as author,
  b1.publicationyear as publicationyear,
  b1.genre as genre,
  b1.subgenre as subgenre,
  b1.publishername as publishername,
  b1.binding as binding, 
  b1.weight as weight,
  b1.selling_price as sellingprice,
  b1.productcode as productcode,
  b1.list_price as listprice,
  b1.selling_date as sellingdate,
  b1.amtsave as amtsave
  
from books b1
left join books b on b.uniq_id = b1.model;


-- Q-1 For each genre, list the top 3 most discounted books, including the rank, and also show the previous book’s saving  and next book’s saving  within the same genre.
use db1;
with main as (

select bookname,author,genre,amtsave,
rank() over (partition by genre order by amtsave) as ranks,
Lag(amtsave) over (partition by genre order by amtsave) as previous_books,
Lead(amtsave) over (partition by genre order by amtsave) as next_books
from books_view
)
select * from main
where ranks <=3;

select * from books_view;

-- Q-2 For each genre, we want to find the one book where the discount (amtsave) suddenly increased the most compared to the previous book.

with main as (
select author,genre,amtsave,
rank() over(partition by genre order by amtsave) as ranks,
Lag(amtsave) over (partition by genre order by amtsave) as previous_books
from books_view
),
differance as (
select * ,(amtsave - previous_books) as discount
from main
),
max as (
select *,rank() over(partition by genre order by discount desc) as dis_rank
from differance
)
select genre,author,amtsave,previous_books,discount
from max 
where dis_rank=1;


-- Q-3 Which books and genre have a discount greater than 50%, and what are their corresponding list and selling prices? 

select book_name,genre,list_price, selling_price, round(((list_price - selling_price) / list_price) * 100,2) AS dis_percent
from books
where ((list_price - selling_price) / list_price) * 100 > 50;

-- Q-4 Please identify the top 2 most discounted books in each genre — but only include genres where we have at least 5 books listed.

with books_genre as (
select genre 
from books_view
group by genre 
having count(*)>=5
),
rnk_book as (
select *,
rank() over(partition by genre order by amtsave desc) as rnk
from books_view
where genre in (select * from books_genre)
)
select bookname,genre,uniqueid,author,amtsave
from rnk_book
where rnk <=2;

-- Q-5 Identify the top 2 most discounted books per genre — but only for genres where the average selling price is over ₹250 and the total number of books.

with genre_filter as (
select genre 
from books_view
group by genre 
having avg(sellingprice) > 250
),
ranked_books as (
select *,
rank() over(partition by genre order by amtsave desc) as rank_in_genre
from books_view 
where genre in (select genre from genre_filter)
)
select genre,uniqueid,author,amtsave,sellingprice
from ranked_books
where rank_in_genre <= 2;


-- Q-6 Given a starting book (by its uniq_id), find all books that are related to it by model — including newer versions, reprints, or variants that are linked by model ID.

select *
from books_view
where model = (
select model
from books_view
where uniqueid = '006fc68c28bd5f9786838aca5843fd6a'
);

-- Q-7 We need to identify the full edition trail (linked by model and uniq_id) of a book, starting from the earliest version — and highlight the most recent one with the highest selling price.

with same_books as (
  select *
  from books_view 
  where model = (
    select model 
    from books_view
    where uniqueid = '006fc68c28bd5f9786838aca5843fd6a'
  )
),
high_price as (
  select *,
         rank() over(order by sellingprice desc) as ranks
  from same_books
)
select *,
       case when ranks = 1 then 'expensive' else null end as highlight
from high_price
order by sellingdate;


-- Q-8 Find the top 2 genres that have sold the most in total revenue in the past 4 months.

select genre, sum(sellingprice) as total_revenue
from books_view
where sellingdate >= '2016-04-30'
group by genre
order by total_revenue desc
limit 2;


-- Q-9 We want to find authors and genre who sold at least 3 books in the last 3 months, with an discount of 100.

with recent_books as (
  select genre,author
  from books_view
  where sellingdate >= date_sub('2016-06-30', interval 3 month)
    and amtsave >= 100
)

select genre,author, count(*) as books_sold
from recent_books
group by genre,author
having count(*) >= 3;

select * from books_view;

-- Q-10 Which were the last 10 days when books were sold, and how many books were sold on each of those days?

select sellingdate, count(*) as num_sales
from books_view
group by sellingdate
order by sellingdate desc
limit 10;


-- Q-11 So, for each publisher, find the single book in the last 5 months that gave customers the highest absolute savings.
-- Include the book’s author, genre, and price details.
use db111;
with intervel as 
(
select author,genre,publishername,sellingprice,amtsave,sellingdate
from books_view
where sellingdate >= date_sub('2016-10-15', interval 5 month)
),
ranking as (
select *,
rank() over(partition by publishername order by amtsave desc) as ranks
from intervel
)
select author,genre,publishername,sellingprice,amtsave,sellingdate
from ranking
where ranks=1;


-- Q-12 When was the last time books were sold, and how many books were sold on that day?

select bookname,sellingdate, count(*) as num_sales
from books_view
group by sellingdate,bookname 
order by sellingdate desc
limit 1;

-- Q-13 Find all books where the selling price is higher than the list price. Show book name, list price, selling price, and publisher.
select book_name,selling_price,genre,publishername
from books
order by selling_price desc
limit 10;


-- Q-14 We want to understand customer preferences in the last 45 days —
-- For each genre, which book binding type (e.g., paperback, hardcover, spiral) was the most popular based on the number of books sold?
with preferences as (
    select genre, binding
    from books_view
    where sellingdate >= date_sub('2016-06-30', interval 45 day)
),
ranking as (
    select genre,binding,count(*) as total_sold,
        rank() over (partition by genre order by count(*) desc) as ranks
    from preferences
    group by genre, binding
)
select genre,binding,total_sold
from ranking
where ranks = 1;


select * from books_view;

-- Q-15 Which genres have been giving high average discounts (in ₹) over the last 60 days but still sold fewer than 10 books total?

with recent_sales as (
  select *
  from books_view
  where sellingdate >= date_sub('2016-06-30', interval 60 day)
)

select bookname,genre,count(*) as total_books,round(avg(amtsave), 2) as avg_discount
from recent_sales
group by genre,bookname
having count(*) < 10
order by avg_discount desc;

select * from books_view;


-- Q-16 write a store procedure to get books by brand that takes a brand name as a input parameter and return all books like unique id,author
-- selling price,list price,genre,subgenre,etc. for that brand.

DELIMITER //

create procedure `book_details`(in brand_name varchar(255))
begin
    select * from books_view
    where brand = brand_name;
end//

DELIMITER ;

call `book_details`('Hodder & Stoughton');

-- Q-17 Create a stored procedure Get Books With Missing Brand that returns all products where the brand field is NULL.

DELIMITER //

create procedure missing_brand()
begin 
select * from books_view
where brand is null or brand='';
end // 

DELIMITER ;

-- Q-18 Write a stored procedure Delete Books By ProductCode that deletes a product from the dataset based on the productcode provided as an input parameter.

DELIMITER //

create procedure delete_books(in p_code int)
begin 
delete from books
where productcode = p_code;
end//

DELIMITER ;

 call delete_books(12299410);
 
 select * from books
 where productcode = 12299410;
 
 -- Q-19 Create a stored procedure Get Average SellingPrice By Brand that returns the average selling_price of products for a given brand.
 use db111;
 DELIMITER //
 
 create procedure `avg_selling_price`(in b_name varchar (200))
 begin SELECT bookname,brand,round(AVG(sellingprice),2) AS average_selling_price
from books_view
where b_name = brand
group by bookname,brand;
end //

DELIMITER ;

call `avg_selling_price`('Hodder & Stoughton');

 
 
-- Q-20 Create a stored procedure GetBooksByPublicationYear that accepts a year as input and returns all books published in that year.

DELIMITER //
create procedure publish_year(in p_year int)
begin
select * from books_view
where publicationyear = p_year;
end //

DELIMITER ;

call publish_year(2012);


-- Summary 

-- I cleaned up the book data and organized it to get useful insights. By analyzing the data, I found which books in each genre have the biggest discounts and where the discount suddenly changed, helping me understand pricing strategies. I also looked at books with over 50% discount and showed their original and selling prices, while tracking different editions to see which versions are the most valuable.

-- Next, I identified the genres that earned the most money in the last 4 months and discovered authors who sold many discounted books recently. I also analyzed recent sales to understand overall activity and trends.

-- In addition, I highlighted the biggest customer savings from each publisher in the last 5 months and looked at which genres offer the best average discounts and the most popular book binding types (like paperback or hardcover).

-- Finally, I spotted some genres that gave big discounts but sold very few books, which could mean the discount strategy isn’t working as expected.


-- Conclusion 

-- I cleaned and organized the book data to understand sales, discounts, and customer choices.

-- The top earning genres in the last 4 months were Literature & Fiction with 179,048 and Non Fiction with 114,360.

-- In Literature & Fiction, authors like Ian Doescher and Tom Robbins sold at least 3 books with a discount of ₹100. Non Fiction was not considered because most books didn’t have author names.

-- The genres with discounts over 50% were Literature & Fiction, Non Fiction, and Children & Teens, with their list and selling prices noted.

-- The most recent book sold was "(INDIAN EDITION) SOILS AND ENVIRONMENTAL QUALITY 3RD EDITION 3 Rev ed Edition" on 31-05-2016, with 1 copy sold.

-- Customers preferred Paperback as the most popular binding in the last 45 days.

-- Literature & Fiction is the strongest genre, performing well in revenue, active authors, discounts, and customer choice. Some genres give big discounts but don’t sell much, which means the discount strategy might need rethinking.