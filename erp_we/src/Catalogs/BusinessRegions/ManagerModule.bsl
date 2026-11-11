

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.ContactInformation.AddTeamContactInformationForPartners(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Presentation = NStr("vi = 'Thông tin liên hệ của bạn hàng theo khu vực kinh doanh';
											|ru = 'Контактная информация партнеров по бизнес-региону';
											|en = 'Contact details of partners in business region'; fa = 'Contact details of partners in business region';
											|it = 'Informazioni di contatto dei partner delle aree commerciali';
											|pl = 'Informacja kontaktowa partnerów w regionie biznesowym';
											|tr = 'İş bölgesindeki ortakların iletişim bilgileri'");
	EndIf;
	
	ReportCommand = Reports.ContactInformation.AddTeamContactInformationOfContactPersons(ReportsCommands);
	If ReportCommand <> Undefined Then
	EndIf;
	
EndProcedure

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf
