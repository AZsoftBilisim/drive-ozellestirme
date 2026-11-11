#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.PurchaseConditions) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PurchaseConditions.FullName();
		ReportCommand.Presentation = NStr("vi = 'Điều kiện mua hàng';
											|ru = 'Условия закупок';
											|en = 'Purchase conditions'; fa = 'شرایط خرید';
											|it = 'Condizioni di acquisto';
											|pl = 'Warunki zakupów';
											|tr = 'Satın alma koşulları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.AdditionalParameters.Insert("CommandName", "PurchaseConditions");
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddVendorReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.PurchaseConditions) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PurchaseConditions.FullName();
		ReportCommand.Presentation = NStr("vi = 'Điều kiện mua hàng theo nhà cung cấp';
											|ru = 'Условия закупок по поставщику';
											|en = 'Vendor purchase conditions'; fa = 'Vendor purchase conditions';
											|it = 'Condizioni di acquisto al fornitore';
											|pl = 'Warunki zakupu przez dostawcę';
											|tr = 'Tedarikçi satın alma hüküm ve koşulları'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.FunctionalOptions = "UseVendorPartnerDataContext,UseDataOfVendorOrCompetitorContext";
		ReportCommand.AdditionalParameters.Insert("CommandName", "SupplierPurchaseConditions");
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PurchaseConditions);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.LongDesc = NStr("vi = 'So sánh điều kiện mua hàng từ những nhà cung cấp khác nhau.';
									|ru = 'Сравнение условий закупки товаров у различных поставщиков.';
									|en = 'Compare goods purchase conditions of vendors.'; fa = 'Compare goods purchase conditions of vendors.';
									|it = 'Сравнение условий закупки товаров у различных поставщиков.';
									|pl = 'Porównanie warunków zakupu towarów u różnych dostawców.';
									|tr = 'Farklı tedarikçilerden ürün satın alma koşullarının karşılaştırılması.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PurchaseConditions");
	OptionDetails.LongDesc = NStr("vi = 'So sánh điều kiện mua hàng từ những nhà cung cấp khác nhau.';
									|ru = 'Сравнение условий закупки товаров у различных поставщиков.';
									|en = 'Compare goods purchase conditions of vendors.'; fa = 'Compare goods purchase conditions of vendors.';
									|it = 'Сравнение условий закупки товаров у различных поставщиков.';
									|pl = 'Porównanie warunków zakupu towarów u różnych dostawców.';
									|tr = 'Farklı tedarikçilerden ürün satın alma koşullarının karşılaştırılması.'");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf