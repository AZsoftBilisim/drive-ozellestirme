#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   CallSource - String - an additional parameter, a string with the name from where the function is called.
//
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands, CallSource = "") Export

	If AccessRight("View", Metadata.Reports.PriceAnalysis)
		And HaveRightToReadDocumentTables(CallSource) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PriceAnalysis.FullName();
		ReportCommand.Presentation = NStr("vi = 'Phân tích giá';
											|ru = 'Анализ цен';
											|en = 'Price analysis'; fa = 'تحلیل قیمت';
											|it = 'Analisi dei prezzi';
											|pl = 'Analiza cen';
											|tr = 'Fiyat analizi'");
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "PriceAnalysis";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PriceAnalysis);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function ArrayOfNamesOfDocumentsThatFormData()
	
	DocumentsArray = New Array;
	DocumentsArray.Add("SalesOrder");
	DocumentsArray.Add("CustomerInvoice");
	DocumentsArray.Add("CommercialProposalForCustomer");

	Return DocumentsArray;
	
EndFunction

Function HaveRightToReadDocumentTables(CallSource) 
	
	If CallSource = "SalesOpportunitiesToCustomer" Then
		ArrayOfDocumentNames = ArrayOfNamesOfDocumentsThatFormData();
		
		For Each DocumentName In ArrayOfDocumentNames Do
			
			MetadataOfDocument = Metadata.Documents.Find(DocumentName);
			
			If MetadataOfDocument = Undefined 
				Or Not AccessRight("Read", MetadataOfDocument) Then
				
				Return False;
				
			EndIf;
			
		EndDo;
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#EndIf