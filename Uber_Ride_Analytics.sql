create database uber;
use uber;

ALTER Table ncr_ride_bookings
RENAME COLUMN `Booking ID` TO Booking_ID,
RENAME COLUMN `Booking Status` TO Booking_Status,
RENAME COLUMN `Customer ID` to Customer_ID,
RENAME COLUMN `Vehicle Type` TO Vehicle_Type,
RENAME COLUMN `Pickup Location` TO Pickup_Location,
RENAME COLUMN `Drop Location` TO Drop_location,
RENAME COLUMN `Avg VTAT` TO Avg_vtat,
RENAME COLUMN `Avg CTAT` TO Avg_ctat,
RENAME COLUMN `Cancelled Rides by Customer` TO Cancelled_rides_by_customer,
RENAME COLUMN `Reason for cancelling by Customer` TO Reason_for_cancelling_by_customer,
RENAME COLUMN `Cancelled Rides by Driver` TO Cancelled_rides_by_driver,
RENAME COLUMN `Driver Cancellation Reason` TO Driver_cancellation_reason,
RENAME COLUMN `Incomplete Rides` to Incomplete_rides,
RENAME COLUMN `Incomplete Rides Reason` to Incomplete_rides_reason,
RENAME COLUMN `Booking Value` to Booking_value,
RENAME COLUMN `Ride Distance` to Ride_distance,
RENAME COLUMN `Driver Ratings` to Driver_ratings,
RENAME COLUMN `Customer Rating` to Customer_rating,
RENAME COLUMN `Payment Method` to Payment_method;

# Total Bookings
SELECT COUNT(Booking_id) as total_bookings from ncr_ride_bookings;

SELECT * FROM ncr_ride_bookings;

# Booking Status Breakdown
SELECT booking_status,
       count(booking_id) as total_bookings
from ncr_ride_bookings group by booking_status;

# Ride volumne over time
SELECT date_format(str_to_date(Date, '%d-%m-%y'), '%Y-%M') as 'month',
	   COUNT(booking_id) as total_bookings
from ncr_ride_bookings group by date_format(str_to_date(Date, '%d-%m-%y'), '%Y-%M')
ORDER BY month;

# Different parameters based on vehicle type
SELECT vehicle_type,
	   COUNT(booking_id) as total_bookings,
       SUM(Booking_value) as total_booking_value,
       ROUND(sum(case when booking_status = 'completed' then booking_value else 0 end), 2) as successful_booking_value,
       ROUND(sum(case when booking_status = 'completed' then ride_distance else 0 end), 2) as successful_ride_distance,
       ROUND(avg(ride_distance), 2) as total_ride_distance
from ncr_ride_bookings GROUP BY vehicle_type;

# Revenue by payment method
SELECT Payment_method,
       COUNT(booking_ID) AS total_bookings
from ncr_ride_bookings where payment_method is not null
group by payment_method;

# Show ride distance according to months when the ride is completed
SELECT date_format(str_to_date(date, '%d-%m-%y'), '%Y-%M') as 'month',
       ROUND(sum(case when booking_status = 'completed' then ride_distance else 0 end), 2) as total_successful_rides
from ncr_ride_bookings 
group by date_format(str_to_date(date, '%d-%m-%y'), '%Y-%M');

# Cancelled rides by customers
select Incomplete_rides_reason,
       count(booking_id) as total_rides
from ncr_ride_bookings 
where Incomplete_rides_reason is not null 
group by Incomplete_rides_reason;

# Highest dropped location
SELECT Drop_location,
       COUNT(Booking_id) as number_of_bookings
from ncr_ride_bookings GROUP BY Drop_location
ORDER BY number_of_bookings desc
limit 5;
       
# Cancellation rate by drivers monthwise
SELECT date_format(str_to_date(Date, '%d-%m-%y'), '%Y-%m') as 'month',
      (COUNT(CASE WHEN booking_status='Cancelled by Customer' THEN 1 END)*100/ COUNT(*)) AS customer_cancellation_rate,
      (COUNT(CASE WHEN booking_status='Cancelled by Driver' THEN 1 END)*100 / COUNT(*)) AS driver_cancellation_rate
from ncr_ride_bookings 
GROUP BY date_format(str_to_date(Date, '%d-%m-%y'), '%Y-%m');

# Places where cab is mostly cancelled by customers and drivers
SELECT Pickup_location,
       COUNT(CASE WHEN booking_status='Cancelled by customer' THEN 1 END) AS total_cancelled_rides_by_customer,
       COUNT(CASE WHEN booking_status='Cancelled by Driver' THEN 1 END) AS total_cancelled_rides_by_driver
from ncr_ride_bookings GROUP BY Pickup_location;

#Top customers by revenue
SELECT Booking_ID,
       SUM(CASE WHEN booking_status='completed' THEN booking_value ELSE 0 END) AS total_revenue
