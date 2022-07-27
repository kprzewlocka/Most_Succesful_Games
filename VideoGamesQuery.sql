-- Procedure to clean database
CREATE PROCEDURE cleaning_database
AS
-- Changing datatype Games_sold to float
ALTER TABLE dbo.game_sales
ALTER COLUMN Games_sold float;

-- Changing datatype Year to int
ALTER TABLE dbo.game_sales
ALTER COLUMN Year int;

-- Changing datatype Critic_Score to float
ALTER TABLE dbo.reviews
ALTER COLUMN Critic_Score float;

-- Changing datatype User_Score to float
ALTER TABLE dbo.reviews
ALTER COLUMN User_Score float;

--Change 0s to NULLs in reviews table
UPDATE dbo.reviews SET dbo.reviews.Critic_Score=NULL WHERE dbo.reviews.Critic_Score=0
UPDATE dbo.reviews SET dbo.reviews.User_Score=NULL WHERE dbo.reviews.User_Score=0

GO



-- All information for the top 10 best selling games 
SELECT top 10 * 
FROM dbo.game_sales
ORDER BY Games_sold desc;


-- Joining game_sales and reviews on Game column and selecting a count of the number of games where both critic_score and user_score are null
SELECT count(dbo.game_sales.Game)
FROM dbo.game_sales 
LEFT JOIN dbo.reviews on dbo.game_sales.Game = dbo.reviews.Name
WHERE dbo.reviews.Critic_Score is null and dbo.reviews.User_Score is null;

-------------------------CRITICS---------------------------------------

--Creating top_10_critics temp table
CREATE TABLE #top_10_critics(
	year int,
	avg_critic_score float 
);

-- Selecting top 10 best years based on average critics scores and inserting it into top_10_critics temp table
INSERT INTO #top_10_critics
SELECT top 10 dbo.game_sales.year, round(avg(dbo.reviews.Critic_Score),2) as avg_critic_score
FROM dbo.game_sales
INNER JOIN  dbo.reviews on dbo.game_sales.Game=dbo.reviews.Name
GROUP BY dbo.game_sales.year
ORDER BY  avg_critic_score desc;

-- Viewing top_10_critics temp table
SELECT *
FROM #top_10_critics

--Creating top_10_critics_more_games temp table
CREATE TABLE #top_10_critics_more_games(
	year int,
	avg_critic_score float, 
	num_games int
);

--Counting games released in "best" years and inserting it into top_10_critics_more_games temp table
INSERT INTO #top_10_critics_more_games
SELECT top 10 dbo.game_sales.year, round(avg(dbo.reviews.Critic_Score),2) as avg_critic_score, count(dbo.game_sales.Game) as num_games
FROM dbo.game_sales
INNER JOIN  dbo.reviews on dbo.game_sales.Game=dbo.reviews.Name
GROUP BY dbo.game_sales.year
HAVING count(dbo.game_sales.Game) > 4
ORDER BY  avg_critic_score desc;

-- Viewing top_10_critics_more_games temp table
SELECT *
FROM #top_10_critics_more_games

--Checking if any games dropped off favourites
SELECT year, avg_critic_score
FROM #top_10_critics
EXCEPT 
SELECT year, avg_critic_score
FROM #top_10_critics_more_games
ORDER BY avg_critic_score desc;

----------------USERS----------------------------------------

--Creating top_10_users_more_games temp table
CREATE TABLE #top_10_users_more_games(
	year int,
	avg_user_score float, 
	num_games int
);

--Counting games released in "best" years and inserting it into top_10_users_more_games temp table
INSERT INTO #top_10_users_more_games
SELECT top 10 dbo.game_sales.year, round(avg(dbo.reviews.User_Score),2) as avg_user_score, count(dbo.game_sales.Game) as num_games
FROM dbo.game_sales
INNER JOIN  dbo.reviews on dbo.game_sales.Game=dbo.reviews.Name
GROUP BY dbo.game_sales.year
HAVING count(dbo.game_sales.Game) > 4
ORDER BY  avg_user_score desc;

-- Viewing top_10_users_more_games temp table
SELECT *
FROM #top_10_users_more_games

-----------------------------------------------------------

-- Selecting games that appear on both #top_10_critics_more_games and #top_10_users_more_games temp tabels
WITH Succesful_games_CTE AS
(SELECT topuser.year as year, topuser.num_games, avg_user_score, avg_critic_score
FROM #top_10_users_more_games as topuser
INNER JOIN #top_10_critics_more_games as topcrit
ON topuser.year = topcrit.year)

-- Counting how many games were sold in these years 
SELECT year, sum(games_sold) as total_games_sold
FROM game_sales
GROUP BY year
HAVING year in (SELECT year
				FROM Succesful_games_CTE)
ORDER BY year
