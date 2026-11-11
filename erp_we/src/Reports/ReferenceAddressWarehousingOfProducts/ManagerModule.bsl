#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  Undefined, ValueTableRow - report command
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ReferenceAddressWarehousingOfProducts) 
			And GetFunctionalOption("UseBinLocationWarehousingForInformation") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ReferenceAddressWarehousingOfProducts.FullName();
		ReportCommand.Presentation = NStr("vi = 'Sắp xếp mặt hàng theo ô';
											|ru = 'Размещение номенклатуры по ячейкам';
											|en = 'Inventory put-away'; fa = 'جای‌گذاری موجودی';
											|it = 'Posizionamento degli articoli per celle';
											|pl = 'Umiejscowienie pozycji wg komórek';
											|tr = 'Hücrelere göre ürün gamı yerleştirme'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "PlacementOfNomenclatureByCellsReferenceContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ReferenceAddressWarehousingOfProducts);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những hàng hóa nào có sẵn mà không được gán cho kho chính?
		|Những ô nào đang trống và chưa được gán cho hàng hóa?';
		|ru = 'Для каких товаров в наличии не назначена основная ячейка?
		|Какие ячейки пусты и не назначены для товаров?';
		|en = 'Check for which goods in stock the main storage bin is not assigned.
		|Verify which storage bins are empty and not assigned for goods.'; fa = 'Check for which goods in stock the main storage bin is not assigned.
		|Verify which storage bins are empty and not assigned for goods.';
		|it = 'Для каких товаров в наличии не назначена основная ячейка?
		|Какие ячейки пусты и не назначены для товаров?';
		|pl = 'Dla jakich dostępnych towarów nie zaznaczono podstawowej komórki?
		|Jakie komórki są puste i nie zaznaczone dla towarów?';
		|tr = 'Stoktaki hangi mallar için ana depo yeri tayin edip etmediğini kontrol edin.
		|Hangi depo yerleri boş olduğunu ve mallar için tayin etmediğini kontrol edin.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PlacementOfProductsInCellsForReference");
	OptionDetails.LongDesc = NStr("vi = 'Những hàng hóa nào có sẵn mà không được gán cho kho chính?
		|Những ô nào đang trống và chưa được gán cho hàng hóa?';
		|ru = 'Для каких товаров в наличии не назначена основная ячейка?
		|Какие ячейки пусты и не назначены для товаров?';
		|en = 'Check for which goods in stock the main storage bin is not assigned.
		|Verify which storage bins are empty and not assigned for goods.'; fa = 'Check for which goods in stock the main storage bin is not assigned.
		|Verify which storage bins are empty and not assigned for goods.';
		|it = 'Для каких товаров в наличии не назначена основная ячейка?
		|Какие ячейки пусты и не назначены для товаров?';
		|pl = 'Dla jakich dostępnych towarów nie zaznaczono podstawowej komórki?
		|Jakie komórki są puste i nie zaznaczone dla towarów?';
		|tr = 'Stoktaki hangi mallar için ana depo yeri tayin edip etmediğini kontrol edin.
		|Hangi depo yerleri boş olduğunu ve mallar için tayin etmediğini kontrol edin.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "PlacementOfNomenclatureByCellsReferenceContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf