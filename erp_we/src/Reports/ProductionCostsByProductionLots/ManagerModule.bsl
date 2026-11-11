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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionCostsByProductionLots);
	DescriptionOfReport.LongDesc = NStr("vi = 'Các chi phí chính (nguyên vật liệu, nhân công và chi phí từng công đoạn) được phân bổ cho các lô hàng sản xuất.';
										|ru = 'Первичные затраты (материалы, труд и постатейные) отнесенные на партии производства.';
										|en = 'Primary costs (materials, labor, and itemized) allocated to production lots.'; fa = 'Primary costs (materials, labor, and itemized) allocated to production lots.';
										|it = 'Первичные затраты (материалы, труд и постатейные) отнесенные на партии производства.';
										|pl = 'Pierwotne wydatki (materiały, praca i wyszczególnione) są przydzielone na partie produkcji.';
										|tr = 'Üretim lotlarına dağıtılan birincil giderler (malzemeler, işçilik ve kalemlere ayrılmış).'");
	DescriptionOfReport.DefineFormSettings = True;	
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AllocationOfCostsByProductionBatches");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí gốc theo từng doanh nghiệp (nguyên vật liệu, công lao động và chi phí chi tiết) được gom nhóm theo nơi phát sinh chi phí.
		|Cho phép xem các lô hàng được phân bổ chi phí.';
		|ru = 'Первичные затраты в разрезе организаций (материалы, труд и постатейные), сгруппированные по местам возникновения затрат.
		|Позволяет увидеть, на какие партии распределены затраты.';
		|en = 'Primary costs by companies (materials, labor, itemized expenses) grouped according to cost centers.
		|It shows allocation of costs per lot.'; fa = 'Primary costs by companies (materials, labor, itemized expenses) grouped according to cost centers.
		|It shows allocation of costs per lot.';
		|it = 'Первичные затраты в разрезе организаций (материалы, труд и постатейные), сгруппированные по местам возникновения затрат.
		|Позволяет увидеть, на какие партии распределены затраты.';
		|pl = 'Pierwotne wydatki w przekroju firm (materiały, praca i wyszczególnione), zgrupowane według miejsc powstania wydatków. 
		|Pozwala zobaczyć, na jakie partie zostały przydzielone wydatki.';
		|tr = 'İş yeri kapsamında gider merkezine göre gruplanmış (malzemeler, işçilik ve kalemler) birincil giderler.
		|Giderlerin hangi lotlara dağıtıldığını görme imkanı sağlar.'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "");
	OptionDetails.DefaultVisibility = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CostGroupingByProductionBatches");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí gốc của bộ phận theo từng doanh nghiệp (nguyên vật liệu, công lao động và chi phí chi tiết) được gom nhóm theo lô hàng sản xuất.
		|Cho phép xem giá vốn của các lô hàng sản xuất đã được tập hợp từ những chi phí và bộ phận nào.';
		|ru = 'Первичные затраты подразделений в разрезе организаций (материалы, труд и постатейные) сгруппированные по партиям производства.
		|Позволяет увидеть, из каких затрат, каких подразделений сложилась себестоимость партии производства.';
		|en = 'Primary costs of business units by companies (materials, labor, itemized expenses) grouped by production lots. 
		|Allows you to view expenses of business units the production lot costs consist of.'; fa = 'Primary costs of business units by companies (materials, labor, itemized expenses) grouped by production lots. 
		|Allows you to view expenses of business units the production lot costs consist of.';
		|it = 'Первичные затраты подразделений в разрезе организаций (материалы, труд и постатейные) сгруппированные по партиям производства.
		|Позволяет увидеть, из каких затрат, каких подразделений сложилась себестоимость партии производства.';
		|pl = 'Pierwotne wydatki działów w przekroju firm (materiały, praca i wyszczególnione) zgrupowane według partii produkcji.
		|Pozwala zobaczyć, z jakich wydatków, jakich działów są złożone koszty własne partii produkcji.';
		|tr = 'İş yeri kapsamında üretim lotlarına göre gruplanmış (malzemeler, işçilik ve kalemlere ayrılmış) departmanların birincil giderleri.
		|Hangi giderlerin, hangi departmanların bir üretim lotunun giderini oluşturduğunu görebilme imkanı sağlar.'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "");
	OptionDetails.DefaultVisibility = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DistributionOfCostsForProductionBatchesByEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí chính theo toàn bộ doanh nghiệp (nguyên vật liệu, công lao động và chi phí công đoạn) được gom nhóm theo nơi phát sinh chi phí.
		|Cho phép xem chi phí được phân bổ vào những lô hàng nào.';
		|ru = 'Первичные затраты по предприятию в целом (материалы, труд и постатейные), сгруппированные по местам возникновения затрат.
		|Позволяет увидеть, на какие партии распределены затраты.';
		|en = 'Primary costs by the company as a whole (materials, labor, itemized expenses) grouped according to cost centers.
		|It shows allocation of costs per lot.'; fa = 'Primary costs by the company as a whole (materials, labor, itemized expenses) grouped according to cost centers.
		|It shows allocation of costs per lot.';
		|it = 'Первичные затраты по предприятию в целом (материалы, труд и постатейные), сгруппированные по местам возникновения затрат.
		|Позволяет увидеть, на какие партии распределены затраты.';
		|pl = 'Pierwotne wydatki według przedsiębiorstwa ogólnie (materiały, praca i wyszczególnione), zgrupowane według miejsc powstania wydatków. 
		|Pozwala zobaczyć, na jakie partie są przydzielone wydatki.';
		|tr = 'İş yeri için gider merkezine göre gruplandırılmış bütün olarak  birincil giderler (malzemeler, işçilik ve kalemlere ayrılmış).
		|Giderlerin hangi lotlara tahsis edildiğinin görülmesini sağlar.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GroupingOfCostsByProductionBatchesByEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí chính của các bộ phận trong toàn bộ doanh nghiệp (nguyên vật liệu, công lao động và chi phí theo công đoạn) được gom nhóm theo lô hàng sản xuất.
		|Cho phép xem giá vốn của các lô hàng sản xuất đã được tập hợp từ những chi phí và bộ phận nào.';
		|ru = 'Первичные затраты подразделений по предприятию в целом (материалы, труд и постатейные) сгруппированные по партиям производства.
		|Позволяет увидеть, из каких затрат, каких подразделений сложилась себестоимость партии производства.';
		|en = 'Primary business unit expenses by the company as a whole (materials, labor, itemized expenses) grouped by production lots. 
		|Allows you to view expenses of business units influenced the production lot cost.'; fa = 'Primary business unit expenses by the company as a whole (materials, labor, itemized expenses) grouped by production lots. 
		|Allows you to view expenses of business units influenced the production lot cost.';
		|it = 'Первичные затраты подразделений по предприятию в целом (материалы, труд и постатейные) сгруппированные по партиям производства.
		|Позволяет увидеть, из каких затрат, каких подразделений сложилась себестоимость партии производства.';
		|pl = 'Pierwotne wydatki działów według przedsiębiorstwa ogólnie (materiały, praca i wyszczególnione) zgrupowane według partii produkcji. 
		|Pozwala zobaczyć, z jakich wydatków, jakich działów są złożone koszty własne partii produkcji.';
		|tr = 'İşletme için üretim lotlarına göre gruplandırılmış bütün olarak departmanların birincil giderleri (malzemeler, işçilik ve kalemlere ayrılmış).
		|Hangi giderlerin, hangi departmanların bir üretim lotunun maliyetini oluşturduğunun görülmesini sağlar.'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "OpeningBalance");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ConsumedForProductionBatches");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Costs_Production");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ClosingBalance");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
