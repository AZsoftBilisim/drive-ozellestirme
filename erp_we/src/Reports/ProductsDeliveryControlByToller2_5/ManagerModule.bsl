#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
// 	ReportsCommands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
// Returns:
// 	Undefined, ValueTableRow - description of the added command.
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ProductsDeliveryControlByToller2_5) 
			And GetFunctionalOption("UseProductionByThirdParty2_5") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ProductsDeliveryControlByToller2_5.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm soát giao hàng';
											|ru = 'Контроль поставки продукции';
											|en = 'Product delivery control'; fa = 'Product delivery control';
											|it = 'Controllo di consegna del prodotto';
											|pl = 'Kontrola dostawy produkcji';
											|tr = 'İmal edilen ürün teslimatının kontrolü'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ControlOfDeliveryOfProductsByProcessor2_5Context";
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductsDeliveryControlByToller2_5);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đã đặt, đã sản xuất, đã tiếp nhận bao nhiêu sản phẩm từ người nhận gia công?';
									|ru = 'Сколько заказано, выпущено, поступило продукции от переработчиков?';
									|en = 'Check how many manufactured products are ordered, released, and received from subcontractors.'; fa = 'Check how many manufactured products are ordered, released, and received from subcontractors.';
									|it = 'Сколько заказано, выпущено, поступило продукции от переработчиков?';
									|pl = 'Ile zamówiono, wyprodukowano, wpłynęło produkcji od przetwórców?';
									|tr = 'Fason üreticilerden kaç adet imal edilen ürün sipariş edildi, üretildi, teslim alındı?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductsDeliveryControlByToller2_5");
	OptionDetails.LongDesc = NStr("vi = 'Đã đặt, đã sản xuất, đã tiếp nhận bao nhiêu sản phẩm từ người nhận gia công?';
									|ru = 'Сколько заказано, выпущено, поступило продукции от переработчиков?';
									|en = 'Check how many manufactured products are ordered, released, and received from subcontractors.'; fa = 'Check how many manufactured products are ordered, released, and received from subcontractors.';
									|it = 'Сколько заказано, выпущено, поступило продукции от переработчиков?';
									|pl = 'Ile zamówiono, wyprodukowano, wpłynęło produkcji od przetwórców?';
									|tr = 'Fason üreticilerden kaç adet imal edilen ürün sipariş edildi, üretildi, teslim alındı?'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ControlOfDeliveryOfProductsByProcessor2_5Context");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf