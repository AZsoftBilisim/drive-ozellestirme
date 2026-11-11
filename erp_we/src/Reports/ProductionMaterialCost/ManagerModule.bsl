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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductionMaterialCost);
	DescriptionOfReport.LongDesc = NStr("vi = 'Dữ liệu tổng hợp về biến động chi phí, phân bổ chi phí cho lô hàng sản xuất và thành phẩm theo từng doanh nghiệp.
		|Cho phép theo dõi việc nhận nguyên vật liệu, phân bổ nguyên vật liệu, công lao động và chi phí chi tiết cho lô hàng sản xuất và xuất xưởng sản phẩm.';
		|ru = 'Сводные данные о движении затрат, распределении затрат на партии производства и выпущенной продукции в разрезе организаций.
		|Позволяет проследить поступление материалов, отнесение материалов, трудозатрат и постатейных расходов на партии производства и выпуск продукции.';
		|en = 'Summary information about cost movements, allocation of costs by production lots and released products by companies.
		|Allows you to follow material receipt; allocation of materials, labor costs and itemized expenses to production lots and product release.'; fa = 'Summary information about cost movements, allocation of costs by production lots and released products by companies.
		|Allows you to follow material receipt; allocation of materials, labor costs and itemized expenses to production lots and product release.';
		|it = 'Сводные данные о движении затрат, распределении затрат на партии производства и выпущенной продукции в разрезе организаций.
		|Позволяет проследить поступление материалов, отнесение материалов, трудозатрат и постатейных расходов на партии производства и выпуск продукции.';
		|pl = 'Skonsolidowane dane o przepływie kosztów, przydziale kosztów na partie produkcji i wyprodukowanej produkcji w przekroju firm. 
		|Pozwala prześledzić wpływ materiałów, przydział materiałów, nakłady pracy i wydatki według pozycji na partie produkcji i wyprodukowanie produkcji.';
		|tr = 'Giderlerin hareketi, üretim lotları ve iş yeri tarafından piyasaya sürülen imal edilen ürünler için maliyetlerin dağıtımı hakkında özet veriler.
		|Malzemelerin girişini, malzemelerin, iş gücü maliyetlerinin üretim lotlarına ve imal edilen ürün üretimine göre atanmasını, kalemlere ayrılmış maliyetlerin izlenmesini sağlar.'");
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "OpeningBalance");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Inflow");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Purchased");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Transfers");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "TransfersToWarehouse");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ConsumedForProductionBatches");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Manufactured");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "WriteOffsForExpenses");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ClosingBalance");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "MovementOfMaterialsProductsWorksOnEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tổng hợp về biến động chi phí, phân bổ chi phí cho lô hàng sản xuất và thành phẩm trong doanh nghiệp.
		|Cho phép theo dõi việc nhận nguyên vật liệu, phân bổ nguyên vật liệu, công lao động và chi phí theo công đoạn cho lô hàng sản xuất và xuất xưởng sản phẩm.';
		|ru = 'Сводные данные о движении затрат, распределении затрат на партии производства и выпущенной продукции по предприятию.
		|Позволяет проследить поступление материалов, отнесение материалов, трудозатрат и постатейных расходов на партии производства и выпуск продукции.';
		|en = 'Summary information about cost movements, allocation of costs by production lots and released products by company.
		|Allows you to follow material receipt; allocation of materials, labor costs and itemized expenses to production lots and product release.'; fa = 'Summary information about cost movements, allocation of costs by production lots and released products by company.
		|Allows you to follow material receipt; allocation of materials, labor costs and itemized expenses to production lots and product release.';
		|it = 'Сводные данные о движении затрат, распределении затрат на партии производства и выпущенной продукции по предприятию.
		|Позволяет проследить поступление материалов, отнесение материалов, трудозатрат и постатейных расходов на партии производства и выпуск продукции.';
		|pl = 'Skonsolidowane dane o przepływie kosztów, przydziale kosztów na partie produkcji i wyprodukowanej produkcji w przedsiębiorstwie. 
		|Pozwala prześledzić wpływ materiałów, przydział materiałów, nakłady pracy i wydatki według pozycji na partie produkcji i wyprodukowanie produkcji.';
		|tr = 'Giderlerin hareketi, üretim lotları ve işletme tarafından piyasaya sürülen imal edilen ürünler için maliyetlerin dağıtımı hakkında özet veriler.
		|Malzemelerin girişini, malzemelerin, iş gücü maliyetlerinin üretim lotlarına ve imal edilen ürün üretimine göre atanmasını, kalemlere ayrılmış maliyetlerin izlenmesini sağlar.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
