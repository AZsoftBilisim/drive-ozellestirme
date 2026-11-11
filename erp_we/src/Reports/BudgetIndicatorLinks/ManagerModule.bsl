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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BudgetIndicatorLinks);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phát sinh khoản mục ngân sách ảnh hưởng thế nào đến chỉ tiêu?';
									|ru = 'Как обороты бюджетных статей влияют на показатели?';
									|en = 'Analyze how turnovers of budget flow items affect budget balance items.'; fa = 'Analyze how turnovers of budget flow items affect budget balance items.';
									|it = 'Как обороты бюджетных статей влияют на показатели?';
									|pl = 'Jak obroty pozycji budżetowych wpływają na wskaźniki?';
									|tr = 'Bütçe kalemlerinin ciroları göstergeleri nasıl etkiler?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "LinksOfBudgetItemsAndIndicators");
	OptionDetails.LongDesc = NStr("vi = 'Phát sinh khoản mục ngân sách ảnh hưởng thế nào đến chỉ tiêu?';
									|ru = 'Как обороты бюджетных статей влияют на показатели?';
									|en = 'Analyze how turnovers of budget flow items affect budget balance items.'; fa = 'Analyze how turnovers of budget flow items affect budget balance items.';
									|it = 'Как обороты бюджетных статей влияют на показатели?';
									|pl = 'Jak obroty pozycji budżetowych wpływają na wskaźniki?';
									|tr = 'Bütçe kalemlerinin ciroları göstergeleri nasıl etkiler?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
