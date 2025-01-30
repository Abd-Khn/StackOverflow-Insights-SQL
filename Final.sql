-- PART 1: BASICS
-- 1. Loading and Exploring Data 
-- Explore the structure and first 10 rows of each table. 

DESC badges;
DESC comments;
DESC post_history;
DESC post_links;
DESC posts_answers;
DESC tags;
DESC users;
DESC votes;
DESC posts;

SELECT * FROM badges LIMIT 10;
SELECT * FROM comments LIMIT 10;
SELECT * FROM post_history LIMIT 10;
SELECT * FROM post_links LIMIT 10;
SELECT * FROM posts_answers LIMIT 10;
SELECT * FROM tags LIMIT 10;
SELECT * FROM users LIMIT 10;
SELECT * FROM votes LIMIT 10;
SELECT * FROM posts LIMIT 10;

-- Identify the total number of records in each table. 
SELECT 'badges' AS table_name, COUNT(*) AS total_records FROM badges
UNION ALL
SELECT 'comments', COUNT(*) FROM comments
UNION ALL
SELECT 'post_history', COUNT(*) FROM post_history
UNION ALL
SELECT 'post_links', COUNT(*) FROM post_links
UNION ALL
SELECT 'posts_answers', COUNT(*) FROM posts_answers
UNION ALL
SELECT 'tags', COUNT(*) FROM tags
UNION ALL
SELECT 'users', COUNT(*) FROM users
UNION ALL
SELECT 'votes', COUNT(*) FROM votes
UNION ALL
SELECT 'posts', COUNT(*) FROM posts;

-- 2. Filtering and Sorting 
-- Find all posts with a comment_count greater than 2 
SELECT 
	post_id,
    COUNT(*) AS comment_count
FROM 
	comments 
GROUP BY 
	post_id
HAVING
	comment_count > 2;

-- Display comments made in 2012, sorted by creation_date (comments table). 
SELECT
	*
FROM
	comments
WHERE
	YEAR(creation_date) = 2012
ORDER BY
	creation_date;

-- 3. Simple Aggregations 
-- Count the total number of badges (badges table). 
SELECT
    COUNT(DISTINCT name) AS number_of_badges
FROM
	badges;
    
-- Calculate the average score of posts grouped by post_type_id (posts_answer table). 
SELECT
	post_type_id,
	ROUND(AVG(score), 2) AS avg_score 
FROM 
	posts_answers
GROUP BY
	post_type_id;

-- ------------------------------------------------------------------------------------------------------

-- Part 2: Joins 
-- Combine the post_history and posts tables to display the title of posts and the corresponding changes made in the post history. 
SELECT
    p.title,
    ph.text
FROM
	posts as p
    JOIN post_history as ph
    ON p.id = ph.post_id;

-- Join the users table with badges to find the total badges earned by each user. 
SELECT
	u.display_name,
    u.id,
    COUNT(b.id) AS total_badges
FROM
	users as u
    LEFT JOIN badges as b
    ON u.id = b.user_id
GROUP BY
	u.id;
    
-- 2. Multi-Table Joins 
-- Fetch the titles of posts (posts), their comments (comments), and the users who made those comments (users). 
SELECT
	p.title,
    c.text,
    u.display_name AS commenters
FROM
	posts AS p
    JOIN comments AS c 
    ON p.id = c.post_id
    JOIN users AS u
    ON c.user_id = u.id; 

-- Combine post_links with posts to list related questions.
SELECT
	p1.title AS questions,
    p2.title AS related_questions
FROM
	post_links AS pl
    JOIN posts AS p1
    ON pl.post_id = p1.id
    JOIN posts AS p2
    ON pl.related_post_id = p2.id;
 
-- Join the users, badges, and comments tables to find the users who have earned badges and made comments.
SELECT
	u.display_name,
    COUNT(DISTINCT b.id) AS total_badges,
    COUNT(DISTINCT c.id) AS total_comments
FROM
	users AS u
    JOIN badges AS b
    ON u.id = b.user_id
    JOIN comments AS c
    ON u.id = c.user_id
GROUP BY
	u.id;
-- -----------------------------------------------------------------------------------------------------

-- Part 3: Subqueries
-- 1. Single-Row Subqueries
-- Find the user with the highest reputation (users table).
SELECT 
	*  
FROM 
	users  
WHERE 
	reputation = (SELECT MAX(reputation) FROM users);

-- Retrieve posts with the highest score in each post_type_id (posts table).
SELECT 
	*  
FROM 
	posts AS p  
