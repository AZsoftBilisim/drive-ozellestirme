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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StateOfSubAssets);
	DescriptionOfReport.FunctionalOptions.Add("UseSubAssets");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái gì?
									 |Sản lượng là bao nhiêu?
									 |Đã tiến hành các dạng sửa chữa gì và khi nào?
									 |Đã ghi nhận những hỏng hóc nào?
									 |Đã thực hiện lần sửa chữa gần nhất khi nào?
									 |Các chỉ tiêu sản lượng hiện tại và dự tính là bao nhiêu?
									 |Tài nguyên còn lại xét về chỉ số và thời hạn sử dụng là bao nhiêu?';
									 |ru = 'Какой статус?
									 |Какая наработка?
									 |Какие виды ремонтов проводились и когда?
									 |Какие дефекты были зарегистрированы?
									 |Когда были выполнены последние ремонты?
									 |Какие текущие и плановые показатели наработок?
									 |Какой остаточный ресурс в величине показателя и срока службы?';
									 |en = 'Check the sub-asset status.
									 |Verify the operating time.
									 |See what R&M works were carried out and when.
									 |Check what defects were registered.
									 |See the last R&M performed.
									 |Take an overview of the current and planned operating time units.
									 |Track the residual lifetime in terms of unit and service life.'; fa = 'Check the sub-asset status.
									 |Verify the operating time.
									 |See what R&M works were carried out and when.
									 |Check what defects were registered.
									 |See the last R&M performed.
									 |Take an overview of the current and planned operating time units.
									 |Track the residual lifetime in terms of unit and service life.';
									 |it = 'Какой статус?
									 |Какая наработка?
									 |Какие виды ремонтов проводились и когда?
									 |Какие дефекты были зарегистрированы?
									 |Когда были выполнены последние ремонты?
									 |Какие текущие и плановые показатели наработок?
									 |Какой остаточный ресурс в величине показателя и срока службы?';
									 |pl = 'Jaki status?
									 |Jaki czas pracy?
									 |Jakie rodzaje napraw zostały przeprowadzone i kiedy?
									 |Jakie wady były zarejestrowane?
									 |Kiedy byli wykonane ostatnie naprawey?
									 |Jakie są bieżące i planowe wskaźniki czasu pracy?
									 |Jaki jest pozostały zasób w wielkości wskaźnika terminu użytkowania?';
									 |tr = 'Durum nedir?
									 |Varlık faaliyet ölçümü nedir?
									 |Ne tür bakım-onarımlar yapıldı ve ne zaman?
									 |Hangi kusurlar kaydedildi?
									 |Son bakım-onarımlar ne zaman yapıldı?
									 |Mevcut ve planlanan varlık faaliyet ölçümleri nelerdir?
									 |Performans ve hizmet ömrü açısından kalan ömrü nedir?'");
		
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "StateOfSubAssets");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái gì?
									 |Sản lượng là bao nhiêu?
									 |Đã tiến hành các dạng sửa chữa gì và khi nào?
									 |Đã ghi nhận những hỏng hóc nào?
									 |Đã thực hiện lần sửa chữa gần nhất khi nào?
									 |Các chỉ tiêu sản lượng hiện tại và dự tính là bao nhiêu?
									 |Tài nguyên còn lại xét về chỉ số và thời hạn sử dụng là bao nhiêu?';
									 |ru = 'Какой статус?
									 |Какая наработка?
									 |Какие виды ремонтов проводились и когда?
									 |Какие дефекты были зарегистрированы?
									 |Когда были выполнены последние ремонты?
									 |Какие текущие и плановые показатели наработок?
									 |Какой остаточный ресурс в величине показателя и срока службы?';
									 |en = 'Check the sub-asset status.
									 |Verify the operating time.
									 |See what R&M works were carried out and when.
									 |Check what defects were registered.
									 |See the last R&M performed.
									 |Take an overview of the current and planned operating time units.
									 |Track the residual lifetime in terms of unit and service life.'; fa = 'Check the sub-asset status.
									 |Verify the operating time.
									 |See what R&M works were carried out and when.
									 |Check what defects were registered.
									 |See the last R&M performed.
									 |Take an overview of the current and planned operating time units.
									 |Track the residual lifetime in terms of unit and service life.';
									 |it = 'Какой статус?
									 |Какая наработка?
									 |Какие виды ремонтов проводились и когда?
									 |Какие дефекты были зарегистрированы?
									 |Когда были выполнены последние ремонты?
									 |Какие текущие и плановые показатели наработок?
									 |Какой остаточный ресурс в величине показателя и срока службы?';
									 |pl = 'Jaki status?
									 |Jaki czas pracy?
									 |Jakie rodzaje napraw zostały przeprowadzone i kiedy?
									 |Jakie wady były zarejestrowane?
									 |Kiedy byli wykonane ostatnie naprawey?
									 |Jakie są bieżące i planowe wskaźniki czasu pracy?
									 |Jaki jest pozostały zasób w wielkości wskaźnika terminu użytkowania?';
									 |tr = 'Durum nedir?
									 |Varlık faaliyet ölçümü nedir?
									 |Ne tür bakım-onarımlar yapıldı ve ne zaman?
									 |Hangi kusurlar kaydedildi?
									 |Son bakım-onarımlar ne zaman yapıldı?
									 |Mevcut ve planlanan varlık faaliyet ölçümleri nelerdir?
									 |Performans ve hizmet ömrü açısından kalan ömrü nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
