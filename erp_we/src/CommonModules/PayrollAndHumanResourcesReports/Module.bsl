#Region Internal

// Generates a bill of account for the specified period.
//
// Parameters:
//   Organization - DefinedType.Organization - The company for which the report is generated
//   ListOfIndividuals - Array of CatalogRef.Persons - List of persons for whom the report is generated
//   Month - Date - The month for which the report is generated
//
// Returns:
//   SpreadsheetDocument - The result of the formation of the calculation sheet
Function BillingSheetForPeriod(Organization, ListOfIndividuals, Month) Export
	
	ResultDocument = Undefined;
	
	SetPrivilegedMode(True);
	
	Try
		
		ReportBillingSheet = ReportBillingSheet();
		
		ResultDocument = Reports.PayslipHR.BillingSheet(
				ListOfIndividuals, Organization, Month, ReportBillingSheet);
		
	Except
		
		Info = ErrorInfo();
		Raise NStr("ru = 'Не удалось, сформировать отчет.';
					|vi = 'Cannot generate report.';
					|en = 'Cannot generate report.'; fa = 'Cannot generate report.';
					|it = 'Cannot generate report.';
					|pl = 'Cannot generate report.';
					|tr = 'Rapor oluşturulamadı.'") + " " + BriefErrorDescription(Info);
		
	EndTry;
	
	SetPrivilegedMode(False);
	
	If ResultDocument = Undefined Then
		
		ResultDocument = New SpreadsheetDocument;
		ResultDocument.FitToPage = True;
		ResultDocument.ShowHeaders = False;
		ResultDocument.ShowGrid = False;
		
	EndIf; 
	
	Return ResultDocument;	
	
EndFunction	

// Generates the data of the billing sheets for the specified persons and company for the specified period.
//
// Parameters:
//   Persons - Array of CatalogRef.Persons - list of persons to report
//   Organization - CatalogRef.Companies - The company for which the report is generated
//   StartDate - Date - start date of the period
//   EndDate - Date - end date of the period
//   ReportBillingSheet - ReportObject.PayslipHR - billing sheet report object (a new one is created by default)
//   PageSetup - Structure - tabular document page parameters (by default: Autoscale = True, display headings = False, Display Grid = A lie)
//
// Returns:
//   Structure - contains the tabular document "Result document" and the data of the calculation sheets "Data of the accounting sheets":
//  * SpreadsheetDocument - SpreadsheetDocument - A tabular document with a generated tabular calculation sheet.
Function DataOfBillingSheets(Persons, Organization, StartDate, EndDate, ReportBillingSheet = Undefined, PageSetup = Undefined) Export
	
	If TypeOf(Persons) = Type("Array")
		Or TypeOf(Persons) = Type("FixedArray") Then
		
		PersonsOfReport = Persons;
		
	Else
		PersonsOfReport = CommonClientServer.ValueInArray(Persons);
	EndIf;
	
	ResultDocument = New SpreadsheetDocument;
	If PageSetup = Undefined Then
		
		ResultDocument.FitToPage = True;
		ResultDocument.ShowHeaders = False;
		ResultDocument.ShowGrid = False;
		
	Else
		FillPropertyValues(ResultDocument, PageSetup);
	EndIf;
	
	If ReportBillingSheet = Undefined Then
		ReportBillingSheet = ReportBillingSheet();
	EndIf;
	
	// Filling in the parameters of a composite Template
	ReportPeriod = New StandardPeriod;
	ReportPeriod.StartDate    = BegOfMonth(StartDate);
	ReportPeriod.EndDate = EndOfMonth(EndDate);
	
	SettingsComposer = ReportBillingSheet.SettingsComposer;
	
	SetDCSReportParameter(SettingsComposer, "ReportPeriod", ReportPeriod);
	SetSelectionOfDCSReport(SettingsComposer, "Individual", PersonsOfReport, DataCompositionComparisonType.InList);
	SetSelectionOfDCSReport(SettingsComposer, "Organization", Organization);
		
	// Formation of the calculation sheet
	ReportBillingSheet.ComposeResult(ResultDocument);
	Result = New Structure("ResultDocument", ResultDocument);
	
	DataOfBillingSheets = Undefined;
	ReportBillingSheet.SettingsComposer.UserSettings.AdditionalProperties.Property("DataOfBillingSheets", DataOfBillingSheets);
	Result.Insert("DataOfBillingSheets", DataOfBillingSheets);
	
	ReportBillingSheet.SettingsComposer.UserSettings.AdditionalProperties.Delete("DataOfBillingSheets");
	
	Return Result;
	
EndFunction

#EndRegion  

#Region Private

Procedure SetDCSReportParameter(SettingsComposer, ParameterName, Value)
	
	Var DataParameter;
	
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	
	DataParameter.Use = True;
	DataParameter.Value = Value;
	
EndProcedure  

Procedure SetSelectionOfDCSReport(SettingsComposer, FilterName, Value, Var_ComparisonType = Undefined)
	
	Var Settings, DCField, Itm, FilterElement;
	
	Settings = SettingsComposer.Settings;
	
	DCField = New DataCompositionField(FilterName);
	
	For Each Itm In Settings.Filter.Items Do
		
		If Itm.LeftValue = DCField Then
			FilterElement = Itm;
			Break;
		EndIf;
	EndDo;
	
	If FilterElement = Undefined Then
		
		FilterElement = Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = DCField;
	EndIf;		
	
	FilterElement.Use = (Value <> Undefined);
	FilterElement.ComparisonType = ?(Var_ComparisonType <> Undefined, Var_ComparisonType, DataCompositionComparisonType.Equal); 
	FilterElement.RightValue  = Value;

EndProcedure 

 Function ReportBillingSheet()
	
	ReportObject = Reports.PayslipHR.Create();
	
	Return ReportObject;
	
EndFunction

#EndRegion