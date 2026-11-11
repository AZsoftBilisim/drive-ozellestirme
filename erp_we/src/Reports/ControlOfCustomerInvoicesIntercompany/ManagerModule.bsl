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
Function AddProductTransferControlCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ControlOfCustomerInvoicesIntercompany) 
			And (GetFunctionalOption("UseCustomerInvoiceIntercompany")
				) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ControlOfCustomerInvoicesIntercompany.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm soát việc chuyển giao hàng hóa';
											|ru = 'Контроль передач товаров';
											|en = 'Goods transfer control'; fa = 'Goods transfer control';
											|it = 'Controllo consegna delle merci';
											|pl = 'Kontrola transferu towarów';
											|tr = 'Mal transferi kontrolü'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "RegistrationOfTransfersOfGoods";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  Undefined, ValueTableRow - report command
Function AddReportGenerationCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ControlOfCustomerInvoicesIntercompany) 
			And (GetFunctionalOption("UseCustomerInvoiceIntercompany")
				) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ControlOfCustomerInvoicesIntercompany.FullName();
		ReportCommand.Presentation = NStr("vi = 'Tạo báo cáo';
											|ru = 'Оформление отчетов';
											|en = 'Register reports'; fa = 'ثبت گزارش‌ها';
											|it = 'Redazione report';
											|pl = 'Tworzenie raportów';
											|tr = 'Rapor düzenlemesi'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "PreparationOfCommissionReports";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfCustomerInvoicesIntercompany);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Tất cả hàng hóa đã được lập chứng từ chuyển giao chưa?
		|Tất cả mặt hàng đã được lập bảng kê ký gửi chưa?
		|Số dư hàng hóa ký gửi là bao nhiêu?';
		|ru = 'Все ли передачи товаров оформлены?
		|Все ли отчеты комиссии оформлены?
		|Каковы остатки комиссионных товаров?';
		|en = 'Check if all goods transfers are completed.
		|Verify if all consignment notifications have been completed.
		|Track the consignment goods balances.'; fa = 'Check if all goods transfers are completed.
		|Verify if all consignment notifications have been completed.
		|Track the consignment goods balances.';
		|it = 'Все ли передачи товаров оформлены?
		|Все ли отчеты комиссии оформлены?
		|Каковы остатки комиссионных товаров?';
		|pl = 'Czy wszyskie przekazania towarów są sporządzone?
		|Czy wszystkie prowizje zostały sporządzone?
		|Jaki jest bieżący stan magazynowy towarów komisowych?';
		|tr = 'Tüm ürün transferleri tamamlandı mı?
		|Tüm komisyon raporları tamamlandı mı?
		|Komisyona tabi ürün bakiyeleri nedir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RegisterCommissionReports");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích hàng hóa đã được chuyển giao ký gửi cho doanh nghiệp khác.
		|Chưa lập bảng kê cho những người nhận nào?';
		|ru = 'Анализ товаров, которые были переданы на комиссию другой организации.
		|Какие получатели еще не отчитались?';
		|en = 'Analyze consignment goods handed over to another company.
		|Verify which recipients have not reported yet.'; fa = 'Analyze consignment goods handed over to another company.
		|Verify which recipients have not reported yet.';
		|it = 'Анализ товаров, которые были переданы на комиссию другой организации.
		|Какие получатели еще не отчитались?';
		|pl = 'Analiza towarów, które zostały przekazane do komisu innej firmie. 
		|Jakie odbiorcy jeszcze nie zdali sprawozdanie?';
		|tr = 'Başka bir iş yerinin komisyonuna transfer edilen ürünlerin analizi.
		|Hangi alıcılar henüz raporlamadı?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RegisterGoodsTransfers");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích hàng hóa đã bán theo sơ đồ liên công ty.
		|Ai là người gửi và ai là người nhận?';
		|ru = 'Анализ товаров, проданных по схеме интеркампани.
		|Кто отправитель и получатель?';
		|en = 'Analysis of goods sold under the intercompany scheme. 
		|Who is the sender and the recipient?'; fa = 'Analysis of goods sold under the intercompany scheme. 
		|Who is the sender and the recipient?';
		|it = 'Анализ товаров, проданных по схеме интеркампани.
		|Кто отправитель и получатель?';
		|pl = 'Analiza towarów, sprzedanych według schematu intercompany. 
		|Kto jest nadawcą i odbiorcą?';
		|tr = 'Şirketler arası şema kapsamında satılan ürünlerin analizi.
		|Gönderen ve alıcı kim?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductsOnCommission");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích số dư hàng hóa ký gửi đang có trong doanh nghiệp.
		|Hàng hóa đã tiếp nhận ký gửi từ những doanh nghiệp nào?';
		|ru = 'Анализ имеющихся остатков комиссионных товаров организации.
		|От каких организаций приняты товары на комиссию?';
		|en = 'Analyze available stock of company consignment goods.
		|Verify, from which companies consignment goods have been received.'; fa = 'Analyze available stock of company consignment goods.
		|Verify, from which companies consignment goods have been received.';
		|it = 'Анализ имеющихся остатков комиссионных товаров организации.
		|От каких организаций приняты товары на комиссию?';
		|pl = 'Analiza istniejącego stanu magazynowego towarów komisowych firmy. 
		|Od jakich firm są przyjęte wiersze pozycji do komisu?';
		|tr = 'İş yerinin komisyon ürünlerinin mevcut bakiyelerinin analizi.
		|Hangi iş yerlerinden konsinye stok kabul edilir?'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "RegistrationOfTransfersOfGoods");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "PreparationOfCommissionReports");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf