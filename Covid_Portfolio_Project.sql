--SELECT *
--FROM PortfolioProject..Covid_Deaths
--ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..Covid_Vaccinations
--ORDER BY 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..Covid_Deaths
ORDER BY 1,2

--Total cases vs total deaths, likelihood of dying if covid-19 is contracted
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProject..Covid_Deaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY 1,2

--percentage of population that has contracted covid-19
SELECT location, date, total_cases, population, (total_cases/population)*100 AS infected_percentage
FROM PortfolioProject..Covid_Deaths
WHERE location LIKE '%states%' AND continent IS NOT NULL

ORDER BY 1,2

--Countries with highest infection rate relative to population
SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC


--countries with highest death count per population
SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

--contintents with highest death count
SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC


-- global
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 AS death_percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--total population relative to vaccinated population
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccianted,
FROM PortfolioProject..Covid_Deaths dea
JOIN PortfolioProject..Covid_Vaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccianted)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccianted
FROM PortfolioProject..Covid_Deaths dea
JOIN PortfolioProject..Covid_Vaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccianted/population) * 100
FROM PopVsVac


--Temp Table
DROP Table if exists #percentpopulationvaccinated
Create Table #percentpopulationvaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rollingpeoplevaccinated
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rollingpeoplevaccinated
From PortfolioProject..Covid_Deaths dea
Join PortfolioProject..Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL