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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ReceivedReturnablePackaging);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Ước tính số lượng và số tiền bao bì luân chuyển được chấp nhận.';
									|ru = 'Оценка количества и залоговой суммы принятой тары.';
									|en = 'Evaluate the quantity and a deposit value of the received packaging.'; fa = 'Evaluate the quantity and a deposit value of the received packaging.';
									|it = 'Оценка количества и залоговой суммы принятой тары.';
									|pl = 'Ocena ilości i wartości kaucyjnej przyjętej tary.';
									|tr = 'Kabul edilen ambalaj miktarının ve teminat tutarının değerlendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ReceivedReturnablePackaging");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá số lượng và số tiền bao bì đã tiếp nhận.
		|Thời hạn bắt đầu trả lại bao bì gần nhất cho nhà cung cấp là khi nào?';
		|ru = 'Оценка количества и залоговой суммы принятой тары.
		|Каковы сроки наступления ближайших возвратов тары поставщикам?';
		|en = 'Evaluate the quantity and a deposit value of the accepted packaging.
		|Verify what the nearest packaging return to vendors is.'; fa = 'Evaluate the quantity and a deposit value of the accepted packaging.
		|Verify what the nearest packaging return to vendors is.';
		|it = 'Оценка количества и залоговой суммы принятой тары.
		|Каковы сроки наступления ближайших возвратов тары поставщикам?';
		|pl = 'Ocena ilości i wartości kaucyjnej przyjętej tary. 
		|Jakie terminy wystąpienia najbliższych zwrotów tary dostawcom?';
		|tr = 'Kabul edilen ambalaj miktarının ve teminat tutarının değerlendirilmesi.
		|Ambalajların tedarikçilere bir sonraki iadesi için son tarihler nelerdir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
