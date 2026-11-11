#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Caches the use of scheduled tasks property in the same-name register detail.
//
// Parameters:
//	FilterCompanies - Array - organization for caching properties.
//	
// Returns:
// 	Number - the amount of processed data for measuring performance
//
Function UpdateCachePropertiesUsingScheduledTask(FilterCompanies = Undefined) Export
	
	DataVolume = 0; // to measure performance
	JobDetails  = CreateTaskDescription();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Jobs.Organization AS Organization,
	|	Jobs.ScheduledJob AS JobID,
	|	Jobs.LastPeriodClosingStartDate,
	|	Jobs.CloseOperationalAccountingInPastPeriod,
	|	Jobs.CloseLocalAccountingInPastPeriod,
	|	Jobs.CloseFinancialAccountingInPastPeriod,
	|	Jobs.CurrentPeriodClosingMode,
	|	Jobs.CloseOperationalAccountingInCurrentPeriod,
	|	Jobs.CloseLocalAccountingInCurrentPeriod,
	|	Jobs.Use
	|FROM
	|	InformationRegister.ScheduledJobsOfMonthEndClosing AS Jobs
	|WHERE
	|	(Jobs.Organization IN (&FilterCompanies)
	|			OR &ByAllCompanies)";
	
	Query.SetParameter("FilterCompanies", 	TMCommonUseClientServer.Array(FilterCompanies));
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(FilterCompanies));
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		DataVolume = DataVolume + 1;
		
		Job = ScheduledJobsServer.Job(Selection.JobID);
		
		If Job = Undefined Then
			
			// The task was not found - we will delete the register entry.
			Record = InformationRegisters.ScheduledJobsOfMonthEndClosing.CreateRecordManager();
			Record.Organization = Selection.Organization;
			
			Record.Delete();
			
		ElsIf Job.Use <> Selection.Use Then
			
			// Update the cache of the "Usage" property.
			FillPropertyValues(JobDetails, Selection);
			JobDetails.Use = Job.Use;
			
			WriteRoutineTaskForOrganization(JobDetails);
			
		EndIf;
		
	EndDo;
	
	Return DataVolume;
	
EndFunction

// Returns a description of the regular task for closing the month for the specified organization.
//
// Parameters:
//	Organization - CatalogRef.Companies - organization for getting a routine task.
//
// Returns:
//	Structure - LongDesc:
//		* Organization - CatalogRef.Companies
//		* JobID - UUID
//		* LastPeriodClosingStartDate - Date
//		* CloseOperationalAccountingInPastPeriod - Boolean
//		* CloseLocalAccountingInPastPeriod - Boolean
//		* CloseFinancialAccountingInPastPeriod - Boolean
//		* CloseOperationalAccountingInCurrentPeriod - Boolean
//		* CloseLocalAccountingInCurrentPeriod - Boolean
//		* Job - ScheduledJob
//		* JobState - See TMCommonUse.GetStateOfLastJob
//
Function GetRoutineTaskForOrganization(Organization) Export
	
	If Organization = Undefined Then
		Organization = Catalogs.Companies.EmptyRef();
	EndIf;
	
	JobDetails = CreateTaskDescription();
	JobDetails.Organization = Organization;
	JobDetails.JobExists = False;
	JobDetails.SettingExists = False;
	JobDetails.LastPeriodClosingStartDate = Date(1, 1, 1);
	JobDetails.CloseOperationalAccountingInPastPeriod = False;
	JobDetails.CloseLocalAccountingInPastPeriod = False;
	JobDetails.CloseFinancialAccountingInPastPeriod = False;
	JobDetails.CurrentPeriodClosingMode = Enums.MonthEndClosingModes.FinalClosing;
	JobDetails.CloseOperationalAccountingInCurrentPeriod = False;
	JobDetails.CloseLocalAccountingInCurrentPeriod = False;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Jobs.ScheduledJob,
	|	Jobs.LastPeriodClosingStartDate,
	|	Jobs.CloseOperationalAccountingInPastPeriod,
	|	Jobs.CloseLocalAccountingInPastPeriod,
	|	Jobs.CloseFinancialAccountingInPastPeriod,
	|	Jobs.CurrentPeriodClosingMode,
	|	Jobs.CloseOperationalAccountingInCurrentPeriod,
	|	Jobs.CloseLocalAccountingInCurrentPeriod
	|FROM
	|	InformationRegister.ScheduledJobsOfMonthEndClosing AS Jobs
	|WHERE
	|	Jobs.Organization = &Organization";
	
	Query.SetParameter("Organization", Organization);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FillPropertyValues(JobDetails, Selection);
		JobDetails.SettingExists  = True;
		JobDetails.JobID = Selection.ScheduledJob;
	EndIf;
	
	If JobDetails.JobID <> Undefined Then
		
		JobDetails.Job = ScheduledJobsServer.Job(JobDetails.JobID);
		
		If JobDetails.Job <> Undefined Then
			JobDetails.JobExists = True;
			JobDetails.Use 	  = JobDetails.Job.Use; // we get it not from the register cache, but from the task itself
			JobDetails.JobState  = TMCommonUse.GetStateOfLastJob(JobDetails.Job);
		EndIf;
		
	EndIf;
	
	Return JobDetails;
	
