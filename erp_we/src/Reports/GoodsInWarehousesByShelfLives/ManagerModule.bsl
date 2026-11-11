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
	
	If AccessRight("View", Metadata.Reports.GoodsInWarehousesByShelfLives) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.GoodsInWarehousesByShelfLives.FullName();
		ReportCommand.Presentation = NStr("vi = 'Số dư theo hạn dùng';
											|ru = 'Остатки по срокам годности';
											|en = 'Remaining goods by shelf life'; fa = 'کالای باقیمانده بر اساس عمر قفسه‌ای';
											|it = 'Tempo di conservazione residuo';
											|pl = 'Ostatki według terminów ważności';
											|tr = 'Son kullanma tarihlerine göre stok bakiyeleri'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "RemnantsOfProductListByExpirationDate");
		
		ReportCommand.VariantKey = "ByProductContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsInWarehousesByShelfLives);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Hàng hóa nào sắp hết hạn sử dụng?';
									|ru = 'По каким товарам скоро истекает срок годности?';
									|en = 'Which goods are expiring soon?'; fa = 'Which goods are expiring soon?';
									|it = 'По каким товарам скоро истекает срок годности?';
									|pl = 'Według jakich towarów upływa termin ważności?';
									|tr = 'Hangi ürünlerin son kullanma tarihi geçmek üzere?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StockBalanceByShelfLives");
	OptionDetails.LongDesc = NStr("vi = 'Hàng hóa nào sắp hết hạn sử dụng?
		|Số dư hàng hóa này là bao nhiêu và có trong kho nào?';
		|ru = 'По каким товарам скоро истекает срок годности?
		|Сколько таких товаров и на каком складе?';
		|en = 'Check which goods are expiring soon.
		|How many of such goods are available and in which warehouse?'; fa = 'Check which goods are expiring soon.
		|How many of such goods are available and in which warehouse?';
		|it = 'По каким товарам скоро истекает срок годности?
		|Сколько таких товаров и на каком складе?';
		|pl = 'Według jakich towarów upływa termin ważności? 
		|Ile takich towarów jest i w jakim magazynie?';
		|tr = 'Hangi ürünlerin son kullanım tarihi dolmak üzere?
		|Bu ürünlerden hangi ambarda kaç adet mevcut ?'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "BalanceOfGoodsByExpirationDateMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Hàng hóa nào sắp hết hạn sử dụng?';
									|ru = 'По каким товарам скоро истекает срок годности?';
									|en = 'Which goods are expiring soon?'; fa = 'Which goods are expiring soon?';
									|it = 'По каким товарам скоро истекает срок годности?';
									|pl = 'Według jakich towarów upływa termin ważności?';
									|tr = 'Hangi ürünlerin son kullanma tarihi geçmek üzere?'");
	OptionDetails.Description = NStr("vi = 'Số dư hàng hóa theo thời hạn hiệu lực (di động)';
									|ru = 'Остатки товаров по срокам годности (моб.)';
									|en = 'Stock by shelf life (mob. client)'; fa = 'موجودی بر اساس عمر قفسه‌ای (کلاینت موبایل)';
									|it = 'Остатки товаров по срокам годности (моб.)';
									|pl = 'Stan magazynowy towarów według terminów ważności (mob.)';
									|tr = 'Son kullanma tarihlerine göre stok bakiyeleri (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf