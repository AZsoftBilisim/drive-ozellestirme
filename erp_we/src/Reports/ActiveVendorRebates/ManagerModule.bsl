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
	
	DisplayReportOptions = False;
	
	ReportSettings = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ActiveVendorRebates);
	ReportSettings.FunctionalOptions.Add(Metadata.FunctionalOptions.UseVendorRebates.Name);
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ReportsOptions.OptionDetails(
		Settings, ReportSettings, "ActiveVendorRebates");
	OptionSettings.LongDesc = NStr("vi = 'Điều kiện thưởng lũy kế nào của nhà cung cấp đang có hiệu lực trong kỳ cụ thể?';
									|ru = 'Какие условия ретро-бонусов поставщика действуют в указанном периоде?';
									|en = 'What vendor rebate conditions are valid during the specified period?'; fa = 'What vendor rebate conditions are valid during the specified period?';
									|it = 'Какие условия ретро-бонусов поставщика действуют в указанном периоде?';
									|pl = 'What vendor rebate conditions are valid during the specified period?';
									|tr = 'Tedarikçinin belirtilmiş dönemde geçerli retro bonuslarının şartları nelerdir?'");
	OptionSettings.Location.Insert(Metadata.Subsystems.Purchases.Subsystems.VendorRebates);
	
	ReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, DisplayReportOptions);
	
	TMReportOptionsOverridable.DisableReportOption(
		Settings,
		ReportSettings,
		"CurrentRebatesOfSuppliersContext");
	
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
	
	If AccessRight("View", Metadata.Reports.ActiveVendorRebates)
	   And GetFunctionalOption("UseVendorRebates") Then
		
		ReportCommand = ReportsCommands.Add();
		Presentation = NStr("vi = 'Thưởng lũy kế của nhà cung cấp đang có hiệu lực';
							|ru = 'Действующие ретро-бонусы поставщика';
							|en = 'Active vendor rebates'; fa = 'تخفیف‌های حجمی فعال فروشنده';
							|it = 'Действующие ретро-бонусы поставщика';
							|pl = 'Active vendor rebates';
							|tr = 'Sağlayıcının geçerli retro bonusları'");
		ReportCommand.Manager = Metadata.Reports.ActiveVendorRebates.FullName();
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