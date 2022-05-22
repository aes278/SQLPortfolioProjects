SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3, 4;

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY 3, 4;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'

SELECT COUNT(COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidDeaths'

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidVaccinations'

SELECT COUNT(COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidVaccinations'

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS 'Total Deaths:Total Cases' 
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS 'Total Deaths:Total Cases' 
FROM PortfolioProject..CovidDeaths
WHERE location = 'Nigeria'
ORDER BY 1, 2

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS 'Total Deaths:Total Cases' 
FROM PortfolioProject..CovidDeaths
WHERE location like '%state%'
ORDER BY 1, 2

-- Looking at Total Cases vs Population

SELECT location, date, population, total_cases, total_deaths, (total_cases / population) * 100 AS 'Total Cases:population' 
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

SELECT location, date, population, total_cases, total_deaths, (total_cases / population) * 100 AS 'Total Cases:population' 
FROM PortfolioProject..CovidDeaths
WHERE location = 'Nigeria'
ORDER BY 1, 2

SELECT location, date, population, total_cases, total_deaths, (total_cases / population) * 100 AS 'Total Cases:population' 
FROM PortfolioProject..CovidDeaths
WHERE Continent = 'Africa'
ORDER BY 1, 2

-- Looking at Countries with higher infection rates

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population) * 100) AS PercentageInfectedPopulation 
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentageInfectedPopulation DESC;


-- Showingat Countries & CONTINENTS with higher Death Count

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- This is not including Canada in North America
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- This is the correct query because it included Canada in North America
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS  NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- This query exclude the world entry that was included in the earlier query
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location <> 'World'
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- GLOBAL QUERIES 
SELECT SUM(CAST(new_deaths AS INT)) AS TotalGlobalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS INT)) AS TotalGlobalDeathCount, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 PercentageDeath
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL


-- Another Table (Vaccinations)
SELECT *
FROM PortfolioProject..CovidVaccinations

-- Join Both Tables

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
FROM PortfolioProject..CovidVaccinations AS Vac
JOIN PortfolioProject.dbo.CovidDeaths Dea
	ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL
ORDER BY 2, 3;

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(INT,Vac.new_vaccinations)) OVER(PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidVaccinations AS Vac
JOIN PortfolioProject.dbo.CovidDeaths Dea
	ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL
ORDER BY 2, 3;

--Using CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
AS
(SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(INT,Vac.new_vaccinations)) OVER(PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidVaccinations AS Vac
JOIN PortfolioProject.dbo.CovidDeaths Dea
	ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS VaccinatedVsPopulation
FROM PopvsVac

---USING TERM TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(225),
LOCATION NVARCHAR(225),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated Numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(INT,Vac.new_vaccinations)) OVER(PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidVaccinations AS Vac
JOIN PortfolioProject.dbo.CovidDeaths Dea
	ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS VaccinatedVsPopulation
FROM #PercentPopulationVaccinated

-- Creating View To Store Data For Later Visualization
CREATE VIEW PercentPopulationVaccinated AS 
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(INT,Vac.new_vaccinations)) OVER(PARTITION BY Dea.location ORDER BY Dea.location, Dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidVaccinations AS Vac
JOIN PortfolioProject.dbo.CovidDeaths Dea
	ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated