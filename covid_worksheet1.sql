Use COVID

--Number of columns in each table:
SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE table_catalog = 'COVID' -- database
   AND table_name = 'coviddeaths' -- table name --26 columns in this table

SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE table_catalog = 'COVID' -- database
   AND table_name = 'covidvaccination' -- table name --45 columns in this table

SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE table_catalog = 'COVID' -- database
   AND table_name = 'owid-covid-data' -- table name --67 columns in this table

--printing common columns in the 2 subtables 
SELECT name 
FROM sys.columns 
WHERE object_id IN (object_id('dbo.coviddeaths'),
                    object_id('dbo.covidvaccination'))
GROUP BY name
HAVING COUNT(*) = 2 --4 common columns - continent, date, iso_code, location

--Let's do some exploratory analysis

--selecting a few of the columns that we will be interested in from the whole dataset. 
select continent, location, date, population, total_cases, total_deaths
from coviddeaths
order by location asc;

--calculate percentage of death compared to the total cases
Select Location, date, total_cases,total_deaths, cast(total_deaths as float) / nullif(cast(total_cases as float),0) * 100 as DeathPercentage
From coviddeaths
order by location

--calculate percentage of death compared to the total cases for a specific country(example: United States)
Select Location, date, total_cases,total_deaths, cast(total_deaths as float) / nullif(cast(total_cases as float),0) * 100 as DeathPercentage
From coviddeaths
where location = 'United States'

--calculate percentage of death compared to the total cases for a specific country(example: United States - method 2)
Select Location, date, total_cases,total_deaths, cast(total_deaths as float) / nullif(cast(total_cases as float),0) * 100 as DeathPercentage
From coviddeaths
where location like '%states%'

--Likewise, total cases when compared to the total population, rounded to 4 decimal points. 
Select Location, date, total_cases,population, Round(cast(total_cases as float) / nullif(cast(population as float),0) * 100, 4)  as InfectionRate
From coviddeaths
order by location

--Total deaths when compared to the total population, rounded to 4 decimal points. 
Select Location, date, total_deaths,population, Round(cast(total_deaths as float) / nullif(cast(population as float),0) * 100, 4)  as MoratlityRate
From coviddeaths
order by location

----Positivity rate (total number of positive test results / total number of both positive and negative test results)
Select Location, date, new_tests_smoothed, new_cases_smoothed, cast(new_cases_smoothed as float) / nullif(cast(new_tests_smoothed as float),0) * 100  as positivityRate --, positive_rate
From dbo.[owid-covid-data]
where location = 'United States'
order by location

--vaccination 
select location, date, people_vaccinated,people_fully_vaccinated,total_boosters
from covidvaccination
order by location

--fully vaccinated per total population 
Select Location, date, people_fully_vaccinated, population, cast(people_fully_vaccinated as float) / nullif(cast(population as float),0) * 100 as VaccinatedPopulation
From dbo.[owid-covid-data]
--where location = 'United States'
order by location
 
--Locations(countries) with Highest infection rate including continent details 
Select Location, Population, MAX(cast(total_cases as float)) as HighestInfectionCount,  max((cast(total_cases as float)) / nullif(cast(population as float),0)) * 100 as PercentPopulationInfected
From coviddeaths
Group by Location, Population
order by PercentPopulationInfected desc

--Locations(countries) with Highest infection rate without the rows that contain continents details
Select date, Location, Population, MAX(cast(total_cases as float)) as HighestInfectionCount,  max((cast(total_cases as float)) / nullif(cast(population as float),0)) * 100 as PercentPopulationInfected
From coviddeaths
where continent !=  ' ' 
Group by date, Location, Population
order by date asc

--Locations(countries) with Highest deaths 
Select Location, population, MAX(cast(Total_deaths as int)) as TotalDeathCount
From coviddeaths
where continent !=  ' ' and location not like '%income%' and location not like '%international%'
Group by Location, population
order by TotalDeathCount desc


