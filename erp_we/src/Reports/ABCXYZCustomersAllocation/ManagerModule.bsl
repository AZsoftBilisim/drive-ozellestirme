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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ABCXYZCustomersAllocation);
	DescriptionOfReport.LongDesc = NStr("vi = 'Phân loại ABC/XYZ khách hàng.';
										|ru = 'ABC/XYZ - распределение клиентов.';
										|en = 'ABC/XYZ distribution of customers.'; fa = 'ABC/XYZ distribution of customers.';
										|it = 'ABC/XYZ - распределение клиентов.';
										|pl = 'ABC/XYZ - podział klientów.';
										|tr = 'ABC/XYZ müşteri dağılımı.'");
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