WHERE 
	score = (  
			SELECT MAX(score)  
			FROM posts  
			WHERE post_type_id = p.post_type_id);
            
-- 2. Correlated Subqueries
-- For each post, fetch the number of related posts from post_links.
SELECT 
	p.id, 
	p.title,  
	(SELECT COUNT(*) 
    FROM post_links AS pl 
    WHERE pl.post_id = p.id) AS related_posts 
FROM 
	posts AS p;
-- -----------------------------------------------------------------------------------------------------
    
-- Part 4: Common Table Expressions (CTEs)
-- 1. Non-Recursive CTE
-- Create a CTE to calculate the average score of posts by each user and use it to:
-- ■ List users with an average score above 50.
-- ■ Rank users based on their average post score.

WITH UserAvgScore AS (  
    SELECT 
		owner_user_id, 
        ROUND(AVG(score), 2) AS avg_score  
    FROM 
		posts  
    GROUP BY 
		owner_user_id  
)  
SELECT 
	owner_user_id, 
    avg_score,  
	RANK() OVER (ORDER BY avg_score DESC) AS `rank`  
FROM 
	UserAvgScore
WHERE
	avg_score > 50;
    
-- Recursive CTE
-- Simulate a hierarchy of linked posts using the post_links table.
WITH RECURSIVE PostHierarchy AS (  
    SELECT 
		
		post_id AS root_post, 
        related_post_id, 
        1 AS level  
    FROM 
		post_links  
      
    UNION ALL  

    SELECT 
		ph.root_post, 
        pl.related_post_id, 
        ph.level + 1  
    FROM 
		PostHierarchy ph  
    JOIN 
		post_links pl ON ph.related_post_id = pl.post_id  
    WHERE 
		ph.level < 3    
)  
SELECT * FROM PostHierarchy;

-- -----------------------------------------------------------------------------------------------------
-- Part 5: Advanced Queries
-- 1. Window Functions
-- Rank posts based on their score within each year (posts table).
SELECT 
    id, 
    title,
    score, 
    YEAR(creation_date) AS post_year,
    RANK() OVER (PARTITION BY YEAR(creation_date) ORDER BY score DESC) AS `rank`  
FROM posts;
SELECT * FROM posts;

-- Calculate the running total of badges earned by users (badges table).
SELECT
    id,
    user_id,
    name AS badge_name,
    date,
    SUM(1) OVER (PARTITION BY user_id ORDER BY date) AS running_total
FROM
    badges
ORDER BY
    user_id, date;


-- -----------------------------------------------------------------------------------------------------------------------
-- NEW INSIGHTS AND QUESTIONS
-- Which users have contributed the most in terms of comments, edits, and votes?
SELECT 
    u.display_name,
    COUNT(DISTINCT c.id) AS total_comments,
    COUNT(DISTINCT ph.id) AS total_edits,
    COUNT(DISTINCT v.id) AS total_votes
FROM 
    users u
    LEFT JOIN comments AS c 
    ON u.id = c.user_id
    
    LEFT JOIN post_history AS ph 
    ON u.id = ph.user_id 
    
    LEFT JOIN posts AS p 
    ON u.id = p.owner_user_id 
    
    LEFT JOIN votes AS v 
    ON p.id = v.post_id
GROUP BY 
	u.id
ORDER BY 
    total_comments DESC, total_edits DESC, total_votes DESC;

-- What types of badges are most commonly earned, and which users are the top earners?
SELECT 
    b.name AS badge_name,
    COUNT(b.id) AS badge_count,
    u.display_name AS top_earner,
    COUNT(b.id) AS badges_earned
FROM 
    badges b
    JOIN users u ON b.user_id = u.id
GROUP BY 
    b.name, u.display_name
ORDER BY 
    badge_count DESC, badges_earned DESC;
    
-- Which tags are associated with the highest-scoring posts?

WITH HighestScoringPosts AS (
    SELECT
        id,
        score
    FROM posts
    ORDER BY score DESC
    LIMIT 1
)
SELECT
    t.tag_name,
    p.score
FROM
    tags t
JOIN posts p ON p.owner_user_id = t.id
WHERE p.score = (SELECT MAX(score) FROM HighestScoringPosts);


-- How often are related questions linked, and what does this say about knowledge sharing?
SELECT 
    COUNT(*) AS total_related_links,
    COUNT(DISTINCT post_id) AS total_posts_linked,
    COUNT(DISTINCT related_post_id) AS total_related_questions
FROM 
    post_links;
    

    