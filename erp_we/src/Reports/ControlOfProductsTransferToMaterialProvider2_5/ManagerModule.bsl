#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
//
// Parameters:
//  ReportsCommands - See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.Commands
//
// Returns:
//  Undefined, ValueTableRow - description of the added command.
//
Function AddReportCommand(ReportsCommands) Export
	
	If Not AccessRight("View", Metadata.Reports.ControlOfProductsTransferToMaterialProvider2_5) Then
		Return Undefined;
	EndIf;
	
	ReportCommand = ReportsCommands.Add();
	ReportCommand.Manager           = Metadata.Reports.ControlOfProductsTransferToMaterialProvider2_5.FullName();
	ReportCommand.Presentation      = NStr("vi = 'Kiểm soát chuyển giao sản phẩm cho bên đặt gia công';
											|ru = 'Контроль передачи продукции давальцу';
											|en = 'Control of product transfer to material provider'; fa = 'کنترل انتقال محصول به تأمین‌کننده مواد';
											|it = 'Controllo di consegna dei prodotti al prestatore';
											|pl = 'Kontrola przekazania produkcji do właściciela surowców';
											|tr = 'Sağlayıcıya ürün transfer kontrolü'");
	ReportCommand.MultipleChoice = False;
	ReportCommand.Importance           = "Ordinary";
	ReportCommand.VariantKey       = "ControlOfTransferOfProductsToGiver2_5Context";
		
	Return ReportCommand;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfProductsTransferToMaterialProvider2_5);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Bao nhiêu sản phẩm đã được đặt hàng, sản xuất, chuyển giao cho người đặt gia công?';
									|ru = 'Сколько заказано, выпущено, передано продукции давальцам?';
									|en = 'Check how many manufactured products are ordered, released, and transferred to providers.'; fa = 'Check how many manufactured products are ordered, released, and transferred to providers.';
									|it = 'Сколько заказано, выпущено, передано продукции давальцам?';
									|pl = 'Ile zamówiono, wyprodukowano, przekazano produkcji właścicielom surowców?';
									|tr = 'Kaç adet imal edilen ürün sipariş edildi, üretildi, tedarikçilere transfer edildi?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ControlOfProductsTransferToMaterialProvider2_5");
	OptionDetails.LongDesc = NStr("vi = 'Bao nhiêu sản phẩm đã được đặt hàng, sản xuất, chuyển giao cho người đặt gia công?';
									|ru = 'Сколько заказано, выпущено, передано продукции давальцам?';
									|en = 'Check how many manufactured products are ordered, released, and transferred to providers.'; fa = 'Check how many manufactured products are ordered, released, and transferred to providers.';
									|it = 'Сколько заказано, выпущено, передано продукции давальцам?';
									|pl = 'Ile zamówiono, wyprodukowano, przekazano produkcji właścicielom surowców?';
									|tr = 'Kaç adet imal edilen ürün sipariş edildi, üretildi, tedarikçilere transfer edildi?'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ControlOfTransferOfProductsToGiver2_5Context");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf