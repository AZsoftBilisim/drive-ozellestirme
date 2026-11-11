#Region Public

#Region OverridableAccessControlFunctions

// See AccessManagementOverridable.OnFillAccessRestriction.
Procedure OnFillAccessRestriction(List, Restriction) Export
	
	If List = Metadata.Catalogs.EmployeesHR Then
		
		Restriction.Text =
		"AttachAdditionalTables
		|ThisList AS T
		|
		|LEFT JOIN Catalog.Users AS T1
		|	ON T1.Individual = T.Ref
		|;
		|AllowReadUpdate
		|WHERE
		|	ValueAllowed(T.Ref)
		|	AND ValueAllowed(T.ParentCompany)";
	
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// StandardSubsystems.AccessManagement

// Fills an array of structures that will be used for initial filling and restoring the initial filling of profiles.
//
// Parameters:
//  ProfilesDetails - Array of See AccessManagement.NewAccessGroupProfileDescription
//  ParametersOfUpdate - Structure:
//   * UpdateModifiedProfiles - Boolean - the initial value is True.
//   * DenyProfilesChange - Boolean - the initial value is True.
//       If set to False, then the supplied profiles can not only be viewed, but also edited.
//   * UpdatingAccessGroups     - Boolean - the initial value is True.
//   * UpdatingAccessGroupsWithObsoleteSettings - Boolean - the initial value is False.
//       If set to True, the value settings made by the administrator for
//       the type of access that was removed from the profile will also be removed from the access groups.
//
Procedure FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	
	// The profile folder "Salary and personnel".
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "PayrollAndHR";
	FolderDescription_.Id = "e253c9e1-e33c-43c5-b03b-cb209ccea271";
	FolderDescription_.Description  = NStr("ru = 'Зарплата и кадры (HR&Payroll)';
											|vi = 'HR&Payroll';
											|en = 'HR&Payroll'; fa = 'HR&Payroll';
											|it = 'HR&Payroll';
											|pl = 'HR&Payroll';
											|tr = 'Bordro ve Personel (HR&Payroll)'", 
		Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);
	
	AddHRManagerProfile(ProfilesDetails);
	AddBillingProfile(ProfilesDetails);
	AddTimesheetProfile(ProfilesDetails);
	AddProfileOfHumanResourcesContractor(ProfilesDetails);
	AddProfileOfPersonResponsibleForSchedule(ProfilesDetails);
	
	IndexOfProfiles = IndexProfiles(ProfilesDetails, "Name");
	
	ProfileDetails = FindProfile("Cashier", ProfilesDetails, IndexOfProfiles);
	If ProfileDetails <> Undefined Then
		AddProfile(ProfileDetails, "Cashier");
	EndIf;
	
	ProfileDetails = FindProfile("Treasurer", ProfilesDetails, IndexOfProfiles);
	If ProfileDetails <> Undefined Then
		AddProfile(ProfileDetails, "Treasurer");
	EndIf;
	
	ProfileDetails = FindProfile("Accountant", ProfilesDetails, IndexOfProfiles);
	If ProfileDetails <> Undefined Then
		AddProfile(ProfileDetails, "Accountant");
	EndIf;
	
	ProfileDetails = FindProfile("LocalDispatcher", ProfilesDetails, IndexOfProfiles);
	If ProfileDetails <> Undefined Then
		AddProfile(ProfileDetails, "LocalDispatcher");
	EndIf;
	
	ProfileDetails = FindProfile("ProductionManager", ProfilesDetails, IndexOfProfiles);
	If ProfileDetails <> Undefined Then
		AddProfile(ProfileDetails, "ProductionManager");
	EndIf;
	
	ProfileDetails = FindProfile("ManufacturingEconomist", ProfilesDetails, IndexOfProfiles);
	If ProfileDetails <> Undefined Then
		AddProfile(ProfileDetails, "ManufacturingEconomist");
	EndIf;
	
	ProfileDetails = FindProfile("ChiefDispatcher", ProfilesDetails, IndexOfProfiles);
	If ProfileDetails <> Undefined Then
		AddProfile(ProfileDetails, "ChiefDispatcher");
	EndIf;

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region Private

Function IndexProfiles(ProfilesDetails, ProfileField = "Name")
	
	Result = New Map;
	For IndexOf = 0 To ProfilesDetails.UBound() Do
		
		Profile = ProfilesDetails[IndexOf];
		Result.Insert(Profile[ProfileField], IndexOf);
		
	EndDo;
	Return Result;
	
EndFunction

Function FindProfile(ProfileName, ProfilesDetails, IndexOfProfiles)

	ProfileIndex = IndexOfProfiles[ProfileName];
	If ProfileIndex = Undefined Then
		Return Undefined;
	EndIf;
	Return ProfilesDetails[ProfileIndex];
	
EndFunction

Procedure AddHRManagerProfile(DescriptionProfiles)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Id = IdOfHrManagerProfile();
	ProfileDetails.Parent      = "PayrollAndHR";
	ProfileDetails.Description  = NStr("ru = 'Кадровик';
										|vi = 'HR officer';
										|en = 'HR officer'; fa = 'HR officer';
										|it = 'HR officer';
										|pl = 'HR officer';
										|tr = 'Personel Uzmanı'");
	
	AddRequiredRolesToProfileDescription(ProfileDetails);
	
	AddRoleToProfileDescription(ProfileDetails, "AddAndEditHumanResources");
	AddRoleToProfileDescription(ProfileDetails, "AddAndEditTimeTracking");
	
	AddRoleToProfileDescription(ProfileDetails, "AddEditPersons");
	AddRoleToProfileDescription(ProfileDetails, "AddChangeEmployeeDataHR");  
	AddRoleToProfileDescription(ProfileDetails, "ReadMasterData");  
	AddRoleToProfileDescription(ProfileDetails, "ReadCompaniesAndBankAccountsOfCompanies"); 
	AddRoleToProfileDescription(ProfileDetails, "ViewCurrencies"); 
	
	DescriptionProfiles.Add(ProfileDetails);
	
EndProcedure

Procedure AddBillingProfile(DescriptionProfiles)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Id = IdOfBillingProfile();
	ProfileDetails.Parent      = "PayrollAndHR";
	ProfileDetails.Description  = NStr("ru = 'Расчетчик';
										|vi = 'Payroll & benefits officer';
										|en = 'Payroll & benefits officer'; fa = 'Payroll & benefits officer';
										|it = 'Payroll & benefits officer';
										|pl = 'Payroll & benefits officer';
										|tr = 'Bordro Uzmanı'");
	
	AddRequiredRolesToProfileDescription(ProfileDetails);
	
	AddRoleToProfileDescription(ProfileDetails, "AddAndEditPayrollCalculation");
	AddRoleToProfileDescription(ProfileDetails, "AddAndEditPayrollPayment");
	AddRoleToProfileDescription(ProfileDetails, "AddAndEditTimeTracking");
	
	AddRoleToProfileDescription(ProfileDetails, "AddEditPersons");
	AddRoleToProfileDescription(ProfileDetails, "AddChangeEmployeeDataHR");  
	AddRoleToProfileDescription(ProfileDetails, "ReadMasterData");  
	AddRoleToProfileDescription(ProfileDetails, "ReadCompaniesAndBankAccountsOfCompanies");  
	AddRoleToProfileDescription(ProfileDetails, "ViewCurrencies");
	AddRoleToProfileDescription(ProfileDetails, "AddEditSalaryRecordingInFinancialAccounting2_5");
	
	DescriptionProfiles.Add(ProfileDetails);
	
EndProcedure

Procedure AddTimesheetProfile(DescriptionProfiles)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Id = ProfileIdTimesheet();
	ProfileDetails.Parent      = "PayrollAndHR";
	ProfileDetails.Description  = NStr("ru = 'Табельщик';
										|vi = 'Timesheet owner';
										|en = 'Timesheet owner'; fa = 'Timesheet owner';
										|it = 'Timesheet owner';
										|pl = 'Timesheet owner';
										|tr = 'Puantör'");
	
	AddRequiredRolesToProfileDescription(ProfileDetails);

	AddRoleToProfileDescription(ProfileDetails, "AddAndEditTimeTracking");
	
	AddRoleToProfileDescription(ProfileDetails, "AddEditPersons");
	AddRoleToProfileDescription(ProfileDetails, "AddChangeEmployeeDataHR");  
	AddRoleToProfileDescription(ProfileDetails, "ReadMasterData");  
	AddRoleToProfileDescription(ProfileDetails, "ReadCompaniesAndBankAccountsOfCompanies");  
	AddRoleToProfileDescription(ProfileDetails, "ViewCurrencies"); 
	
	DescriptionProfiles.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileOfPersonResponsibleForSchedule(DescriptionProfiles)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Id = IdOfProfileResponsibleForSchedule();
	ProfileDetails.Parent      = "PayrollAndHR";
	ProfileDetails.Description  = NStr("ru = 'Ответственный за расписание';
										|vi = 'Person responsible for the schedule';
										|en = 'Person responsible for the schedule'; fa = 'Person responsible for the schedule';
										|it = 'Person responsible for the schedule';
										|pl = 'Person responsible for the schedule';
										|tr = 'Programdan sorumlu kişi'");
	
	AddRequiredRolesToProfileDescription(ProfileDetails);

	AddRoleToProfileDescription(ProfileDetails, "HeadcountManagementHR");
	
	AddRoleToProfileDescription(ProfileDetails, "AddEditPersons");
	AddRoleToProfileDescription(ProfileDetails, "AddChangeEmployeeDataHR");  
	AddRoleToProfileDescription(ProfileDetails, "ReadMasterData");  
	AddRoleToProfileDescription(ProfileDetails, "ReadCompaniesAndBankAccountsOfCompanies");  
	AddRoleToProfileDescription(ProfileDetails, "ViewCurrencies"); 
	
	DescriptionProfiles.Add(ProfileDetails);
	
EndProcedure

Procedure AddProfileOfHumanResourcesContractor(DescriptionProfiles)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Id = IdOfHrManagerBillingProfile();
	ProfileDetails.Parent      = "PayrollAndHR";
	ProfileDetails.Description  = NStr("ru = 'Кадровик-расчетчик';
										|vi = 'HR officer (payroll & benefits)';
										|en = 'HR officer (payroll & benefits)'; fa = 'HR officer (payroll & benefits)';
										|it = 'HR officer (payroll & benefits)';
										|pl = 'HR officer (payroll & benefits)';
										|tr = 'Personel ve Bordro Uzmanı'");
	
	AddRequiredRolesToProfileDescription(ProfileDetails);

	AddRoleToProfileDescription(ProfileDetails, "AddAndEditHumanResources");
	AddRoleToProfileDescription(ProfileDetails, "AddAndEditTimeTracking");
	AddRoleToProfileDescription(ProfileDetails, "AddAndEditPayrollCalculation");
	AddRoleToProfileDescription(ProfileDetails, "AddAndEditPayrollPayment");
	
	AddRoleToProfileDescription(ProfileDetails, "AddEditPersons");
	AddRoleToProfileDescription(ProfileDetails, "AddChangeEmployeeDataHR");  
	AddRoleToProfileDescription(ProfileDetails, "ReadMasterData");  
	AddRoleToProfileDescription(ProfileDetails, "ReadCompaniesAndBankAccountsOfCompanies");  
	AddRoleToProfileDescription(ProfileDetails, "ViewCurrencies"); 
	AddRoleToProfileDescription(ProfileDetails, "AddEditSalaryRecordingInFinancialAccounting2_5");
	
	DescriptionProfiles.Add(ProfileDetails);
	
EndProcedure

Function IdOfHrManagerProfile()
	Return "63ad30be-d5ad-4fca-acb1-4905dd15d556";
EndFunction

Function IdOfBillingProfile()
	Return "f1bacb55-d09c-4407-8a12-01f5ab8dc086";
EndFunction

Function ProfileIdTimesheet()
	Return "fe40825c-26e2-4097-b0ad-d1efa12fec2e";
EndFunction

Function IdOfProfileResponsibleForSchedule()
	Return "da2c751d-65e5-11f0-a551-3c7c3f0fdb0c";
EndFunction

Function IdOfHrManagerBillingProfile()
	Return "57c0839b-9966-4c41-9f25-b2468a2d101c";
EndFunction

Procedure AddRequiredRolesToProfileDescription(ProfileDetails) 
	
	AddRoleToProfileDescription(ProfileDetails, "BasicAccessSSL");
	AddRoleToProfileDescription(ProfileDetails, "BasicAccessDMIL" , 											"IntegrationWith1CDocumentManagementSubsystem");
	AddRoleToProfileDescription(ProfileDetails, "BasicAccessSRL" , 											"RegulatedReporting");
	AddRoleToProfileDescription(ProfileDetails, "BasicAccessCTL" , 											"CloudTechnology");
	AddRoleToProfileDescription(ProfileDetails, "BasicAccessOUS" , 											"OnlineUserSupport");
	AddRoleToProfileDescription(ProfileDetails, "ReadingJobTitles",											"SalaryCadresApplications.BasicReferenceDataAdvanced");
	AddRoleToProfileDescription(ProfileDetails, "StartWebClient");
	AddRoleToProfileDescription(ProfileDetails, "StartThickClient");
	AddRoleToProfileDescription(ProfileDetails, "StartThinClient");
	AddRoleToProfileDescription(ProfileDetails, "PrintFormsEdit", 								"StandardSubsystems.Print");
	AddRoleToProfileDescription(ProfileDetails, "AddEditPersonalReportsOptions", 					"StandardSubsystems.ReportsOptions");
	AddRoleToProfileDescription(ProfileDetails, "ReadAdditionalReportsAndDataProcessors", 						"StandardSubsystems.AdditionalReportsAndDataProcessors");
	AddRoleToProfileDescription(ProfileDetails, "AddEditFoldersAndFiles", 							"StandardSubsystems.FilesOperations");
	AddRoleToProfileDescription(ProfileDetails, "SaveUserData");
	
EndProcedure

Procedure AddRoleToProfileDescription(ProfileDetails, NameOfRole, FullSubsystemName = "") Export
	
	If Not IsBlankString(FullSubsystemName) And Not Common.SubsystemExists(FullSubsystemName) Then
		Return;
	EndIf;
	
	ProfileDetails.Roles.Add(NameOfRole);
	
EndProcedure

Procedure AddProfile(ProfileDetails, ProfileName)
	
	If ProfileName = "Treasurer" Then
		ProfileDetails.Roles.Add("ReadSalaryPayment");
		ProfileDetails.Roles.Add("AddAndEditPayrollPayment");
	ElsIf ProfileName = "Accountant" Then
		ProfileDetails.Roles.Add("ReadSalaryPayment");
		ProfileDetails.Roles.Add("AddAndEditPayrollPayment");
	ElsIf ProfileName = "Cashier" Then
		ProfileDetails.Roles.Add("ReadSalaryPayment");
	ElsIf ProfileName = "LocalDispatcher" Then
		ProfileDetails.Roles.Add("ReadEmployeeDataHR");
	ElsIf ProfileName = "ProductionManager" Then
		ProfileDetails.Roles.Add("ReadEmployeeDataHR");
	ElsIf ProfileName = "ManufacturingEconomist" Then
		ProfileDetails.Roles.Add("ReadEmployeeDataHR");
	ElsIf ProfileName = "ChiefDispatcher" Then
		ProfileDetails.Roles.Add("ReadEmployeeDataHR");	
	EndIf;
	
EndProcedure

#EndRegion
