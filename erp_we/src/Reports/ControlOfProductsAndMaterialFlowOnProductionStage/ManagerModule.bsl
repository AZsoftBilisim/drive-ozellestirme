
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//   ValueTableRow - added command
//
Function AddCommandControlMovementOfProductsAndMaterialsByProductionStage(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ControlOfProductsAndMaterialFlowOnProductionStage) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ControlOfProductsAndMaterialFlowOnProductionStage.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm soát sự lưu chuyển của sản phẩm và vật liệu';
											|ru = 'Контроль движения продукции и материалов';
											|en = 'Control of product and material flow'; fa = 'کنترل جریان محصول و مواد';
											|it = 'Controllo del movimento di produzione e materiali';
											|pl = 'Kontrola przepływu produktów i materiałów';
											|tr = 'İmal edilen ürün ve malzeme hareketi kontrolü'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ControlOfMovementOfProductsAndMaterialsAtProductionStage";
		
		Return ReportCommand;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfProductsAndMaterialFlowOnProductionStage);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf