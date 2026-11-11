// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CompositionOfVendorRebates);
	ReportSettings.FunctionalOptions.Add(Metadata.FunctionalOptions.UseVendorRebates.Name);
	ReportSettings.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	TMReportOptionsOverridable.DisableReport(ReportSettings);
	
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//   VariantKey - String - 
//   
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddReportCommand(ReportsCommands, Parameters, VariantKey = "") Export
	
	If AccessRight("View", Metadata.Reports.CompositionOfVendorRebates)
	   And GetFunctionalOption("UseVendorRebates") Then
		
		ReportCommand = ReportsCommands.Add();
		
		If VariantKey = "CompositionOfRebatesSuppliersContext" Then
			
			Presentation = NStr("vi = 'Thành phần chứng từ  (dữ liệu cập nhật)';
								|ru = 'Состав документа (актуальные данные)';
								|en = 'Document content (relevant data)'; fa = 'محتوای سند (داده‌های مربوط)';
								|it = 'Document content (relevant data)';
								|pl = 'Document content (relevant data)';
								|tr = 'Belge içeriği (güncel veriler)'"); 
			
		ElsIf VariantKey = "CompositionOfRebatesOfSuppliersAccordingToDocumentContext" Then
			
			Presentation = NStr("vi = 'Thành phần chứng từ (theo dữ liệu chứng từ)';
								|ru = 'Состав документа (по данным документа)';
								|en = 'Document content (based on document data)'; fa = 'Document content (based on document data)';
								|it = 'Document content (based on document data)';
								|pl = 'Document content (based on document data)';
								|tr = 'Belge içeriği (belge verileri kapsamında)'");
			
		Else
			
			Presentation = NStr("vi = 'Thành phần chứng từ thưởng lũy kế đối với nhà cung cấp';
								|ru = 'Состав документа ретро-бонусов поставщиков';
								|en = 'Vendor rebate document content'; fa = 'Vendor rebate document content';
								|it = 'Vendor rebate document content';
								|pl = 'Vendor rebate document content';
								|tr = 'Tedarikçi retro bonusu belgelerinin içeriği'");
			
		EndIf;
		
		ReportCommand.Manager = Metadata.Reports.CompositionOfVendorRebates.FullName();
		ReportCommand.Presentation = Presentation;
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
		If ValueIsFilled(VariantKey) Then
			
			ReportCommand.VariantKey = VariantKey;
			
		EndIf;
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf