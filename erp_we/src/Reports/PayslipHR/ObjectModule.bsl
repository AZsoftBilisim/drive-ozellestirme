#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers
	
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;

	ResultDocument.Clear();
	
	ReportSettings = SettingsComposer.GetSettings();
	
	// Document parameters
	ResultDocument.ReadOnly = True;
	ResultDocument.PrintParametersKey = "PRINT_OPTIONS_BillingSheet";
	ResultDocument.PageOrientation = PageOrientation.Landscape;
	
	CompositionTemplate = DataCompositionServer.GetLayoutTemplate(DataCompositionSchema, ReportSettings);
	
	// Let's create and initialize the layout processor.
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , , True);
	
	DataOnBillingSheet = New ValueTree;
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	OutputProcessor.SetObject(DataOnBillingSheet);
	
	// Denote the beginning of the output
	OutputProcessor.Output(CompositionProcessor, True);
	ToOutputTemplate(DataOnBillingSheet, ResultDocument);
	AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
	AuxProperties.Insert("ReportIsBlank", DataOnBillingSheet.Rows.Count() = 0);
	
EndProcedure 

#EndRegion

#Region Private

Function ServiceNumberForPrinting(Val EmployeeCode)
	
	Return ObjectsPrefixesClientServer.DeletePrefixesFromObjectNumber(EmployeeCode, True, True);
	
EndFunction

Function MonthOfAccrualForPrinting(Val MonthOfAccrual)
	
	Return Upper(Format(MonthOfAccrual, "DF='MMMM yyyy'"));
	
EndFunction

Procedure ToOutputTemplate(PersonData, SpreadsheetDocument=Undefined) 
	
	If SpreadsheetDocument = Undefined Then
		SpreadsheetDocument = New SpreadsheetDocument;
	EndIf;
	
	EmptyRows = New Array;
	For Each OrganizationData_1 In PersonData.Rows Do
		If OrganizationData_1.Rows.Count()=0 Then
			EmptyRows.Add(OrganizationData_1);
		EndIf;
	EndDo;
	For Each IsBlankString In EmptyRows Do
		PersonData.Rows.Delete(IsBlankString);
	EndDo;
	
	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_BillingSheet";
	
	Template = PrintManagement.PrintFormTemplate("Report.PayslipHR.PF_MXL_BillingSheet");
	
	AccountsOfCompanies = 0;
	For Each CurrentRowDataOnPerson In PersonData.Rows Do 
		AccountsOfCompanies = AccountsOfCompanies+1;
		If CurrentRowDataOnPerson.Rows.Count() = 0 Then
			Continue;
		EndIf;
		
		SamplingByPeriod = CurrentRowDataOnPerson.Rows;
		For Each CurrentPeriod In SamplingByPeriod Do
			
			HeaderStructure_ = New Structure("MonthOfAccrualForPrinting,IndividualFULLName");
			FillPropertyValues(HeaderStructure_, CurrentPeriod);
			HeaderStructure_.MonthOfAccrualForPrinting = MonthOfAccrualForPrinting(CurrentPeriod.MonthOfAccrual); 
			
			OutputArea(Template, "Header", SpreadsheetDocument, HeaderStructure_);
			
			SamplingByWorkplace = CurrentPeriod.Rows;
			For Each CurrentLineIsSelectionByWorkplace In SamplingByWorkplace Do
				
				WorkplaceStructure = New Structure("EmployeeSCompanyAtEndOfPeriod",
				CurrentLineIsSelectionByWorkplace.Organization, 
				CurrentLineIsSelectionByWorkplace.Department);
				
				OutputArea(Template, "Workplace", SpreadsheetDocument, WorkplaceStructure);
				
				SelectionByEmployee = CurrentLineIsSelectionByWorkplace.Rows;
				For Each CurrentRowSelectionByEmployee In SelectionByEmployee Do
					
					HeaderStructure_ = New Structure("ServiceNumberForPrinting, EmployeeSDivisionAtEndOfPeriod",
					ServiceNumberForPrinting(CurrentRowSelectionByEmployee.EmployeeCode), 
					CurrentRowSelectionByEmployee.Department);
					
					If ValueIsFilled(CurrentRowSelectionByEmployee.Employee) Then
						OutputArea(Template, "Employee", SpreadsheetDocument, HeaderStructure_);
					EndIf;
					
					ThereIsPayout = False;
					SamplingByWorkingConditions = CurrentRowSelectionByEmployee.Rows;
					For Each CurrentLineSelectionBasedOnWorkingConditions In SamplingByWorkingConditions Do
						
						StructureOfWorkConditions = New Structure("JobTitleOfEmployeeAtEndOfPeriod,TariffRateAtEndOfPeriod",
						CurrentLineSelectionBasedOnWorkingConditions.JobTitle, CurrentLineSelectionBasedOnWorkingConditions.Salary_Tariff);
						
						If ValueIsFilled(CurrentRowSelectionByEmployee.Employee) Then
							OutputArea(Template, "WorkingConditions", SpreadsheetDocument, StructureOfWorkConditions);
						EndIf;	
						
						SamplingByGroupsOfCalculationTypes = CurrentLineSelectionBasedOnWorkingConditions.Rows;
						For Each CurrentRowIsSelectionByGroupsOfCalculationTypes In SamplingByGroupsOfCalculationTypes Do
							
							If CurrentRowIsSelectionByGroupsOfCalculationTypes.Group = "Accrued" Then
								
								WithdrawAccruedData(CurrentRowIsSelectionByGroupsOfCalculationTypes, Template, SpreadsheetDocument);
								
							ElsIf CurrentRowIsSelectionByGroupsOfCalculationTypes.Group = "Withheld" Then
								
								WithdrawWithheldData(CurrentRowIsSelectionByGroupsOfCalculationTypes, Template, SpreadsheetDocument);
								
							ElsIf CurrentRowIsSelectionByGroupsOfCalculationTypes.Group = "HasBeenPaid" Then
								
								ThereIsPayout = True;
								DisplayPaidData(CurrentRowIsSelectionByGroupsOfCalculationTypes, Template, SpreadsheetDocument);
								
							ElsIf CurrentRowIsSelectionByGroupsOfCalculationTypes.Group = "Debt" Then
								
								OutputDataOnDebt(CurrentRowIsSelectionByGroupsOfCalculationTypes, Template, SpreadsheetDocument);
								
							EndIf;
							
						EndDo;
						
						If Not ThereIsPayout Then
							StructureAmount = New Structure("Sum", Format(0, "NFD=2; NZ=0,00"));
							DisplayPaidData(StructureAmount, Template, SpreadsheetDocument);
						EndIf;
						
					EndDo;
					
				EndDo;
			EndDo;
		EndDo;
		
		If Not AccountsOfCompanies = PersonData.Rows.Count() Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
	EndDo;
	
EndProcedure

Procedure OutputDataOnDebt(CurrentRowIsSelectionByGroupsOfCalculationTypes, Template, SpreadsheetDocument)
	
	OutputArea(Template, "IsBlankString", SpreadsheetDocument);
	
	SamplingLineDebts = CurrentRowIsSelectionByGroupsOfCalculationTypes.Rows;
	
	For Each CurrentRowSelectionRowDebts In SamplingLineDebts Do
		
		DebtStructure = New Structure("TypeOfDebt,Sum", 
									CurrentRowSelectionRowDebts.Kind, 
									CurrentRowSelectionRowDebts.Sum);
		
		OutputArea(Template, "DebtForCompany", SpreadsheetDocument, DebtStructure);
		
	EndDo;	

EndProcedure	

Procedure DisplayPaidData(CurrentRowIsSelectionByGroupsOfCalculationTypes, Template, SpreadsheetDocument)
	
	OutputArea(Template, "IsBlankString", SpreadsheetDocument);
	
	StructurePaid = New Structure("Sum", CurrentRowIsSelectionByGroupsOfCalculationTypes.Sum); 
	
	OutputArea(Template, "TitlePaid", SpreadsheetDocument, StructurePaid);
	
EndProcedure	

Procedure WithdrawWithheldData(CurrentRowIsSelectionByGroupsOfCalculationTypes, Template, SpreadsheetDocument)

	OutputArea(Template, "IsBlankString", SpreadsheetDocument);
	OutputArea(Template, "TableHeaderWithheld",SpreadsheetDocument);
	
	StructureRetained = New Structure("Sum", CurrentRowIsSelectionByGroupsOfCalculationTypes.Sum);
	
	OutputArea(Template, "TitleWithheld", SpreadsheetDocument, StructureRetained);
	
	SelectionRowWithheld = CurrentRowIsSelectionByGroupsOfCalculationTypes.Rows;
	For Each CurrentRowSelectionRowWithheld In SelectionRowWithheld Do
		
		StructureOfCalculationType = New Structure("CalculationType,Sum",
								CurrentRowSelectionRowWithheld.Kind, 
								CurrentRowSelectionRowWithheld.Sum);
		StructureOfCalculationType.Insert("PeriodPresentation",  Format(CurrentRowSelectionRowWithheld.ActionPeriod, "DF=MM.yyyy"));
		
		OutputArea(Template, "LineWithheld", SpreadsheetDocument, StructureOfCalculationType);
		
	EndDo;	

EndProcedure	

Procedure WithdrawAccruedData(CurrentRowIsSelectionByGroupsOfCalculationTypes, Template, SpreadsheetDocument)

	OutputArea(Template, "IsBlankString", SpreadsheetDocument);
	OutputArea(Template, "HeaderOfAccruedTable", SpreadsheetDocument);
	
	StructureAccrued = New Structure("Sum", CurrentRowIsSelectionByGroupsOfCalculationTypes.Sum); 
	OutputArea(Template, "TitleAccrued", SpreadsheetDocument, StructureAccrued);
	
	SelectionAccrualLine = CurrentRowIsSelectionByGroupsOfCalculationTypes.Rows;
	For Each CurrentRowSelectionAccrualRow In SelectionAccrualLine Do
		
		StructureOfCalculationType = New Structure();
		StructureOfCalculationType.Insert("CalculationType",      CurrentRowSelectionAccrualRow.Kind);
		StructureOfCalculationType.Insert("DaysWorked",  CurrentRowSelectionAccrualRow.DaysWorked);
		StructureOfCalculationType.Insert("HoursWorked", CurrentRowSelectionAccrualRow.HoursWorked);
		StructureOfCalculationType.Insert("Sum",           CurrentRowSelectionAccrualRow.Sum);
		StructureOfCalculationType.Insert("PeriodPresentation",  Format(CurrentRowSelectionAccrualRow.ActionPeriod, "DF=MM.yyyy"));
					
		OutputArea(Template, "LineAccrued", SpreadsheetDocument, StructureOfCalculationType);
		
	EndDo;	
	
EndProcedure	

Procedure OutputArea(Template, NameOfArea, SpreadsheetDocument, ParametersStructure = Undefined)
	
	Area = Template.GetArea(NameOfArea);
	
	If ValueIsFilled(ParametersStructure) Then
		FillPropertyValues(Area.Parameters, ParametersStructure);
	EndIf;	
	
	SpreadsheetDocument.Put(Area); 
		
EndProcedure		
		
// For the general Form "Report Form" of the subsystem "Report Options".
// Defines the report Form settings for the "Report Options" subsystem.
// Parameters:
//   Form - ClientApplicationForm - Report form
//   VariantKey - String - Report variant key
//   Settings - Structure - Report Form Settings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Print.PageOrientation = PageOrientation.Landscape;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new data layout settings. 
// Used to change the layout scheme.
//
// Parameters:
//   Context - FormTable  - The context of the Settings Composer
//   SchemaKey - String - Data Layout Schema key
//   VariantKey - String - The key of the data layout settings option
//   NewDCSettings - DataCompositionSettings - New data layout settings
//   NewDCUserSettings - DataCompositionUserSettings - New custom data layout settings
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey <> VariantKey Then			
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		SchemaKey = VariantKey;			
	EndIf;
	
EndProcedure

#EndRegion
	
#Else
	Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên client.';
				|ru = 'Недопустимый вызов объекта на клиенте.';
				|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
				|it = 'Chiamata di oggetto non valida sul client.';
				|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
				|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf