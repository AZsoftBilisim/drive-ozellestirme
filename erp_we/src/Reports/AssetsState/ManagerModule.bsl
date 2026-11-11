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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AssetsState);
	DescriptionOfReport.FunctionalOptions.Add("UseRMManagement");

	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đã thực hiện sửa chữa lần gần nhất khi nào? 
		|Các chỉ tiêu sản lượng hiện tại và dự tính là gì?
		|Tài nguyên còn lại xét về chỉ số và thời hạn sử dụng là bao nhiêu?';
		|ru = 'Когда были выполнены последние ремонты? 
		|Каковы текущие и плановые показателей наработок?
		|Каков остаточный ресурс в величине показателя и срока службы?';
		|en = 'Check when the last repair/maintenance was performed.
		|View the current and planned operating time.
		|Take an overview of the residual lifetime in the amount of value and service life.'; fa = 'Check when the last repair/maintenance was performed.
		|View the current and planned operating time.
		|Take an overview of the residual lifetime in the amount of value and service life.';
		|it = 'Когда были выполнены последние ремонты? 
		|Каковы текущие и плановые показателей наработок?
		|Каков остаточный ресурс в величине показателя и срока службы?';
		|pl = 'Kiedy zostały ostatnie remonty? 
		|Jakie bieżące i planowe wskaźniki średniego czasu pracy? 
		|Jaki jest ostateczny zasób w wielkości wskaźnika i terminu użytkowania?';
		|tr = 'En son bakım-onarımlar ne zaman yapıldı?
		|Mevcut ve planlanan varlık faaliyet ölçümleri nelerdir?
		| Endeks ve hizmet ömrü açısından kalan ömür nedir?'");
		
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AssetsState");
	OptionDetails.LongDesc = NStr("vi = 'Đã thực hiện sửa chữa lần gần nhất khi nào? 
		|Các chỉ tiêu sản lượng hiện tại và dự tính là gì?
		|Tài nguyên còn lại xét về chỉ số và thời hạn sử dụng là bao nhiêu?';
		|ru = 'Когда были выполнены последние ремонты? 
		|Каковы текущие и плановые показателей наработок?
		|Каков остаточный ресурс в величине показателя и срока службы?';
		|en = 'Check when the last repair/maintenance was performed.
		|View the current and planned operating time.
		|Take an overview of the residual lifetime in the amount of value and service life.'; fa = 'Check when the last repair/maintenance was performed.
		|View the current and planned operating time.
		|Take an overview of the residual lifetime in the amount of value and service life.';
		|it = 'Когда были выполнены последние ремонты? 
		|Каковы текущие и плановые показателей наработок?
		|Каков остаточный ресурс в величине показателя и срока службы?';
		|pl = 'Kiedy zostały ostatnie remonty? 
		|Jakie bieżące i planowe wskaźniki średniego czasu pracy? 
		|Jaki jest ostateczny zasób w wielkości wskaźnika i terminu użytkowania?';
		|tr = 'En son bakım-onarımlar ne zaman yapıldı?
		|Mevcut ve planlanan varlık faaliyet ölçümleri nelerdir?
		| Endeks ve hizmet ömrü açısından kalan ömür nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
