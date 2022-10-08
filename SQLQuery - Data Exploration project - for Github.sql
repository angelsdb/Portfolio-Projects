--Data check for each tables 


SELECT * FROM Portfolio_project..CovidDeaths
ORDER BY 3,4


SELECT * FROM Portfolio_project..CovidVaccinations
ORDER BY 3,4



--Looking at total cases versus total deaths

--How many cases per country and how many deaths they have for their entire cases
--This shows the likelihood of dying if you contract covid in your country

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Portfolio_project..CovidDeaths
where location = 'United Kingdom' and where continent IS NOT NULL
order by 1, 2





--Looking at total cases versus total population
--Shows what percentage of population got infected with covid

Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from Portfolio_project..CovidDeaths
where location = 'United Kingdom' and where continent IS NOT NULL
order by 1, 2




--Looking at countries with the highest infection rates compared to population

Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from Portfolio_project..CovidDeaths
--where location = 'United Kingdom' and where continent IS NOT NULL
group by population, location
order by PercentPopulationInfected desc





--Showing countries with highest death count per population

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from Portfolio_project..CovidDeaths
--where location = 'United Kingdom'
where continent IS NOT NULL
group by location
order by TotalDeathCount desc


--Investigating location values under CovidDeaths table as part of Data exploration
--Based on my data checking, those that under continent NULL values is showing continent
--instead of countries under the location column and I do not want that data, so what 
--I need to do is make sure to remove anything NULL under the continent column


SELECT * FROM Portfolio_project..CovidDeaths
where continent IS NOT NULL
ORDER BY 3,4



--LETS BREAK THINGS DOWN BY CONTINENT

Select location from Portfolio_project..CovidDeaths
group by location
order by location desc


Correct query: column should be continent not location
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from Portfolio_project..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc



--Showing continents with highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from Portfolio_project..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc




-- GLOBAL NUMBERS

--Initial query:
Select 
date, 
SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
--,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Portfolio_project..CovidDeaths
where continent is not null
group by date
order by 1,2


--Second phase query for global numbers:
Select
SUM(new_cases) as total_cases, 
SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
--,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Portfolio_project..CovidDeaths
where continent is not null
--group by date
order by 1,2



--Checking at Vaccinations table:
Select * from Portfolio_project..CovidVaccinations


--Lets try to do some Joins! -- The below query are being joined based on:
---location
---date


Select * from Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date


--Looking at total population versus Vaccinations
--what are the total amount of people in the world that had been vaccinated
--columns used are population from deaths table and new_vaccinations per day column from vaccinations table

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
from Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3



--Applying a ROLLING COUNT BY USING PARTITION BY under the new_vaccinations column:


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as RollingcountPeopleVaccinated
from Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3



--Using the total sum from the rolling count of vaccinations PER COUNTRY
--e.g. Albania, total vaccinated people (last sum of rolling count) 1417691 to be divided by total population in Albania
--on the below query I tried addded in the following column:
--(RollingcountPeoplevaccinated/population)*100
--However, this did not work because I cannot use the column RollingcountPeoplevaccinated to use this as a column I need to do a CTE



Select dea.continent, 
dea.location, dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as RollingcountPeoplevaccinated,
(RollingcountPeoplevaccinated/population)*100
from Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3




-- USE CTE 

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingcountPeoplevaccinated)
as

(
Select dea.continent, 
dea.location, dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as RollingcountPeoplevaccinated
-- (RollingcountPeoplevaccinated/population)*100
from Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
Select *, (RollingcountPeoplevaccinated/population)*100 
from PopvsVac





-- TEMP TABLE
--Same exact effect as the CTE function above, but just want to showcase to apply it in a TEMP table function


DROP TABLE if exists #Percentpopvaccinated
Create table #Percentpopvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
Population bigint,
new_vaccinations bigint,
RollingcountPeoplevaccinated bigint
)


Insert into #Percentpopvaccinated
Select dea.continent, 
dea.location, dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as RollingcountPeoplevaccinated
from Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3

Select *
from #Percentpopvaccinated




-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION
-- USING VIEWS



Create view Percentpopvaccinated as
Select dea.continent, 
dea.location, dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) as RollingcountPeoplevaccinated
from Portfolio_project..CovidDeaths dea
join Portfolio_project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select * from Percentpopvaccinated 