from ncr_ride_bookings GROUP BY Booking_ID
ORDER BY total_revenue desc
limit 5;

# Which vehicle_type is travelling the most
SELECT vehicle_type,
       ROUND(sum(case when booking_status = 'completed' THEN Ride_distance ELSE 0 END), 2) AS total_distance_travelled,
       ROUND(SUM(CASE WHEN booking_status='completed' THEN Booking_value ELSE 0 END), 2) AS total_revenue_generated
from ncr_ride_bookings GROUP BY vehicle_type
Order by total_distance_travelled desc;

#Which vehicle type has the highest revenue per km, and how does it compare across months?
SELECT Vehicle_type,
	   month(str_to_date(Date, '%d-%m-%y')) as ride_month,
       ROUND(SUM(booking_value) / SUM(ride_distance), 2) as highest_revenue_per_km
from ncr_ride_bookings where booking_status = 'completed'
GROUP BY Vehicle_type, month(str_to_date(Date, '%d-%m-%y'))
order by ride_month;

#Which pickup and drop locations have the highest ride demand, and what are the most popular ride routes?
SELECT Pickup_location,
       Drop_location,
       COUNT(Booking_id) as total_bookings
from ncr_ride_bookings where booking_status='completed'
GROUP BY Pickup_location, Drop_location
Order by total_bookings desc;

#What is the average driver rating per vehicle type, and how does it correlate with completed rides and revenue?
SELECT Vehicle_type,
       ROUND(avg(Driver_ratings), 2) as avg_rating,
       ROUND(SUM(CASE WHEN booking_status = 'completed' THEN Ride_distance ELSE 0 END), 2) AS total_distance_travelled,
       ROUND(SUM(CASE WHEN booking_status = 'completed' THEN Booking_value ELSE 0 END),2) AS total_revenue,
       COUNT(CASE WHEN booking_status = 'completed' THEN 1 END ) AS total_completed_rides
from ncr_ride_bookings GROUP BY Vehicle_type
ORDER BY avg_rating desc;

#What is the average customer rating trend over time, and do customers who give low ratings tend to cancel more?
SELECT DATE_FORMAT(STR_TO_DATE(DATE, '%d-%m-%y'), '%Y-%M') AS ride_month,
	   ROUND(AVG(Customer_rating), 2) AS customer_rating,
       COUNT(*) AS total_rides
from ncr_ride_bookings where customer_rating is not null
GROUP BY DATE_FORMAT(STR_TO_DATE(DATE, '%d-%m-%y'), '%Y-%M')
ORDER BY ride_month, total_rides;

select * from ncr_ride_bookings;

