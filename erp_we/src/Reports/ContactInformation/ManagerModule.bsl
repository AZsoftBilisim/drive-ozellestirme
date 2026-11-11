#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ReportsOptions

// The configuration options for that report.
// More detailed - See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	// Setting placement, default visibility, importance
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "SeeAlso");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ByContactPersons");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "SeeAlso");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
// Returns:
//   ValueTableRow - description of the report command
//
Function AddTeamContactInformationForPartners(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ContactInformation) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ContactInformation.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thông tin liên hệ';
											|ru = 'Контактная информация';
											|en = 'Contact details'; fa = 'اطلاعات تماس';
											|it = 'Informazioni di contatto';
											|pl = 'Dane kontaktowe';
											|tr = 'İletişim bilgileri'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand["Importance"]         = "Important";
		ReportCommand.FunctionalOptions = "UseRolesOfPartnerContactPersons";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction


// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
// Returns:
//   ValueTableRow - description of the report command
//
Function AddTeamContactInformationOfContactPersons(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ContactInformation) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ContactInformation.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thông tin liên hệ của người liên hệ';
											|ru = 'Контактная информация контактных лиц';
											|en = 'Contact details of contact persons'; fa = 'Contact details of contact persons';
											|it = 'Contatti';
											|pl = 'Dane kontaktowe osób kontaktowych';
											|tr = 'İlgili kişilerin iletişim bilgileri'");
		ReportCommand.VariantKey = "ByContactPersons";
		ReportCommand.MultipleChoice = True;
		ReportCommand["Importance"] = "Important";
		ReportCommand.FunctionalOptions = "UseRolesOfPartnerContactPersons";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction


#EndRegion

#EndRegion

#EndIf