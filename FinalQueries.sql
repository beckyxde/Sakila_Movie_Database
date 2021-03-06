/* Slide 1: (Question Set 1 - #2) */


WITH t1 AS
  (SELECT f.title title,
          c.name genre,
          f.rental_duration rental_duration,
          NTILE(4) OVER (PARTITION BY f.rental_duration) AS LEVEL
   FROM film f
   JOIN film_category fc ON f.film_id = fc.film_id
   JOIN category c ON c.category_id = fc.category_id
   WHERE c.name IN ('Animation',
                    'Children',
                    'Classics',
                    'Comedy',
                    'Family and Music'))
SELECT title,
       genre,
       rental_duration,
       CASE
           WHEN LEVEL <= 1 THEN 'first_quarter'
           WHEN LEVEL <= 2 THEN 'second_quarter'
           WHEN LEVEL <= 3 THEN 'third_quarter'
           ELSE 'final_quarter'
       END AS standard_quartile
FROM t1


/* Slide 2: Question Set 1 - #3 */


WITH t1 AS
  (SELECT f.title title,
          c.name genre,
          f.rental_duration rental_duration,
          NTILE(4) OVER (PARTITION BY f.rental_duration) standard_quartile,
                        CASE
                            WHEN rental_duration <= 25 THEN 'first_quarter'
                            WHEN rental_duration <= 50 THEN 'second_quarter'
                            WHEN rental_duration <= 75 THEN 'third_quarter'
                            ELSE 'final_quarter'
                        END AS LEVEL
   FROM film f
   JOIN film_category fc ON f.film_id = fc.film_id
   JOIN category c ON c.category_id = fc.category_id
   WHERE c.name IN ('Animation',
                    'Children',
                    'Classics',
                    'Comedy',
                    'Family and Music'))
SELECT genre,
       standard_quartile,
       count(genre)
FROM t1
GROUP BY 1, 2
ORDER BY 1, 2


/* Slide 3: (Question Set 2 - #1) */


SELECT s.store_id,
       DATE_PART('month', r.rental_date) rental_month,
       DATE_PART('year', r.rental_date) rental_year,
       SUM(r.rental_id) rental_count
FROM store s
JOIN customer c ON s.store_id = c.customer_id
JOIN rental r ON r.customer_id = c.customer_id
GROUP BY 1, 2, 3
ORDER BY 2


/* Slide 4: (Question Set 2 - #2) */


WITH t1 AS
  (SELECT DATE_TRUNC('month', payment_date) payment_month,
          CONCAT(c.first_name, ' ', c.last_name) full_name,
          COUNT(payment_id) payment_count,
          SUM(amount) monthly_sum
   FROM customer c
   JOIN payment p ON c.customer_id = p.customer_id
   GROUP BY 1, 2
   ORDER BY 4 DESC
   LIMIT 10)
SELECT TO_CHAR(payment_month, 'YYYY-MM') pay_month,
       full_name,
       payment_count,
       monthly_sum
FROM t1


/* Not Included in Slides: (Question Set 2 - #3) */


WITH t1 AS
  (SELECT sum(amount) total_payment,
          CONCAT(c.first_name, ' ', c.last_name) full_name
   FROM customer c
   JOIN payment p ON c.customer_id = p.customer_id
   WHERE payment_date BETWEEN '2007-01-01' AND '2007-12-31'
   GROUP BY 2)
SELECT full_name,
       total_payment,
       LEAD(total_payment) OVER (
                                 ORDER BY total_payment) - total_payment as lead_difference
FROM t1
ORDER BY 3 DESC
LIMIT 10


/* The first query shows the payment differences of the customer compared to one another. */

WITH t1 AS
  (SELECT CONCAT(c.first_name, ' ', c.last_name) full_name
   FROM customer c
   JOIN payment p ON c.customer_id = p.customer_id
   GROUP BY 1),
     t2 AS
  (SELECT t1.full_name,
          count(p.payment_id) AS payment_count,
          sum(p.amount) AS total_payment,
          date_trunc('month', p.payment_date) payment_month,
          date_trunc('year', p.payment_date) payment_year
   FROM t1
   WHERE p.payment_date BETWEEN '2007-01-01' AND '2007-12-31'),
     t3 AS
  (SELECT CONCAT(payment_year, '-', payment_month) pay_date,
          t1.full_name,
          t2.payment_count,
          t2.total_payment,
          LEAD(t2.total_payment) OVER (PARTITION BY t1.full_name
                                       ORDER BY DATE_TRUNC('month', t2.payment_month)) AS lead_difference
   FROM t1
   JOIN t2 ON t1.customer_id = t2.customer_id)
SELECT *
FROM t3