SELECT
    CASE
        WHEN Customer_rating <= 3 THEN 'Low Rating'
        WHEN Customer_rating > 3 AND Customer_rating <= 4 THEN 'Medium Rating'
        WHEN Customer_rating > 4 THEN 'High Rating'
        ELSE 'No Rating'
    END AS rating_category,
    COUNT(*) AS total_rides,
    SUM(CASE WHEN Booking_Status IN ('Cancelled by Customer', 'Cancelled by Driver') THEN 1 ELSE 0 END) AS cancelled_rides,
    ROUND(SUM(CASE WHEN Booking_Status IN ('Cancelled by Customer', 'Cancelled by Driver') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_rate_percent
FROM ncr_ride_bookings
WHERE Customer_rating IS NOT NULL
GROUP BY rating_category
ORDER BY cancellation_rate_percent DESC;

#What is the cancellation trend by customers vs drivers?
SELECT 
      DATE_FORMAT(str_to_date(Date, '%d-%m-%y'), '%Y-%M') AS 'month',
      sum(case when booking_status = 'Cancelled by Driver' then 1 else 0 end) as cancel_by_driver,
      sum(case when booking_status = 'Cancelled by Customer' THEN 1 else 0 end) as cancel_by_customer
from ncr_ride_bookings GROUP BY DATE_FORMAT(str_to_date(Date, '%d-%m-%y'), '%Y-%M')
Order by month;

# Reasons which occur frequently while cancelling
SELECT
      'Customer' as cancel_by,
      Reason_for_cancelling_by_customer as cancelling_reasons,
      COUNT(*) AS total_cancel
from ncr_ride_bookings 
where booking_status='Cancelled by Customer' AND
Reason_for_cancelling_by_customer is not null
GROUP BY Reason_for_cancelling_by_customer
UNION ALL
SELECT 
	  'Driver' as cancel_by,
      Driver_cancellation_reason as cancelling_reasons,
      COUNT(*) AS total_count
from ncr_ride_bookings
WHERE booking_status='Cancelled by Driver' AND
Driver_cancellation_reason IS NOT NULL
GROUP BY Driver_cancellation_reason;

#How much revenue loss is incurred due to cancellations and incomplete rides each month?
WITH Cancel_rides as (
     SELECT booking_status,
			date_format(str_to_date(Date, '%d-%m-%y'), '%Y-%M') as 'month',
            sum(COALESCE(Booking_value, 0)) as total_amount,
            COUNT(Booking_ID) AS total_number_of_cancel_rides
	 from ncr_ride_bookings WHERE booking_status IN ('Incomplete', 'Cancelled by Driver', 'Cancelled by Customer')
     GROUP BY date_format(str_to_date(Date, '%d-%m-%y'), '%Y-%M'), booking_status
)
select * from cancel_rides order by month;
	
#What is the average booking value per hour of the day, and which hours generate the maximum earnings?
SELECT 
      HOUR(Time) as booking_hour,
      ROUND(AVG(booking_value),2) as avg_booking_value,
      SUM(Booking_value) as total_booking_value,
      COUNT(*) AS total_rides
from ncr_ride_bookings
where booking_status = 'Completed'
GROUP BY hour(time)
order by total_booking_value desc;
      
#Which payment method has the lowest average fare per ride, and is it more common for short or long rides?
WITH payment_stats AS (
    SELECT 
        Payment_method,
        ROUND(AVG(Booking_value), 2) AS avg_fare,
        COUNT(*) AS total_rides
    FROM ncr_ride_bookings
    WHERE booking_status = 'Completed'
    GROUP BY Payment_method
),
lowest_payment AS (
    SELECT Payment_method, avg_fare
    FROM payment_stats
    ORDER BY avg_fare ASC
    LIMIT 1
)
SELECT 
    r.Payment_method,
    ROUND(AVG(r.Booking_value), 2) AS avg_fare,
    SUM(CASE WHEN r.Ride_distance <= 5 THEN 1 ELSE 0 END) AS short_rides,
    SUM(CASE WHEN r.Ride_distance > 5 THEN 1 ELSE 0 END) AS long_rides
FROM ncr_ride_bookings r
JOIN lowest_payment lp ON r.Payment_method = lp.Payment_method
WHERE r.booking_status = 'Completed'
GROUP BY r.Payment_method;

#Can we identify high-value customers (based on lifetime revenue) and analyze their booking behavior, payment preference, and ride distance trends?
# High Value Customers
WITH customer_revenue AS (
    SELECT 
        Customer_ID,
        SUM(Booking_value) AS lifetime_revenue,
        COUNT(*) AS total_rides
    FROM ncr_ride_bookings
    WHERE booking_status = 'Completed'
    GROUP BY Customer_ID
)
SELECT *
FROM customer_revenue
ORDER BY lifetime_revenue DESC
LIMIT 10;   

# Payment Preference
SELECT 
    Customer_ID,
    Payment_method,
    COUNT(*) AS rides,
    ROUND(SUM(Booking_value),2) AS total_spent
FROM ncr_ride_bookings
WHERE booking_status = 'Completed'
  AND Customer_ID IN (
        SELECT Customer_ID
        FROM (
            SELECT Customer_ID, SUM(Booking_value) AS lifetime_revenue
            FROM ncr_ride_bookings
            WHERE booking_status = 'Completed'
            GROUP BY Customer_ID
            ORDER BY lifetime_revenue DESC
            LIMIT 10
        ) AS top_customers
  )
GROUP BY Customer_ID, Payment_method
ORDER BY total_spent DESC;

#Ride distance travels
SELECT 
    Customer_ID,
    ROUND(AVG(Ride_distance), 2) AS avg_distance,
    MAX(Ride_distance) AS max_distance,
    MIN(Ride_distance) AS min_distance
FROM ncr_ride_bookings
WHERE booking_status = 'Completed'
  AND Customer_ID IN (
        SELECT Customer_ID
        FROM (
            SELECT Customer_ID, SUM(Booking_value) AS lifetime_revenue
            FROM ncr_ride_bookings
            WHERE booking_status = 'Completed'
            GROUP BY Customer_ID
            ORDER BY lifetime_revenue DESC
            LIMIT 10
        ) AS top_customers
  )
GROUP BY Customer_ID
ORDER BY avg_distance DESC;

#Booking behaviour
SELECT 
    Customer_ID,
    DATE_FORMAT(str_to_date(Date, '%d-%m-%y'), '%Y-%M') AS month,
    COUNT(*) AS rides,
    SUM(Booking_value) AS monthly_spent
FROM ncr_ride_bookings
WHERE booking_status = 'Completed'
  AND Customer_ID IN (
        SELECT Customer_ID
        FROM (
            SELECT Customer_ID, SUM(Booking_value) AS lifetime_revenue
            FROM ncr_ride_bookings
            WHERE booking_status = 'Completed'
            GROUP BY Customer_ID
            ORDER BY lifetime_revenue DESC
            LIMIT 10
        ) AS top_customers
  )
GROUP BY Customer_ID, DATE_FORMAT(str_to_date(Date, '%d-%m-%y'), '%Y-%M') 
ORDER BY Customer_ID, month;






      
      
       












