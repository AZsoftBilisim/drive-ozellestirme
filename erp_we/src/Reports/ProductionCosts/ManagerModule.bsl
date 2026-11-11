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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionCosts);
	DescriptionOfReport.LongDesc = NStr("vi = 'Thông tin tổng hợp về chi phí (nguyên vật liệu, dạng công việc đã thực hiện và chi phí theo từng công đoạn), lô sản xuất và thành phẩm theo từng doanh nghiệp.';
										|ru = 'Сводная информация о затратах (материалах, выполненных видах работ и постатейных расходах), партиях производства и выпущенной продукции в разрезе организаций.';
										|en = 'Summary information about costs (materials, kinds of activity performed, and itemized expenses), production lots, and released products by companies.'; fa = 'Summary information about costs (materials, kinds of activity performed, and itemized expenses), production lots, and released products by companies.';
										|it = 'Сводная информация о затратах (материалах, выполненных видах работ и постатейных расходах), партиях производства и выпущенной продукции в разрезе организаций.';
										|pl = 'Informacje zbiorcze o rozchodach (materiałach, wykonanych rodzajów prac i rozchodów według pozycji), partiach produkcji i wyprodukowanej produkcji w przekroju firm.';
										|tr = 'Giderler (malzemeler, gerçekleştirilen iş türleri ve kalemlere ayrılmış maliyetler), üretim lotları ve iş yeri tarafından piyasaya sürülen imal edilen ürünler hakkında özet bilgiler.'");
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfTMQiProductionCostsForEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Thông tin tổng hợp về chi phí (nguyên vật liệu, dạng công việc đã thực hiện và chi phí theo từng công đoạn), lô sản xuất và thành phẩm theo doanh nghiệp.';
									|ru = 'Сводная информация о затратах (материалах, выполненных видах работ и постатейных расходах), партиях производства и выпущенной продукции по предприятию.';
									|en = 'Summary information about costs (materials, kinds of activity performed, and itemized expenses), production lots, and released products of the enterprise.'; fa = 'Summary information about costs (materials, kinds of activity performed, and itemized expenses), production lots, and released products of the enterprise.';
									|it = 'Сводная информация о затратах (материалах, выполненных видах работ и постатейных расходах), партиях производства и выпущенной продукции по предприятию.';
									|pl = 'Informacje zbiorcze o rozchodach (materiałach, wykonanych rodzajów prac i rozchodów według pozycji), partiach produkcji i wyprodukowanej produkcji według przedsiębiorstwa.';
									|tr = 'Giderler (malzemeler, gerçekleştirilen iş türleri ve kalemlere ayrılmış maliyetler), üretim lotları ve işletme tarafından piyasaya sürülen imal edilen ürünler hakkında özet bilgiler.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
