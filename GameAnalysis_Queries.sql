use game_analysis;

alter table level_details2
rename column TimeStamp to start_datetime;


alter table level_details2
modify Dev_ID varchar(10);

alter table level_details2
modify Difficulty varchar(15);

alter table level_details2 add primary key(P_ID,Dev_ID,start_datetime);

alter table player_details modify L1_Status int;
alter table player_details modify L2_Status int;
alter table player_details modify L1_Code varchar(30);
alter table player_details modify L2_Code varchar(30);
alter table player_details modify PName varchar(30);
alter table player_details modify P_ID int primary key;


select * from player_details

select * from level_details2

-- 1. Extract `P_ID`, `Dev_ID`, `PName`, and `Difficulty_level` of all players at Level 0.

select ld.P_ID,Dev_ID, PName, Difficulty 
from level_details2 as ld
inner join player_details as pd on ld.P_ID = pd.P_ID
where ld.Level = 0;

-- 2) Find `Level1_code`wise average `Kill_Count` where `lives_earned` is 2, and at least 3
stages are crossed.

select L1_Code, avg(Kill_Count) as Avg_kill_count
from level_details2 as ld
inner join player_details as pd on ld.P_ID = pd.P_ID
where Lives_Earned = 2 and Stages_crossed >= 3
Group by L1_Code
Order by Avg_kill_count desc;

-- 3) Find the total number of stages crossed at each difficulty level for Level 2 with players
using `zm_series` devices. Arrange the result in decreasing order of the total number of
stages crossed.

select  sum(Stages_Crossed) as Total_Stages_Crossed,Difficulty, Dev_ID
from level_details2 as ld
inner join player_details as pd on ld.P_ID = pd.P_ID
where Level = 2 AND Dev_ID like "zm%"
Group by Difficulty,Dev_ID
Order by Total_Stages_Crossed desc;

-- Q4) Extract `P_ID` and the total number of unique dates for those players who have
 played games on multiple days.
 
select ld.P_ID, count(distinct date(start_datetime)) as Total_Unique_dates
from level_details2 as ld
inner join player_details as pd on ld.P_ID = pd.P_ID 
Group by ld.P_ID
Having count(distinct date(start_datetime)) >1;

-- Q5) Find `P_ID` and levelwise sum of `kill_counts` where `kill_count` is greater than 
the average kill count for Medium difficulty. 

select ld.P_ID, ld.Level,Sum(Kill_Count) as Total_kill_Counts 
from level_details2 as ld
inner join player_details as pd on ld.P_ID = pd.P_ID 
where  Difficulty = "Medium"
Group by ld.P_ID,ld.Level
Having SUM(Kill_Count) > AVG(Kill_Count)

-- 6) Find `Level` and its corresponding `Level_code`wise sum of lives earned, excluding Level
0. Arrange in ascending order of level.

Select ld.Level, pd.L1_Code, SUM(Lives_Earned) as Total_Leaves_Earned
from level_details2 as ld
inner join player_details as pd on ld.P_ID = pd.P_ID 
where ld.Level > 0
Group by ld.Level,pd.L1_Code
order by ld.Level asc;

--7) Find the top 3 scores based on each `Dev_ID` and rank them in increasing order using
`Row_Number`. Display the difficulty as well.


with RankedScored as (
	select *, row_number() over(partition by Dev_ID order by Score Desc) as ScoreRank
    from level_details2
)
select Dev_ID,Difficulty,Score,ScoreRank
from RankedScored
where ScoreRank <=3;

-- 8) Find the `first_login` datetime for each device ID.

select Dev_ID,MIN(start_datetime) as first_login
from level_details2
group by Dev_ID

-- 9) Find the top 5 scores based on each difficulty level and rank them in increasing order
using `Rank`. Display `Dev_ID` as well.

with RankedScore as (
	Select *, 
     rank() over(partition by Difficulty order by Score desc) as ScoreRank
    from level_details2
)
select Dev_ID, Difficulty, Score, ScoreRank
from RankedScore
where ScoreRank <= 5;

-- 10) Find the device ID that is first logged in (based on `start_datetime`) for each player
(`P_ID`). Output should contain player ID, device ID, and first login datetime.

select pd.P_ID, Dev_ID, MIN(start_datetime) as First_login_time
from level_details2 ld
inner join player_details pd on ld.P_ID = pd.P_ID
group by pd.P_ID, Dev_ID;

-- 11) For each player and date, determine how many `kill_counts` were played by the player
so far.
a) Using window functions

select P_ID, Date(start_datetime) as date, sum(kill_count)
over(partition by P_ID order by start_datetime) as Total_KillCounts
from level_details2;


b) Without window functions


select P_ID, Date(start_datetime) as date, sum(kill_count) as Total_killcounts
from level_details2 
Group by P_ID,Date(start_datetime);

-- 12) Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`,
excluding the most recent `start_datetime`.

select P_ID, Stages_crossed, start_datetime,
sum(Stages_crossed) over(partition by P_ID 
					order by start_datetime Rows between unbounded 
                    preceding and 1 preceding) as Cumulative_Sum
from level_details2;

-- 13) Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

select Dev_ID, P_ID, sum(score) as TOtal_Score
from level_details2
group by Dev_ID, P_ID
order by TOtal_Score desc
Limit 3;

-- 14. Find players who scored more than 50% of the average score, scored by the sum of
scores for each `P_ID`.

select P_ID, Sum(Score) as Total_score, Avg(Score) as Average_Score,
(Avg(Score) * 0.5) as FiftyPercentAvg
from level_details2
group by P_ID
having Avg(score) < sum(score);




-- 15. Create a stored procedure to find the top `n` `headshots_count` based on each `Dev_ID`
and rank them in increasing order using `Row_Number`. Display the difficulty as well.
DELIMITER //
CREATE PROCEDURE GetTopHeadshots(IN n INT)
BEGIN
    SELECT Dev_ID, Headshots_Count, difficulty
    FROM (
        SELECT Dev_ID, P_ID, Headshots_Count, difficulty,
               ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Headshots_Count) AS Ranked
        FROM level_details2
    ) AS pro
    WHERE Ranked <= n;
END //
DELIMITER ;
call GetTopHeadshots(5);