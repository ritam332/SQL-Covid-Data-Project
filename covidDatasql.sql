use coviddata;
select * from coviddata..CovidDeaths  where continent is not null order by 3,4;
--select * from coviddata..CovidDeaths order by 3,4


-- selecting data
select location,date,total_cases,new_cases,total_deaths,population 
from coviddata..CovidDeaths order by 1,2;

-- total cases vs total death -- shows the likelihood of dying if you contract covid in India

select location,date,total_cases,new_cases,total_deaths,(total_deaths/total_cases*100) as DeathRate 
from coviddata..CovidDeaths  where location like '%india%' and continent is not null order by 1,2;

-- looking at total cases vs population -- shows %popln get covid

select location,date,population,total_cases,(total_cases/population*100) as InfectionRate 
from coviddata..CovidDeaths where continent is not null and location like '%india%'  order by 1,2;

-- countries with highest InfectionRate compared to popln
select location,population,max(total_cases) as total_infection_count,max(total_cases/population*100) as InfectionRate 
from coviddata..CovidDeaths   where continent is not null group by location, population order by InfectionRate desc;

-- countries with highest deathCount compared to popln

select location,population,max(cast(total_deaths as bigint)) as total_death_count
from coviddata..CovidDeaths 
where continent is not null
group by location, population  order by total_death_count desc;

-- continent wise data
-- continent with highest death count per popln

select location,max(cast(total_deaths as bigint)) as total_death_count
from coviddata..CovidDeaths 
where continent is  null
group by location  
order by total_death_count desc;

-- global numbers

select date,sum(new_cases) as total_cases,SUM(CAST(new_deaths as int)) as total_deaths,(SUM(CAST(new_deaths as int))/sum(new_cases)*100) as DeathRate 
from coviddata..CovidDeaths  where  continent is not null group by date order by 1,2;

select sum(new_cases) as total_cases,SUM(CAST(new_deaths as int)) as total_deaths,(SUM(CAST(new_deaths as int))/sum(new_cases)*100) as DeathRate 
from coviddata..CovidDeaths  where  continent is not null order by 1,2;


--join two table
select * from coviddata..CovidDeaths d
join coviddata..CovidVaccinations v
on d.date=v.date and d.location=v.location;

-- total population vs vaccination
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(cast(v.new_vaccinations as int)) over(partition by d.location order by d.location, d.date) as RollingPplVaccinated
from coviddata..CovidDeaths d
join coviddata..CovidVaccinations v
on d.date=v.date and d.location=v.location
where d.continent is not null
order by 2,3;

-- using CTE
with popVSvac (continent, location, date, popln, new_vac,RollingPplVaccinated)
as(
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(cast(v.new_vaccinations as int)) over(partition by d.location order by d.location, d.date) as RollingPplVaccinated
from coviddata..CovidDeaths d
join coviddata..CovidVaccinations v
on d.date=v.date and d.location=v.location
where d.continent is not null
--order by 2,3
)
select *,RollingPplVaccinated/popln*100 as VacPercentage from popVSvac

-- temp table

drop table if exists #percentPoplnVaccinated; 
create table #percentPoplnVaccinated(
continent nvarchar(255), location nvarchar(255), date datetime, popln numeric, new_vac numeric, RollingPplVaccinated numeric
)

insert into #percentPoplnVaccinated
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(cast(v.new_vaccinations as int)) over(partition by d.location order by d.location, d.date) as RollingPplVaccinated
from coviddata..CovidDeaths d
join coviddata..CovidVaccinations v
on d.date=v.date and d.location=v.location
--where d.continent is not null
--order by 2,3
select *,RollingPplVaccinated/popln*100 as VacPercentage from #percentPoplnVaccinated;

-- creating view to store data for later visualizations

create view percentPoplnVaccinated as
select d.continent,d.location,d.date,d.population,v.new_vaccinations,
sum(cast(v.new_vaccinations as int)) over(partition by d.location order by d.location, d.date) as RollingPplVaccinated
from coviddata..CovidDeaths d
join coviddata..CovidVaccinations v
on d.date=v.date and d.location=v.location
where d.continent is not null
--order by 2,3

drop view if exists percentPoplnVaccinated