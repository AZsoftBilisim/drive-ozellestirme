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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PrimaryDemandAnalysis);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Mức độ đáp ứng nhu cầu của khách hàng?
		|Có những nguyên nhân nào không đáp ứng nhu cầu?';
		|ru = 'Насколько удовлетворен спрос клиентов?
		|Какие причины неудовлетворения спроса?';
		|en = 'Is customer demand fulfilled?
		|Why the demand is not fulfilled?'; fa = 'Is customer demand fulfilled?
		|Why the demand is not fulfilled?';
		|it = 'Насколько удовлетворен спрос клиентов?
		|Какие причины неудовлетворения спроса?';
		|pl = 'Na ile jest zaspokojony popyt klientów? 
		|Jakie są przyczyny niezaspokojonego popytu?';
		|tr = 'Müşteri talebi ne kadar karşılanıyor?
		|Talebin karşılanamamasının nedenleri nelerdir?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MeetingPrimaryDemand");
	OptionDetails.LongDesc = NStr("vi = 'Những nguyên nhân chính nào không đáp ứng nhu cầu theo từng vụ việc và người quản lý?
		|Những vụ việc nào đã đáp ứng nhu cầu?';
		|ru = 'Каковы основные причины неудовлетворения спроса в разрезе сделок и менеджеров?
		|По каким сделкам спрос был удовлетворен?';
		|en = 'Check the reasons for unfulfilled demand by sales opportunities and managers.
		|Verify for which sales opportunities the demand is fulfilled.'; fa = 'Check the reasons for unfulfilled demand by sales opportunities and managers.
		|Verify for which sales opportunities the demand is fulfilled.';
		|it = 'Каковы основные причины неудовлетворения спроса в разрезе сделок и менеджеров?
		|По каким сделкам спрос был удовлетворен?';
		|pl = 'Jakie podstawowe przyczyny niezaspokojenia popytu w przekroju umowy i menedżerów? 
		|Według jakich umowy popyt został zaspokojony?';
		|tr = 'Satış fırsatları ve yöneticiler açısından talebin karşılanamamasının ana nedenleri nelerdir?
		|Hangi satış fırsatları kapsamında talep karşılanmıştır?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
