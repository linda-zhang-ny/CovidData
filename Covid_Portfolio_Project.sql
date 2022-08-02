/*
Covid-19 Data

Skills Used: Join, Converting Data Types, Creating Views, Aggregate Functions, Windows Functions, Temp Tables, CTE's

August 2022
*/
select *
from portfolioproject..CovidDeaths
where continent is not null
order by 3, 4


--select the data that we are going to be using

SELECT location, date, total_cases,new_cases,total_deaths,population
from portfolioproject..CovidDeaths
where continent is not null
order by 1,2

--Total Cases vs Total Deaths
--Shows liklihood of dying in United States if you got covid
SELECT location, date, total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from portfolioproject..CovidDeaths
where location = 'United States' 
AND continent is not null
order by 1,2

--Total Cases vs Population
--shows what percentage of population got covid
SELECT location, date, population, total_cases,(total_cases/population)*100 as DeathPercentage
from portfolioproject..CovidDeaths
where location = 'United States'
AND continent is not null
order by 1,2

--Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM portfolioproject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY 4 DESC

--Countries with the Highest Death Rate compared to Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM portfolioproject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY 2 DESC


--Group by Continent
--showing continents with highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM portfolioproject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers
Select SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM portfolioproject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


--Total Population vs Vaccinations
--Shows percentage of population that got a vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccines vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


--Using CTE to perform calculation on Partition by in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null 
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac
ORDER BY 2,3


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


--creating view to store for visualiztaions
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccines vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 