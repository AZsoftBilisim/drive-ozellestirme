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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductsRelease);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá sản lượng theo đơn vị.';
									|ru = 'Оценка выпуска по подразделениям.';
									|en = 'Business unit release evaluation.'; fa = 'Business unit release evaluation.';
									|it = 'Оценка выпуска по подразделениям.';
									|pl = 'Ocena wyprodukowania według działów.';
									|tr = 'Üretimin departmana göre değerlendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ProductsRelease");
	OptionDetails.LongDesc = NStr("vi = 'Khối lượng xuất xưởng trong bộ phận là bao nhiêu?
											|Không có lỗi khi lập chứng từ xuất xưởng?
											|Không có lỗi khi phản ánh chi phí theo công việc và bán thành phẩm?';
											|ru = 'Какой объем выпуска в подразделениях?
											|Нет ли ошибок при оформлении документов выпуска?
											|Нет ли ошибок в отражении затрат по работам и полуфабрикатам?';
											|en = 'Take an overview of the output volume in the business units.
											|Check if there any errors upon registering output documents.
											|Verify if there any errors upon recording costs of works and semi-finished products.'; fa = 'Take an overview of the output volume in the business units.
											|Check if there any errors upon registering output documents.
											|Verify if there any errors upon recording costs of works and semi-finished products.';
											|it = 'Какой объем выпуска в подразделениях?
											|Нет ли ошибок при оформлении документов выпуска?
											|Нет ли ошибок в отражении затрат по работам и полуфабрикатам?';
											|pl = 'Jaka objętość jest w działach? 
											|Czy niema błędów przy sporządzeniu dokumentów wyprodukowania? 
											|Czy nie ma błędów w odzwierciedleniu rozchodów według prac i półproduktów?';
											|tr = 'Departmanlarda üretim hacmi nedir?
											|Üretim belgelerinin hazırlanmasında herhangi  hata var mı?
											|İş ve yarı mamul giderlerinin yansıtılmasında herhangi hata var mı?'");
	
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Delete", "Production.ShopManagement2_2");
	TMReportOptionsOverridable.ChangePlacementOfReportVariant(OptionDetails.Location, "Insert", "Production.ShopFloorManufacturingAccounting");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
