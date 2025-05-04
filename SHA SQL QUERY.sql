create database Socialhealth_insurance
use Socialhealth_insurance


alter Table Contributions
add constraint fk_MemberContribution 
Foreign Key (member_id) references Members(member_id)


alter Table Healthcare_Services
add constraint fk_Memberservice
Foreign Key (member_id) references Members(member_id)

alter Table Healthcare_Services
add constraint fk_providerservice
Foreign Key (provider_id) references Providers(provider_id)

alter Table Surveys
add constraint fk_Membersurveys
Foreign Key (member_id) references Members(member_id)


alter Table claims
add constraint fk_providerclaims
Foreign Key (provider_id) references Providers(provider_id)

alter Table claims
add constraint fk_serviceclaims
Foreign Key (service_id) references Healthcare_services(service_id)

-------------------------- What is the distribution of members by income level and employment status?
SELECT 
    employment_status,
    income_level,
    COUNT(*) AS member_count
FROM 
    Members
GROUP BY 
    employment_status, income_level
ORDER BY 
    employment_status, income_level;



	WITH IncomeEmploymentDistribution AS (
    SELECT
        income_level,
        employment_status,
        COUNT(*) AS member_count
    FROM
        members
    WHERE
        income_level IN ('high', 'middle', 'low')
        AND employment_status IN ('Employed', 'Unemployed', 'Self-Employed')
    GROUP BY
        income_level,
        employment_status
)

SELECT
    income_level,
    employment_status,
    member_count,
    RANK() OVER (PARTITION BY income_level ORDER BY member_count DESC) AS rank_within_income
FROM
    IncomeEmploymentDistribution
ORDER BY
    income_level,
    rank_within_income;

------------------------------ How many members are subsidized versus non-subsidized across different regions?

SELECT 
    region,
    CASE 
        WHEN is_subsidized = 1 THEN 'True'
        ELSE 'False'
    END AS Is_subsidized,
    COUNT(*) AS countmembers
FROM 
    Members
GROUP BY 
    region,
    CASE 
        WHEN is_subsidized = 1 THEN 'True'
        ELSE 'False'
    END
	order by 
	region;

--------------------------- What is the average age of members by region? (Use CTEs)

 WITH  average_age as(
 select 
 region,
 AVG(age) AS average_age from Members
 group by region 

 )

 select * from average_age
  order by region


--------------------------- Calculate the total contributions received monthly. (Use Temp Tables)

select 
FORMAT(contribution_date, 'MM') as Month,
sum(contribution_amount) as total_contribution
into #Month_TotalContributions
 FROM Contributions
 group by FORMAT(contribution_date, 'MM') 
 order by Month


 

 select * from #Month_TotalContributions



 WITH Monthy_contribution as(
 select 
FORMAT(contribution_date, 'MMMM') as Month,
sum(contribution_amount) as total_contribution
 FROM Contributions
 group by FORMAT(contribution_date, 'MMMM') 
 )

 select * from Monthy_contribution


 ----------------------- Identify members who have penalties greater than 100 KES.
 select 
 m.full_name,
 m.member_id,
 sum(Round(c.penalty_applied,2)) as penalty
 from Members m
 join Contributions c
 on m.member_id=c.member_id
  where penalty_applied>100
 group by m.full_name,m.member_id
 order by m.full_name 


 ----------------------- Find the top 5 employers contributing the highest total amount.

----(Customers having more than 2 contributions )
 select employer_id,
 count(contribution_id) as Count_OF_contributions from Contributions
 group by employer_id
 having  count(contribution_id) >2


 ----------top 5 employers contributing the highest total amount.

 select  top 5 employer_id,
 sum(round(contribution_amount,2))as contribution_amonut,
 count(contribution_id) as Count_OF_contributions from Contributions
 group by employer_id
 order by  Count_OF_contributions desc



 ------Quiz 3...3. Healthcare Services Utilization:
 ------------(i) Which types of healthcare services are most utilized?

 select
 service_type,
 COUNT(member_id) as Members
from Healthcare_Services
group by service_type
order by Members desc

------------(ii) - Calculate the average out-of-pocket expenses per service type and region.

select 
h.service_type,
m.region,
Round(AVG(h.out_of_pocket),2) as out_of_pocket_expenses
 from Healthcare_Services h
 join Members m
 on h.member_id=m.member_id
 group by m.region,h.service_type
 order by out_of_pocket_expenses desc


 select
    h.service_type,
    p.region,
    avg(h.out_of_pocket) as avg_out_of_pocket
from healthcare_services h
join providers p
on h.provider_id = p.provider_id
group by h.service_type, p.region
order by avg_out_of_pocket desc;


----------------- Find members with the highest total healthcare costs but lowest coverage. (Use Subqueries)

select cost_total,
cost_covered,
round((cost_covered/cost_total)*100,0) as cost_coverage_percentage
from
Healthcare_Services
where round((cost_covered/cost_total)*100,0)=50


SELECT TOP 10
    hs.cost_total,
    hs.cost_covered
