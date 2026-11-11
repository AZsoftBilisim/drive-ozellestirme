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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ItemizedProductionCosts);
	DescriptionOfReport.LongDesc = NStr("vi = 'Chi phí sản xuất chi tiết theo từng doanh nghiệp được đưa vào bộ phận và phân bổ cho giá vốn sản phẩm.
		|Cho phép phân tích tất cả chi phí theo công đoạn đã được phân bổ cho lô hàng sản xuất hay chưa.';
		|ru = 'Постатейные производственные расходы в разрезе организаций, отнесенные на подразделение и распределенные на себестоимость продукции.
		|Позволяет проанализировать, все ли постатейные расходы распределены на партии производства.';
		|en = 'Itemized production costs by companies referred to a business unit and allocated to product cost.
		|It allows you to analyze if all itemized expenses are allocated to production lots.'; fa = 'Itemized production costs by companies referred to a business unit and allocated to product cost.
		|It allows you to analyze if all itemized expenses are allocated to production lots.';
		|it = 'Постатейные производственные расходы в разрезе организаций, отнесенные на подразделение и распределенные на себестоимость продукции.
		|Позволяет проанализировать, все ли постатейные расходы распределены на партии производства.';
		|pl = 'Wyszczególnione wydatki produkcyjne w przkroju firm, odniesione do działu i przydzielone do kosztów własnych produkcji.
		|Pozwala przeanalizować, czy wszystkie wyszczególnione wydatki są przydzielone na partie produkcji.';
		|tr = 'Departmana ait edilen ve imal edilen ürün üretim maliyetine dağıtılan iş yerine göre kalemlere ayrılmış üretim maliyetleri.
		|Tüm kalemlere ayrılmış maliyetlerin üretim lotlarına tahsis edilip edilmediğinin analiz edilmesini sağlar.'");
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "OpeningBalance");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Inflow");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ConsumedForProductionBatches");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ClosingBalance");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfItemizedExpensesByEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí sản xuất theo công đoạn trong toàn bộ doanh nghiệp được đưa vào bộ phận và phân bổ cho giá vốn sản phẩm.
		|Cho phép phân tích tất cả chi phí chi tiết đã được phân bổ cho lô hàng sản xuất hay chưa.';
		|ru = 'Постатейные производственные расходы по предприятию в целом, отнесенные на подразделение и распределенные на себестоимость продукции.
		|Позволяет проанализировать, все ли постатейные расходы распределены на партии производства.';
		|en = 'Itemized production costs of the whole enterprise referred to a business unit and allocated to product cost.
		|It allows you to analyze if all itemized expenses are allocated to production lots.'; fa = 'Itemized production costs of the whole enterprise referred to a business unit and allocated to product cost.
		|It allows you to analyze if all itemized expenses are allocated to production lots.';
		|it = 'Постатейные производственные расходы по предприятию в целом, отнесенные на подразделение и распределенные на себестоимость продукции.
		|Позволяет проанализировать, все ли постатейные расходы распределены на партии производства.';
		|pl = 'Wyszczególnione wydatki produkcyjne według przedsiębiorstwa ogólnie, odniesione do działu i przydzielone do kosztów własnych produkcji. 
		|Pozwala przeanalizować, czy wszystkie wyszczególnione wydatki są przydzielone na partie produkcji.';
		|tr = 'Departmana ait edilen ve imal edilen ürün üretim maliyetine dağıtılan işletmeye göre kalemlere ayrılmış üretim maliyetleri.
		|Tüm kalemlere ayrılmış maliyetlerin üretim lotlarına tahsis edilip edilmediğinin analiz edilmesini sağlar.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