EndFunction

// Saves the parameters of the regular task for closing the month.
//
// Parameters:
//	JobDetails - Structure:
//		* Organization - CatalogRef.Companies - 
//		* JobID - UUID -
//
Procedure WriteRoutineTaskForOrganization(JobDetails) Export
	
	Record = InformationRegisters.ScheduledJobsOfMonthEndClosing.CreateRecordManager();
	
	FillPropertyValues(Record, JobDetails);
	Record.Organization 		   		   = JobDetails.Organization;
	Record.ScheduledJob 		   = JobDetails.JobID;
	Record.Use	   		   = JobDetails.Use;
	
	SetPrivilegedMode(True);
	
	Record.Write(True);
	
EndProcedure

// Returns an array of organizations that have scheduled monthly closing tasks enabled.
//
// Parameters:
//	FilterCompanies - Array - organization for checking whether a scheduled task is enabled.
//
// Returns:
//	Array - array of organizations
//
Function GetOrganizationsWithScheduledTasksEnabled(FilterCompanies = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Jobs.Organization AS Organization
	|FROM
	|	InformationRegister.ScheduledJobsOfMonthEndClosing AS Jobs
	|WHERE
	|	(Jobs.Organization IN (&FilterCompanies)
	|			OR &ByAllCompanies)
	|	AND Jobs.Use
	|
	|ORDER BY
	|	Organization";
	
	Query.SetParameter("FilterCompanies", 	TMCommonUseClientServer.Array(FilterCompanies));
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(FilterCompanies));
	
	SetPrivilegedMode(True);
	
	CompanyArray = Query.Execute().Unload().UnloadColumn("Organization");
	
	Return CompanyArray;
	
EndFunction

#EndRegion

#Region Private

Function CreateTaskDescription()
	
	Return New Structure(
		"Organization, JobID, LastPeriodClosingStartDate,
		|CloseOperationalAccountingInPastPeriod, CloseLocalAccountingInPastPeriod,
		|CloseFinancialAccountingInPastPeriod, CurrentPeriodClosingMode,
		|CloseOperationalAccountingInCurrentPeriod, CloseLocalAccountingInCurrentPeriod,
		|Job, Use, JobState, JobExists, SettingExists");
	
EndFunction

Procedure FillInTaskAttributeForOrganizations(ChoiceList) Export
	
	AnEmptyPicture    = New Picture;
	CompanyArray = GetOrganizationsWithScheduledTasksEnabled();
	
	For Each CurrentCompany In ChoiceList Do
		ThereIsRoutineTask 	= (CompanyArray.Find(CurrentCompany.Value) <> Undefined);
		CurrentCompany.Picture = ?(ThereIsRoutineTask, PictureLib.ScheduledJob, AnEmptyPicture);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
