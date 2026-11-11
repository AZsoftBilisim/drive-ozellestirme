//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.InitialRequestAnalysis);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đã thu hút bao nhiêu khách hàng?
		|Bao nhiêu vụ việc đã được ký kết?
		|Phân tích theo từng nguồn tác động, kênh quan tâm ban đầu và kiểu nguồn.';
		|ru = 'Сколько клиентов было привлечено?
		|Сколько было заключено сделок?
		|Анализ в разрезе источников воздействия, каналов первичного интереса и типам источников.';
		|en = 'How many customers are attracted?
		|How many deals are concluded?
		|Analysis by impact sources, lead source channels, and source types.'; fa = 'How many customers are attracted?
		|How many deals are concluded?
		|Analysis by impact sources, lead source channels, and source types.';
		|it = 'Сколько клиентов было привлечено?
		|Сколько было заключено сделок?
		|Анализ в разрезе источников воздействия, каналов первичного интереса и типам источников.';
		|pl = 'Ile klientów zostało zostało pozyskano? 
		|Ile zostało zawarto transakcji? 
		|Analiza w przekroju źródeł wpływu, kanałów pierwotnego zainteresowania i typów źródeł.';
		|tr = 'Kaç müşteri çekildi?
		|Kaç satış fırsatı yapıldı?
		|Etki kaynakları, birincil ilgi kanalları ve kaynak tipleri kesitinde analiz.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PrimaryInterest");
	OptionDetails.LongDesc = NStr("vi = 'So sánh các nguồn quan tâm ban đầu theo số lượng khách hàng đã ghi nhận và vụ việc đã ký kết.';
									|ru = 'Сравнение источников первичного интереса по количеству зарегистрированных клиентов и заключенных сделок.';
									|en = 'Compare lead sources against the number of registered customers and sales opportunities.'; fa = 'Compare lead sources against the number of registered customers and sales opportunities.';
									|it = 'Сравнение источников первичного интереса по количеству зарегистрированных клиентов и заключенных сделок.';
									|pl = 'Porównanie źródeł pierwotnego interesu według ilości zarejestrowanych klientów i zawartych transakcji.';
									|tr = 'Kayıtlı müşteri ve yapılan satış fırsatı sayısı kapsamında birincil ilgi kaynaklarının karşılaştırılması.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
