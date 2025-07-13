CREATE SCHEMA Apple_itunes;
use Apple_itunes;

-- Table: employee
CREATE TABLE employee (
    employee_id INTEGER PRIMARY KEY,
    last_name VARCHAR(100),
    first_name VARCHAR(100),
    title VARCHAR(100),
    reports_to INTEGER,
    levels char(10),
    birth_date DATE,
    hire_date DATE,
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    phone VARCHAR(20),
    fax VARCHAR(20),
    email VARCHAR(100)
);

-- Table: customer
CREATE TABLE customer (
    customer_id INTEGER PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    company VARCHAR(100),
    address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    phone VARCHAR(20),
    fax VARCHAR(20),
    email VARCHAR(100),
    support_rep_id INTEGER
);

-- Table: invoice
CREATE TABLE invoice (
    invoice_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    invoice_date DATE,
    billing_address VARCHAR(255),
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_country VARCHAR(100),
    billing_postal_code VARCHAR(20),
    total DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- Table: media_type
CREATE TABLE media_type (
    media_type_id INTEGER PRIMARY KEY,
    name VARCHAR(100)
);

-- Table artist
CREATE TABLE artist (
	artist_id INTEGER PRIMARY KEY,
    name VARCHAR(300)
);
drop table album;
-- Table album
CREATE TABLE album (
	album_id INTEGER PRIMARY KEY,
    title VARCHAR(200),
    artist_id INTEGER,
    FOREIGN KEY (artist_id) REFERENCES artist(artist_id)
);

-- Table genre
CREATE TABLE genre (
	genre_id INTEGER primary KEY,
    name varchar(100)
);

-- Table: track
CREATE TABLE track (
    track_id INTEGER PRIMARY KEY,
    name VARCHAR(200),
    album_id INTEGER,
    media_type_id INTEGER,
    genre_id INTEGER,
    composer VARCHAR(200),
    milliseconds INTEGER,
    bytes INTEGER,
    unit_price DECIMAL(10, 2),
    FOREIGN KEY (media_type_id) REFERENCES media_type(media_type_id),
    FOREIGN KEY (album_id) REFERENCES album(album_id),
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
);

-- Table invoice_line
CREATE TABLE invoice_line (
	invoice_line_id integer primary key,
    invoice_id integer,
    track_id integer,
    unit_price decimal(10,2),
    quantity integer,
    foreign key (invoice_id) references invoice(invoice_id),
    foreign key (track_id) references track(track_id)
);

-- Table: playlist_track
CREATE TABLE playlist_track (
    playlist_id INTEGER,
    track_id INTEGER,
    FOREIGN KEY (track_id) REFERENCES track(track_id)
);

-- Table playlist
CREATE TABLE playlist (
	playlist_id integer,
    name varchar(100)
);


-- Q1. Who is the senior most employee based on job title?
SELECT first_name, last_name, title, levels
FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Q2. Which countries have the most Invoices?
SELECT 
    billing_country, COUNT(invoice_id) AS invoice_count
FROM
    invoice
GROUP BY billing_country
ORDER BY COUNT(invoice_id) DESC
LIMIT 5;

-- Q3. What are top 3 values of total invoice?
SELECT invoice_id, total
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals.
select billing_city, sum(total) as total_invoice from invoice group by billing_city order by sum(total) desc limit 1;

-- Q4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
SELECT billing_city, SUM(total) AS total_sales
FROM invoice
GROUP BY billing_city
ORDER BY total_sales DESC
LIMIT 1;

-- Q5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;

-- Q6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A 
SELECT DISTINCT c.email, c.first_name, c.last_name, g.name AS genre
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email ASC;

-- Q7. Let's invite the artists who have written the most rock music in our dataset. 
--     Write a query that returns the Artist name and total track count of the top 10 rock bands.
SELECT ar.name AS artist_name, COUNT(*) AS rock_track_count
FROM track t
JOIN genre g ON t.genre_id = g.genre_id
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY rock_track_count DESC
LIMIT 10;

-- Q8. Return all the track names that have a song length longer than the average song length. 
--     Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds) FROM track
)
ORDER BY milliseconds DESC;

-- Q9. Find how much amount spent by each customer on artists. Write a query to return the customer name, artist name, and total spent.
SELECT 
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    ar.name AS artist_name,
    ROUND(SUM(il.unit_price * il.quantity), 2) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
GROUP BY c.customer_id, ar.artist_id
ORDER BY total_spent DESC;

-- Q10. We want to find out the most popular music Genre for each country. 
--      We determine the most popular genre as the genre with the highest amount of purchases. 
--      Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.
WITH genre_counts AS (
    SELECT
        c.country,
        g.name AS genre,
        COUNT(*) AS purchase_count
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
),
ranked_genres AS (
    SELECT *,
           RANK() OVER (PARTITION BY country ORDER BY purchase_count DESC) AS rnk
    FROM genre_counts
)
SELECT country, genre, purchase_count
FROM ranked_genres
WHERE rnk = 1;

-- Q11. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount.
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.country,
        SUM(i.total) AS total_spent
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.country
),
ranked_customers AS (
    SELECT *,
           RANK() OVER (PARTITION BY country ORDER BY total_spent DESC) AS rnk
    FROM customer_spending
)
SELECT country, first_name, last_name, total_spent
FROM ranked_customers
WHERE rnk = 1;

-- Q12. Who are the most popular artists?
SELECT ar.name AS artist_name, COUNT(*) AS tracks_sold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
GROUP BY ar.artist_id, ar.name
ORDER BY tracks_sold DESC
LIMIT 10;

-- Q13. Which is the most popular song?
SELECT t.name AS song_name, COUNT(*) AS times_sold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
GROUP BY t.track_id, t.name
ORDER BY times_sold DESC
LIMIT 1;

-- Q14. What are the average prices of different types of music?
SELECT g.name AS genre, ROUND(AVG(t.unit_price), 2) AS avg_price
FROM track t
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY g.name
ORDER BY avg_price DESC;

SELECT mt.name AS media_type, ROUND(AVG(t.unit_price), 2) AS avg_price
FROM track t
JOIN media_type mt ON t.media_type_id = mt.media_type_id
GROUP BY mt.name
ORDER BY avg_price DESC;

-- Q15. What are the most popular countries for music purchases?
SELECT billing_country, COUNT(*) AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;