FROM (
    SELECT 
        cost_total,
        cost_covered,
        ROUND((cost_covered * 1.0 / cost_total) * 100, 0) AS cost_coverage_percentage
    FROM 
        Healthcare_Services
) AS hs
WHERE 
    hs.cost_coverage_percentage = 50
ORDER BY 
    hs.cost_total DESC;





	-----------Quiz 4  Provider Performance:
	----------------------- List providers with the highest number of services offered.
	select 
	p.provider_name,
	p.provider_id ,
	count (h.service_type) as  No_services_offered
	from Healthcare_Services h
	join Providers p
	on p.provider_id=h.provider_id
	group by p.provider_id ,p.provider_name
	order by No_services_offered desc




with P_last_2years_accredited as (
	select provider_id,
	provider_name
	accreditation_date
	from Providers
	where accreditation_date>=DATEADD(YEAR, -2, GETDATE())
	)
	select  
	c.provider_id,
	c.claim_status,
	count(c.claim_status)
	from P_last_2years_accredited p
	join Claims c
	on p.provider_id=c.provider_id
	group by c.provider_id,c.claim_status

	--------- Find providers accredited within the last 2 years and compare their claim approval rates.

	with RecentProviders as (
select provider_id
from providers
where accreditation_date >= dateadd(year, -2, getdate())
),
ClaimStats as (
select 
    c.provider_id,
    c.claim_status,
    count(*) as claim_count
from claims c
join RecentProviders r
on c.provider_id = r.provider_id
group by c.provider_id, c.claim_status
)
select 
    provider_id,
    sum(case when claim_status = 'Approved' then claim_count else 0 end) as approved,
    sum(claim_count) as total,
    round(sum(case when claim_status = 'Approved' then claim_count else 0 end) * 100.0 / sum(claim_count), 2) as approval_rate
from ClaimStats
group by provider_id;



----------5. Claims Analysis:
-------------- What is the total claim amount by claim status (Approved, Pending, Rejecte)
select
claim_status,
round(SUM(claim_amount),2) as total_claim_amount
from Claims
group by claim_status
order by total_claim_amount desc


--------- Identify discrepancies where claim amount does not match the covered amount for services.
select 
    c.claim_id,
    h.service_id,
    c.claim_amount,
    h.cost_covered
from claims c
join healthcare_services h
on c.service_id = h.service_id
where c.claim_amount <> h.cost_covered;


------6. Surveys and Sentiment Analysis:
------- What is the average satisfaction score by region?

--------------member satisfaction score by members from a certain region 

select 
m.region,
AVG(s.satisfaction_score) as avg_satisfactionscore
from Surveys s
join Members m
on s.member_id=m.member_id
group by m.region



--------------- Is there a correlation between trust levels and satisfaction scores? (Consider using CASE WHEN for categorization)
select
avg(satisfaction_score) as avg_satisfaction,
trust_category from (
select
satisfaction_score,
case 
when trust_level='medium' then 'Medium Trust_level'
when trust_level='High' then 'High Trust_level'
else 'Low Trust_level'
End as trust_category
from Surveys) as categorized
group by trust_category

-------7. Legal Risks:
-----How many legal cases are pending?

select 
status,
COUNT(status) as Count_status
 from Legal_Cases
 where status='pending'
 group by  status

 select count(*) as pending_cases
from legal_cases
where status = 'Pending';


---------- List legal cases by impact level and find the average filing duration from filing date to today.


select 
case_id,
impact_level,
AVG(datediff (day,filing_date,getdate ())) as avg_days_since_filling
from 
Legal_Cases
group by case_id,impact_level



---------Advanced Challenges:
-------- Create a member healthcare utilization profile (number of services, average costs, satisfaction level) using JOINs across multiple tables.

select 
m.member_id,
count(h.service_id) as No_of_services,
AVG(h.cost_total) as average_costs,
AVG(s.satisfaction_score) as avergae_satisafaction_level
from Members m
left  join Healthcare_Services h
on m.member_id=h.member_id
left join Surveys s
on h.member_id=s.member_id

group by m.member_id
order by m.member_id



- Using UNION, combine high penalty members and low satisfaction members into a 'high-risk' group.

select 
member_id,

'high penalty' as risk_reason
from Contributions
where penalty_applied >100

union  
select
member_id,
'Low satisfaction' as risk_reason
from Surveys
where satisfaction_score <3


select member_id, 'High Penalty' as risk_reason, avg(penalty_applied) as risk_value
from contributions
where penalty_applied > 100
group by member_id
union
select member_id, 'Low Satisfaction' as risk_reason, avg(Satisfaction_score) as risk_value 
from surveys
where satisfaction_score < 3
group by member_id

--------excel work queriries

-----(a) Distribution of members by income level
select 
income_level,
COUNT(member_id) as total_members
from members
group by income_level
order by total_members desc


------- (B)Stacked Column: Members by employment status or subsidy status across regions
select employment_status,is_subsidized,COUNT(member_id) as Total_membersfrom Membersgroup by employment_status,is_subsidizedorder by Total_members-----------------(c) Line Chart with Moving Average: Monthly contributions with trendselect
    format(contribution_date, 'MM') as Month,
    sum(contribution_amount) as total_contributions
from Contributions
group by format(contribution_date, 'MM');