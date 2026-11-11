#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddPartnerDossierTeam(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.PartnerProfile) Then
		
		ReportCommand = ReportsCommands.Add();
		
		UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
		Presentation = ?(UsePartnersAsCounterparties, NStr("vi = 'Hồ sơ đối tác theo chương trình.';
															|ru = 'Досье контрагента по данным программы';
															|en = 'Customer profile according to application data'; fa = 'Customer profile according to application data';
															|it = 'Profilo del contraente secondo i dati del programma';
															|pl = 'Dokumentacja kontrahenta zgodnie z programem';
															|tr = 'Program verilerine göre cari hesap dosyası'"), NStr("vi = 'Hồ sơ bạn hàng';
																															|ru = 'Досье партнера';
																															|en = 'Partner profile'; fa = 'نمایه شریک';
																															|it = 'Profilo del partner';
																															|pl = 'Akta partnera';
																															|tr = 'İş ortağı dosyası'"));
		
		ReportCommand.Manager = Metadata.Reports.PartnerProfile.FullName();
		ReportCommand.Presentation = Presentation;
		
		ReportCommand.MultipleChoice = True; // FormCommand 
		ReportCommand["Importance"]        = "Important";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PartnerProfile);
	DescriptionOfReport.Enabled = False;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf