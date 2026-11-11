#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ReportsOptions

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "Billing_Sheet");    
	OptionSettings.LongDesc = NStr("ru = 'Расчетный лист';
									|vi = 'Payslip';
									|en = 'Payslip'; fa = 'فیش حقوقی';
									|it = 'Payslip';
									|pl = 'Payslip';
									|tr = 'Ücret hesap pusulası'");
						
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Internal

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "BillingSheet") Then
		
		PrintedDocument = Undefined;
		PrintParameters.Property("PrintedDocument", PrintedDocument);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"BillingSheet",
			"BillingSheet",
			PrintedDocument);
						
	EndIf;
	
EndProcedure

// Generates a bill of account for the specified persons and company for the specified month.
//
// Parameters:
//   Persons - Array of CatalogRef.Persons- list of persons for the formation of a bill of account
//   Organization - CatalogRef.Companies - The company for which the report is generated
//   MonthOfReportGeneration - Date - the month for which the bill is generated
//   ReportBillingSheet - String - Report Link.Billing Sheet - link to the billing sheet report (optional parameter)
//
// Returns:
//   Structure- The result of the formation of the calculation sheet:
//   * ResultDocument - SpreadsheetDocument - generated billing sheet
Function BillingSheet(Persons, Organization, MonthOfReportGeneration, ReportBillingSheet = Undefined) Export
	
	Return PayrollAndHumanResourcesReports.DataOfBillingSheets(
		Persons, Organization, MonthOfReportGeneration, MonthOfReportGeneration, ReportBillingSheet).ResultDocument;
	
EndFunction

#EndRegion

#EndIf