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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.LoadOfWorkCenterTypes);
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích mức tải các dạng nguồn lực sản xuất theo lịch biểu sản xuất.';
									|ru = 'Анализ загрузки видов рабочих центров по графику производства.';
									|en = 'Analysis of load of work center types by production schedule.'; fa = 'Analysis of load of work center types by production schedule.';
									|it = 'Анализ загрузки видов рабочих центров по графику производства.';
									|pl = 'Analiza centrów pracy według harmonogramu produkcji.';
									|tr = 'Üretim programına göre iş merkezi türlerinin yüklenmesinin analizi.'");
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Delete", "Production.ShopManagement2_2");
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Insert", "Production.IntershopManagement2_2");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "LoadingTypesOfWorkCentersTable");
	OptionDetails.LongDesc = NStr("vi = 'Hiển thị mức tải các dạng nguồn lực sản xuất trong mỗi bộ phận.';
									|ru = 'Показывает загрузку видов рабочих центров в каждом подразделении.';
									|en = 'Shows the load of work center types in each business unit.'; fa = 'Shows the load of work center types in each business unit.';
									|it = 'Показывает загрузку видов рабочих центров в каждом подразделении.';
									|pl = 'Pokazuje pobieranie rodzajów centrów pracy w każdym dziale.';
									|tr = 'Her departmandaki iş merkezi türü yüklenmesini gösterir.'");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement");
	OptionDetails.FunctionalOptions.Add("UsePlanningByProductionResources");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "OccupancyOfWorkCenterTypes");
	OptionDetails.LongDesc = NStr("vi = 'Các dạng việc làm của năng lực sản xuất có chi tiết đến quy trình sản xuất.';
									|ru = 'Занятость видов рабочих центров с детализацией до производственных процессов.';
									|en = 'Stage placement in work center calendar in detail down to production processes.'; fa = 'Stage placement in work center calendar in detail down to production processes.';
									|it = 'Занятость видов рабочих центров с детализацией до производственных процессов.';
									|pl = 'Zajętość rodzajów centrów pracy z detalizacją do procesów produkcyjnych.';
									|tr = 'Üretim süreçlerine kadar detaylandırma ile iş merkezi türlerinin istihdamı.'");
	OptionDetails.FunctionalOptions.Add("EnabledOnlyProductionManagement21");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "LoadingTypesOfWorkCentersTableContext");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
