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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfCCDNumbersOfGoods);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát tính chính xác khi ghi nhận giao dịch với hàng hóa nhập khẩu có chỉ ra số tờ khai hải quan và nước xuất xứ.';
									|ru = 'Контроль корректности учета операций с импортными товарами с указанием номера ГТД и страны происхождения.';
									|en = 'Control accuracy of accounting of transactions with imported goods with specification of a CCD number and country of origin.'; fa = 'Control accuracy of accounting of transactions with imported goods with specification of a CCD number and country of origin.';
									|it = 'Контроль корректности учета операций с импортными товарами с указанием номера ГТД и страны происхождения.';
									|pl = 'Kontrola poprawności ewidencji operacji z towarami importowymi ze wskazaniem numeru towarowej deklaracji celnej i kraju pochodzenia.';
									|tr = 'GKB numarasını ve menşe ülkesini gösteren ithal ürünlerle yapılan işlemlerin muhasebesinin doğruluğunun kontrolü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ControlOfCCDNumbersOfGoods");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát tính chính xác khi ghi nhận giao dịch với hàng hóa nhập khẩu có chỉ ra số tờ khai hải quan và nước xuất xứ.';
									|ru = 'Контроль корректности учета операций с импортными товарами с указанием номера ГТД и страны происхождения.';
									|en = 'Control accuracy of accounting of transactions with imported goods with specification of a CCD number and country of origin.'; fa = 'Control accuracy of accounting of transactions with imported goods with specification of a CCD number and country of origin.';
									|it = 'Контроль корректности учета операций с импортными товарами с указанием номера ГТД и страны происхождения.';
									|pl = 'Kontrola poprawności ewidencji operacji z towarami importowymi ze wskazaniem numeru towarowej deklaracji celnej i kraju pochodzenia.';
									|tr = 'GKB numarasını ve menşe ülkesini gösteren ithal ürünlerle yapılan işlemlerin muhasebesinin doğruluğunun kontrolü.'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ControlOfCCDNumbersOfGoods_");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát tính chính xác khi ghi nhận giao dịch với hàng hóa nhập khẩu có chỉ ra số tờ khai hải quan và nước xuất xứ.';
									|ru = 'Контроль корректности учета операций с импортными товарами с указанием номера ГТД и страны происхождения.';
									|en = 'Control accuracy of accounting of transactions with imported goods with specification of a CCD number and country of origin.'; fa = 'Control accuracy of accounting of transactions with imported goods with specification of a CCD number and country of origin.';
									|it = 'Контроль корректности учета операций с импортными товарами с указанием номера ГТД и страны происхождения.';
									|pl = 'Kontrola poprawności ewidencji operacji z towarami importowymi ze wskazaniem numeru towarowej deklaracji celnej i kraju pochodzenia.';
									|tr = 'GKB numarasını ve menşe ülkesini gösteren ithal ürünlerle yapılan işlemlerin muhasebesinin doğruluğunun kontrolü.'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
