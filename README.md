# chicago_crime_analytics
### A tool to identify trends in the "City of the Big Shoulders".

Tool used: PostgreSQL, Tableau

LINKs

## Business case evaluation

* Business Problem: The Chicago Chief of Police is having trouble tracking and monitoring crime trends in his city. Although the data is well gathered and stored, asking data specialists for a report on crime rates for a specific community or area is ineffective and time-consuming. They need a data analytics solution that will gather useful information in a clear, uncomplicated way, making it possible to conduct ad hoc analysis and uncover valuable patterns and trends.
* My solution: To help Chief and his colleagues gather valuable insights that are important for city safety, I plan to use my SQL and data visualisation skills. SQL will enable me to build a precise query that tailors the data to showcase valuable trends and numbers. The data visualisation tool I have chosen, Tableau, will help me present this data in a clear and approachable way to help officers instantly spot patterns in the dataset. The dashboard will be designed to support filtering the data by the three main aspects: Community or district of the city, type of crime and year. The questions that are important for this task are as follows:
  * Have there been any significant increases or decreases in specific crime types compared to the previous year or month? If so, by what percentage?
  * Are there any discernible patterns in the seasonality of crime? For example, do certain types of crime tend to spike during particular months or seasons? What is the 'crime season' during a year?
  * Which districts or communities have the lowest reported crime rates? Which community is the safest? 

## Data Preparation
I gathered all the data used in this task from the (Chicago Data Portal)[https://data.cityofchicago.org]. This analysis is based on data set [Crimes - 2001 to Present](https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2/about_data) I've applied a filter on the site to download data ranging from January 1, 2020, at 12:00:00 AM to December 31, 2024, at 11:45:00 PM. The mapping of the area was pulled from [chicago Community areas](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/chicago-Community-areas/m39i-3ntz). 

