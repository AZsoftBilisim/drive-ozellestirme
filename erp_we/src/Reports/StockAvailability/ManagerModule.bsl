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
	
	If AccessRight("View", Metadata.Reports.StockAvailability)
		And Not TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StockAvailability.FullName();
		ReportCommand.Presentation = NStr("vi = 'Số dư và tính khả dụng';
											|ru = 'Остатки и доступность';
											|en = 'Stock availability'; fa = 'دسترس‌پذیری موجودی';
											|it = 'Rimanenze e disponibilità';
											|pl = 'Ostatki i dostępność';
											|tr = 'Bakiye ve erişilebilirlik'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "RemainingGoodsAndAvailability");
		
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
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StockAvailability);
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	DescriptionOfReport.DefineFormSettings = True;

	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Số dư hàng tồn kho là bao nhiêu và bao nhiêu trong đó là khả dụng?
		|Bao nhiêu hàng hóa đang giao, dự phòng hoặc đang đặt riêng?
		|Hàng hóa được dự phòng cho những đơn hàng nào?';
		|ru = 'Каков остаток товаров и сколько из них доступно?
		|Сколько товаров отгружается, в резерве или в обособлении?
		|Какими заказами зарезервирован товар?';
		|en = 'Check the stock balance. Verify how many goods are available.
		|Track how many goods are shipped, in reserve or assigned.
		|Track by which orders the goods are reserved.'; fa = 'Check the stock balance. Verify how many goods are available.
		|Track how many goods are shipped, in reserve or assigned.
		|Track by which orders the goods are reserved.';
		|it = 'Каков остаток товаров и сколько из них доступно?
		|Сколько товаров отгружается, в резерве или в обособлении?
		|Какими заказами зарезервирован товар?';
		|pl = 'Jaki jest stan magazynowy i towarów z magazynu jest dostępne? 
		|Ile towarów jest wysłano, w rezerwie lub w oddzieleniu?
		|Przez jakie zamówienia jest zarezerwowany towar?';
		|tr = 'Ürünlerin bakiyesi nedir ve kaç adet mevcut?
		|Yedekte veya ayrıca olmak üzere kaç ürün sevk ediliyor?
		|Ürünler hangi siparişler için ayrıldı?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UseAssignmentsWithoutOrder");
	OptionDetails.FunctionalOptions.Add("UseAssignmentsWithoutOrder");
	OptionDetails.LongDesc = NStr("vi = 'Số dư hàng tồn kho là bao nhiêu và bao nhiêu trong đó là khả dụng?
		|Bao nhiêu hàng hóa đang giao, dự phòng hoặc đang đặt riêng?
		|Hàng hóa được dự phòng cho những đơn hàng nào?';
		|ru = 'Каков остаток товаров и сколько из них доступно?
		|Сколько товаров отгружается, в резерве или в обособлении?
		|Какими заказами зарезервирован товар?';
		|en = 'Check the stock balance. Verify how many goods are available.
		|Track how many goods are shipped, in reserve or assigned.
		|Track by which orders the goods are reserved.'; fa = 'Check the stock balance. Verify how many goods are available.
		|Track how many goods are shipped, in reserve or assigned.
		|Track by which orders the goods are reserved.';
		|it = 'Каков остаток товаров и сколько из них доступно?
		|Сколько товаров отгружается, в резерве или в обособлении?
		|Какими заказами зарезервирован товар?';
		|pl = 'Jaki jest stan magazynowy i towarów z magazynu jest dostępne? 
		|Ile towarów jest wysłano, w rezerwie lub w oddzieleniu?
		|Przez jakie zamówienia jest zarezerwowany towar?';
		|tr = 'Ürünlerin bakiyesi nedir ve kaç adet mevcut?
		|Yedekte veya ayrıca olmak üzere kaç ürün sevk ediliyor?
		|Ürünler hangi siparişler için ayrıldı?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "NotUseAssignmentsWithoutOrder");
	OptionDetails.FunctionalOptions.Add("NotUseAssignmentsWithoutOrder");
	OptionDetails.LongDesc = NStr("vi = 'Số dư hàng tồn kho là bao nhiêu và bao nhiêu trong đó là khả dụng?
		|Bao nhiêu hàng hóa đang giao, dự phòng hoặc đang đặt riêng?
		|Hàng hóa được dự phòng cho những đơn hàng nào?';
		|ru = 'Каков остаток товаров и сколько из них доступно?
		|Сколько товаров отгружается, в резерве или в обособлении?
		|Какими заказами зарезервирован товар?';
		|en = 'Check the stock balance. Verify how many goods are available.
		|Track how many goods are shipped, in reserve or assigned.
		|Track by which orders the goods are reserved.'; fa = 'Check the stock balance. Verify how many goods are available.
		|Track how many goods are shipped, in reserve or assigned.
		|Track by which orders the goods are reserved.';
		|it = 'Каков остаток товаров и сколько из них доступно?
		|Сколько товаров отгружается, в резерве или в обособлении?
		|Какими заказами зарезервирован товар?';
		|pl = 'Jaki jest stan magazynowy i towarów z magazynu jest dostępne? 
		|Ile towarów jest wysłano, w rezerwie lub w oddzieleniu?
		|Przez jakie zamówienia jest zarezerwowany towar?';
		|tr = 'Ürünlerin bakiyesi nedir ve kaç adet mevcut?
		|Yedekte veya ayrıca olmak üzere kaç ürün sevk ediliyor?
		|Ürünler hangi siparişler için ayrıldı?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByProductContextWithoutOrder");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UseAppointmentsWithoutOrderingMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Số dư hàng tồn kho là bao nhiêu và bao nhiêu trong đó là khả dụng?
		|Bao nhiêu hàng hóa đang giao, dự phòng hoặc đang đặt riêng?
		|Hàng hóa được dự phòng cho những đơn hàng nào?';
		|ru = 'Каков остаток товаров и сколько из них доступно?
		|Сколько товаров отгружается, в резерве или в обособлении?
		|Какими заказами зарезервирован товар?';
		|en = 'Check the stock balance. Verify how many goods are available.
		|Track how many goods are shipped, in reserve or assigned.
		|Track by which orders the goods are reserved.'; fa = 'Check the stock balance. Verify how many goods are available.
		|Track how many goods are shipped, in reserve or assigned.
		|Track by which orders the goods are reserved.';
		|it = 'Каков остаток товаров и сколько из них доступно?
		|Сколько товаров отгружается, в резерве или в обособлении?
		|Какими заказами зарезервирован товар?';
		|pl = 'Jaki jest stan magazynowy i towarów z magazynu jest dostępne? 
		|Ile towarów jest wysłano, w rezerwie lub w oddzieleniu?
		|Przez jakie zamówienia jest zarezerwowany towar?';
		|tr = 'Ürünlerin bakiyesi nedir ve kaç adet mevcut?
		|Yedekte veya ayrıca olmak üzere kaç ürün sevk ediliyor?
		|Ürünler hangi siparişler için ayrıldı?'");
	OptionDetails.Description = NStr("vi = 'Số dư và tính khả dụng của hàng hóa (di động)';
									|ru = 'Остатки и доступность товаров (моб.)';
									|en = 'Stock availability (mob. client)'; fa = 'دسترس‌پذیری موجودی (کلاینت موبایل)';
									|it = 'Остатки и доступность товаров (моб.)';
									|pl = 'Stan magazynowy i dostępność towarów (mob.)';
									|tr = 'Ürün bakiyeleri ve erişilebilirlik (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf