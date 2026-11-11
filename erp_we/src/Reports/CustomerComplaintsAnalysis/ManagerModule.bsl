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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CustomerComplaintsAnalysis);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tổng hợp việc ghi nhận và đảm bảo khiếu nại của khách hàng.';
									|ru = 'Сводный анализ регистрации и удовлетворения претензий от клиентов.';
									|en = 'Summary analysis of registration and satisfaction of customer complaints.'; fa = 'Summary analysis of registration and satisfaction of customer complaints.';
									|it = 'Сводный анализ регистрации и удовлетворения претензий от клиентов.';
									|pl = 'Skonsolidowana analiza rejestracji i zaspokojenia roszczeń od klientów.';
									|tr = 'Kayıt özet analizi ve müşterilerden gelen müşteri şikayetlerinin karşılanması.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AnalysisOfCustomerClaims");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá nguyên nhân phát sinh khiếu nại, bộ phận và nhân viên theo số lượng khiếu nại.';
									|ru = 'Рейтинг причин возникновения претензий, подразделений и сотрудников по количеству претензий.';
									|en = 'Rating of reasons for customer complaint causes, business units and employees by the number of complaints.'; fa = 'Rating of reasons for customer complaint causes, business units and employees by the number of complaints.';
									|it = 'Рейтинг причин возникновения претензий, подразделений и сотрудников по количеству претензий.';
									|pl = 'Ranking przyczyn powstania roszczeń, działów i pracowników według ilości roszczeń.';
									|tr = 'Talep sayısına göre şikayet taleplerinin, departmanların ve çalışanların derecelendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ClaimsSatisfactionAnalysis");
	OptionDetails.LongDesc = NStr("vi = 'Tỷ lệ khiếu nại hài lòng và không hài lòng theo từng nguyên nhân.';
									|ru = 'Соотношение удовлетворенных и неудовлетворенных претензий в разрезе причин.';
									|en = 'Ratio of fulfilled and unfulfilled complaints for each complaint reason.'; fa = 'Ratio of fulfilled and unfulfilled complaints for each complaint reason.';
									|it = 'Соотношение удовлетворенных и неудовлетворенных претензий в разрезе причин.';
									|pl = 'Współczynnik zaspokojonych i niezaspokojonych roszczeń w przekroju przyczyn.';
									|tr = 'Sebepler kapsamında karşılanan ve karşılanmayan taleplerin oranı.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DynamicsOfOccurrence");
	OptionDetails.LongDesc = NStr("vi = 'Tỷ lệ khiếu nại đã tiếp nhận và đã xử lý hàng tháng.';
									|ru = 'Соотношение поступивших и отработанных претензий за период помесячно.';
									|en = 'Ratio of received and processed complaints for a month period.'; fa = 'Ratio of received and processed complaints for a month period.';
									|it = 'Соотношение поступивших и отработанных претензий за период помесячно.';
									|pl = 'Współczynnik otrzymanych i przetworzonych roszczeń za okres co miesiąc.';
									|tr = 'Aylık bazda dönem için alınan ve işlenen şikayetlerin oranı.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
