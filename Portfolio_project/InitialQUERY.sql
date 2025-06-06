select *
from Portfolio..CovidDeaths
order by 3,4;


select *
from Portfolio..CovidVaccinations
order by 3,4;

select 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
from Portfolio..CovidDeaths
order by 1,2;

-- Looking at Total Cases vs Total Deaths

-- Shows likelihood of death in case of contraction of virus.
select 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	CAST(total_deaths as float)/CAST(total_cases as float)*100 as DeathPercentage
from Portfolio..CovidDeaths
where location like 'India' --looking for native country
order by 1,2;


-- Looking at the Total Cases vs Population

-- Shows what percentage of people have covid
select 
	location, 
	date, 
	total_cases, 
	population, 
	CAST(total_cases as float)/CAST(population as float) as ContractionPercentage
from Portfolio..CovidDeaths
where location like 'India' --looking for native country
order by 1,2;


-- Looking at countries with highest infection rate compared to population

select 
	location, 
	max(total_cases) as HighestInfectionCount, 
	population, 
	MAX(CAST(total_deaths as float)/CAST(total_cases as float))*100 as HighestInfectionRate
from Portfolio..CovidDeaths
where continent is not null
group by location, population
order by HighestInfectionRate desc;

-- Ordering by continent

select 
	continent, 
	max(total_deaths) as HighestDeathCount
from Portfolio..CovidDeaths
where continent is not null
group by continent
order by HighestDeathCount desc;

-- Gets more accurate as we do not remove the ones in the location column

select 
	location, 
	max(total_deaths) as HighestDeathCount
from Portfolio..CovidDeaths
where continent is null
group by location
order by HighestDeathCount desc;

-- Showing the countries with the highest death count per population

select 
	location, 
	max(total_deaths) as HighestDeathCount
from Portfolio..CovidDeaths
where continent is null
group by location
order by HighestDeathCount desc;


-- Global numbers all at once

select
	sum(new_cases) as total_cases, -- sum of all new cases add to total cases
	sum(new_deaths) as total_deaths,
	(sum(CAST(new_deaths as float))/sum(CAST(new_cases as float)))*100 as DeathPercentage
from Portfolio..CovidDeaths
where continent is not null
order by 1,2;


-- GLobal numbers date wise

select
	date,
	sum(new_cases) as total_cases, -- sum of all new cases add to total cases
	sum(new_deaths) as total_deaths,
	(sum(CAST(new_deaths as float))/sum(CAST(new_cases as float)))*100 as DeathPercentage
from Portfolio..CovidDeaths
where continent is not null
group by date
order by 1,2;


-- Joining the 2 tables

Select *
from Portfolio..CovidDeaths dea
join Portfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date;


-- Looking at total population vs vaccinations

select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as Rolling_people_vaccinated
from Portfolio..CovidDeaths dea
join Portfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3;


-- USE CTE(common table expressing)

with PopvsVac (Continent,Location, Date, Population,New_Vaccinations, Rolling_people_vaccinated)

as 
(
select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as Rolling_people_vaccinated
from Portfolio..CovidDeaths dea
join Portfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

select * , (Rolling_people_vaccinated/Population)*100 as vaccination_percentages
from POPvsVac;


-- Using TempTable

drop table if exists #PercentPopulationVaccinated;
create table #Percent_population_vaccinated (
	Continent nvarchar(255),
	Location nvarchar(255),
	Date date,
	Population numeric,
	New_vaccinations numeric,
	Rolling_people_vaccinated numeric
	)

insert into #Percent_population_vaccinated
select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as Rolling_people_vaccinated
from Portfolio..CovidDeaths dea
join Portfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *
from #Percent_population_vaccinated
order by 2,3


-- creating views to store data for later visualizations

create view PopulationVaccinated as 
(
select 
	dea.continent, 
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as Rolling_people_vaccinated
from Portfolio..CovidDeaths dea
join Portfolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

select * 
from PopulationVaccinated