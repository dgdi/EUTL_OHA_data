# Scraper for the European Union Transaction Log Operator Holding Account
This repository stores the code to scrape the European Union Transaction Log (EUTL) [Operator Holding Account](https://ec.europa.eu/clima/ets/oha.do) (OHA) data by Duccio Gamannossi degl'Innocenti.

### Description of files in the Repo

* *EUTLOHA_scraper.R* 				:   script to download the XML pages of the EUTL OHA dataset

* *EUTLOHA_databuild.R*       :   script to read the XML pages of the EUTL OHA dataset and create tabular datasets (*EUTLOHA_ma99.csv.gz* and *EUTLOHA_maNOT99.csv.gz*)

* *EUTLOHA_datacombine.R* 				:   script to combine the information of *EUTLOHA_ma99.csv.gz* and *EUTLOHA_maNOT99.csv.gz* in the more complete *EUTLOHA_tot.csv.gz*

* *license.txt*							: 	license applying to the scripts in the repo	

* *package_setup.R*					:   script to install needed packages


* ***data***								: 	folder containing the EUTL OHA dataset in tabular form (csv compressed using gzip)

    * *EUTLOHA_comb.csv.gz*: More complete EUTL OHA dataset combining the information of *EUTLOHA_ma99.csv.gz* and *EUTLOHA_maNOT99.csv.gz*

    * *EUTLOHA_ma99.csv.gz*:   EUTL OHA dataset from processing the XML pages collecting all the "Main Activity Type" (All)  
    
    * *EUTLOHA_maNOT99.csv.gz*:   EUTL OHA dataset from processing the XML pages of every "Main Activity Type"  
    
    * *EUTLOHA_scraper_report.txt*:  report of the data scraping

* **R**									: 	folder containing R scripts to be sourced
	
	* fun.R					:   script storing the functions needed to run the main scripts
	* pars.R 		    : 	script storing the general parameters used in the main scripts

### Information

The script *EUTLOHA_scraper.R* retrieves from the [EUTL OHA webpage](https://ec.europa.eu/clima/ets/oha.do) the "National Administrator", "Main Activity Type", "Compliance Status" and "Phases" codes and uses them to query the entire dataset. In case of errors, the script tries to re-download the pages during the next 60 hours. Upon completion, the script summarizes the outcome of the scraping in the file *data/EUTLOHA_scraper_report.txt* (time of scraping start and end, number and % of errors if present).

The script *EUTLOHA_databuild.R* reads all the XML pages downloaded by *EUTLOHA_scraper.R*, allows one to check what are the fields, and builds datasets in tabular form. For each "National Administrator", "Compliance Status" and "Phases" it is possible to query an XML page for each of the "Main Activity Type" or all at once. Given that the two resulting datasets (respectively *EUTLOHA_ma99.csv.gz* and *EUTLOHA_maNOT99.csv.gz*) are different, both are provided in the data folder.

The script *EUTLOHA_datacombine.R* reads the datasets *EUTLOHA_ma99.csv.gz* and *EUTLOHA_maNOT99.csv.gz* and checks if there are differences between the two. Given that the observations that are non-missing in both datasets are identical but there are cases where one of the two datasets reports information that is missing in the other, the script combines the two datasets to produce the more complete *EUTLOHA_comb.csv.gz*.   

The data here provided is part of the one available [here](https://climate.ec.europa.eu/eu-action/eu-emissions-trading-system-eu-ets/union-registry_en#documentation) -released yearly-, and [here](https://www.eea.europa.eu/data-and-maps/dashboards/emissions-trading-viewer-1) -released in aggregated form. Notice that several checks and additions are performed in the latter release, see the technical documents reported in the page for more information. 

### Instructions

+ If the scraping has been performed recently enough (check the date of download in *EUTLOHA_scraper_report.txt* ) simply download the dataset of interest from the data folder.

+ If you need the most up-to-date data possible, you can use the scripts *EUTLOHA_scraper.R* and *EUTLOHA_databuild.R* (you will need to set some minor details, such as the path of the folder where to store the downloaded pages). To this end:

    1. Start a new R-project in an empty folder
    2. Copy the content of the repo in the project folder
    3. Run the script package_setup.R to install the needed packages
    4. Run *EUTLOHA_scraper.R* to downlad the the XML pages of the EUTL OHA dataset in the convenience folder *EUTLOHA_ma_country_phase_compliance* and produce *EUTLOHA_scraper_report.txt* in the *data* folder
    5. Run *EUTLOHA_databuild.R*, to create the datasets *EUTLOHA_ma99.csv.gz* and *EUTLOHA_maNOT99.csv.gz* in the *data* folder
    6. Run *EUTLOHA_datacombine.R* to create the dataset *EUTLOHA_comb.csv.gz* in the *data* folder

The scripts have been tested on Win 10, R-4.1.1, RStudio-1.4.1717

The scripts in the repository are distributed under the BSD license. For more information, please check the license.txt file. The EUTL OHA data is publicly available.

For any question, suggestion or comment, write to: mail@dgdi.me