--continent wise data along with income based categories 
Select location, population, MAX(cast(Total_deaths as int)) as TotalDeathCount
From coviddeaths
Where continent =  ' ' and location != 'world'
Group by population, location
order by TotalDeathCount desc

--continent wise data
--location, population, total deaths,vaccinated population 
Select location, population, MAX(cast(Total_deaths as float)) as TotalDeathCount, SUM(distinct(cast(new_people_vaccinated_smoothed as float))) / SUM(distinct(cast(population as float))) *100 as VaccinatedPopulation
From dbo.[owid-covid-data]
Where continent =  ' ' and location not like '%income%' and location not like '%international%' and location != 'world'
Group by population, location
order by TotalDeathCount desc

--location, population, total cases, total deaths,vaccinated population 
Select location, population, MAX(cast(total_cases as float)) as TotalcasesCount, MAX(cast(Total_deaths as float)) as TotalDeathCount, SUM(distinct(cast(new_people_vaccinated_smoothed as float))) / SUM(distinct(cast(population as float))) *100 as VaccinatedPopulation
From dbo.[owid-covid-data]
Where continent =  ' ' and location not like '%income%' and location not like '%international%' and location != 'world'
Group by population, location
order by TotalDeathCount desc


--To print out the continents
Select distinct(location)
From coviddeaths
Where continent =  ' ' and location not like '%income%' and location not like '%international%' and location != 'world'

--World data

--population of the world 
select SUM(distinct(cast(population as float))) as total_population
from coviddeaths
where continent =  ' '  and location = 'world' 

--income based location categories 
select location, SUM(distinct(cast(population as float))) as total_population
from coviddeaths
where location like '%income%'
group by location

--deathVsCases
select SUM(distinct(cast(population as float))) as total_population, SUM(cast(new_deaths as float)) as total_deaths, SUM(cast(New_Cases as float)) as Total_cases, SUM(cast(new_deaths as float))/SUM(cast(New_Cases as float)) as deathVScases
from coviddeaths
where continent =  ' '  and location = 'world'

--deathVspopulation
select SUM(distinct(cast(population as float))) as total_population, SUM(cast(new_deaths as float)) as total_deaths, SUM(cast(new_deaths as float)) / SUM(distinct(cast(population as float))) as Percentage_dead
from coviddeaths
where continent =  ' '  and location = 'world'

--world complete : incidence rate = cases/population. fatality rate: death/cases
select SUM(distinct(cast(population as float))) as total_population, SUM(cast(New_Cases as float)) as Total_cases, SUM(cast(new_deaths as float)) as total_deaths,  SUM(cast(New_Cases as float))/SUM(distinct(cast(population as float))) as Incidence_rate
	,SUM(cast(new_deaths as float))/SUM(cast(New_Cases as float)) as Fatality_rate,SUM(distinct(cast(new_people_vaccinated_smoothed as float))) as people_vaccinated
	, SUM(distinct(cast(new_people_vaccinated_smoothed as float))) / SUM(distinct(cast(population as float))) *100 as VaccinatedPopulation
from dbo.[owid-covid-data]
where continent =  ' '  and location = 'world'




--world vaccination
Select SUM(distinct(cast(population as float))) as total_population, SUM(distinct(cast(new_people_vaccinated_smoothed as float))) as people_vaccinated, SUM(distinct(cast(new_people_vaccinated_smoothed as float))) / SUM(distinct(cast(population as float))) *100 as VaccinatedPopulation
From dbo.[owid-covid-data]
where continent =  ' '  and location = 'world'

--vaccination data, location wise, using Common Table Expression
With VaccinatedPopulation (Continent, Location, Date, Population, New_Vaccinations, Cum_PeopleVaccinated)
as
(
Select continent, location, date, population, new_vaccinations
, SUM(CONVERT(float,new_vaccinations)) OVER (Partition by Location Order by Location, Date) as Cum_PeopleVaccinated
From dbo.[owid-covid-data]
where continent is not null 
)
Select *, (Cum_PeopleVaccinated / nullif(cast(Population as float),0)) as Percentage_vaccinated
From VaccinatedPopulation
