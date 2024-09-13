select *
from portfolioproject_database..CovidDeaths
UPDATE portfolioproject_database..CovidDeaths
SET continent = NULL WHERE continent = ''
UPDATE portfolioproject_database..CovidDeaths
set new_cases = NULL WHERE new_cases = ''
UPDATE portfolioproject_database..CovidDeaths
set new_deaths = NULL WHERE new_deaths = ''
--order by 3,4
order by new_deaths
--select *
--from portfolioproject_database..Covidvaccinations
--order by 3,4

--selecting required variables
--Total cases Vs Total deaths
--likelyhood of dying once you contract covid in united states
select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 as death_precentage
from portfolioproject_database..CovidDeaths
where location like '%states%'
order by 1, 2
-- There is a % chance of dying if you contract Covid

--% of population contracted covid
select location, date, total_cases, total_deaths, population, (CONVERT(float, total_cases)/population) * 100 as precentage_covid
from portfolioproject_database..CovidDeaths
where location like '%states%'
order by 1, 2
-- Inference: Between January 2020 and April 2021, 3 - 9 % of the population contracted covid

--identifying countries with highest covid infection rate
select location, MAX(total_cases) as highestcovidcount,  population, (MAX(CONVERT(float, total_cases))/NULLIF(CONVERT(float, population), 0)) * 100 as max_percent_populationinfected
from portfolioproject_database..CovidDeaths
--where location like '%states%'
group by location, population
order by max_percent_populationinfected desc
--Inference: Highest covid infection rate is associated with the country Andorra at 17 % and lowest with Tanzania at 0.0009%
order by location
--INference: In Canda we have 3.25% of total population that had been infected with Covid

--Countries with highest death count
select location, MAX(cast(total_deaths as int)) as highestdeathcount
from portfolioproject_database..CovidDeaths
where continent is not null
group by location
order by highestdeathcount desc
--Inference: United staes has highes tdeath count at 576232

--Daily Death percentage of the infected covid cases across the world
select date, SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(NULLIF(CONVERT(float, new_deaths), 0))/SUM(NULLIF(CONVERT(float, new_cases), 0))*100 as percentageglobaldeath
from portfolioproject_database..CovidDeaths
where continent is not null
group by date
order by percentageglobaldeath
--Inference: Daily death percentage varied between 0.33% -  28.4%

--Daily Increment in Percentage of total vaccitaned individuals per country
select dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER(partition by dea.location Order by dea.location, dea.date) as rollingvaccinationnumber
from portfolioproject_database..CovidDeaths dea
join portfolioproject_database..Covidvaccinations vac
 on dea.location=vac.location
 and dea.date=vac.date
 where dea.continent is not null
 order by dea.location, dea.date


--Daily Increment in Percentage of total vaccitaned individuals per country
--Using CTE
with popvacc (continent, location, date, population, new_vaccinations, rollingvaccinationnumber)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER(partition by dea.location Order by dea.location, dea.date) as rollingvaccinationnumber
from portfolioproject_database..CovidDeaths dea
join portfolioproject_database..Covidvaccinations vac
 on dea.location=vac.location
 and dea.date=vac.date
 where dea.continent is not null
)
select *, (rollingvaccinationnumber/NULLIF(CONVERT(float, population), 0))*100 as percentagevaccinated  from popvacc

--Using temp table to generate a separate table for the above selected items
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations float,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
from portfolioproject_database..CovidDeaths dea
join portfolioproject_database..Covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/NULLIF(CONVERT(float, population), 0))*100 as percentagevaccinated
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated_1 as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
from portfolioproject_database..CovidDeaths dea
join portfolioproject_database..Covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select * from PercentPopulationVaccinated_1 
