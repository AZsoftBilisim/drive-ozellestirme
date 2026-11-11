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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.TransferredReturnablePackaging);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá số lượng và số tiền ký cược bao bì do khách hàng không trả lại.';
									|ru = 'Оценка количества и залоговой суммы невозвращенной клиентом тары.';
									|en = 'Evaluate the quantity and a deposit value of the packaging that a customer has not returned.'; fa = 'Evaluate the quantity and a deposit value of the packaging that a customer has not returned.';
									|it = 'Оценка количества и залоговой суммы невозвращенной клиентом тары.';
									|pl = 'Ocena ilości i wartości kaucyjnej niezwróconej przez klienta tary.';
									|tr = 'Müşteri tarafından iade edilmeyen ambalaj miktarının ve teminat tutarının değerlendirilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TransferredReturnablePackaging");
	OptionDetails.LongDesc = NStr("vi = 'Đánh giá số lượng và số tiền đặt cọc bao bì mà khách hàng không trả lại (hoặc trả lại không đúng hạn).
		|Thời hạn bắt đầu trả lại gần nhất là bao giờ?';
		|ru = 'Оценка количества и залоговой суммы невозвращенной (или возвращенной не вовремя) клиентом тары.
		|Каковы сроки наступления ближайших возвратов?';
		|en = 'Evaluate the quantity and a deposit value of the packaging that a customer has not returned (or has not returned on time).
		|Verify the nearest packaging return date.'; fa = 'Evaluate the quantity and a deposit value of the packaging that a customer has not returned (or has not returned on time).
		|Verify the nearest packaging return date.';
		|it = 'Оценка количества и залоговой суммы невозвращенной (или возвращенной не вовремя) клиентом тары.
		|Каковы сроки наступления ближайших возвратов?';
		|pl = 'Ocena ilości i wartości kaucyjnej niezwróconej (lub zwróconej nie w terminie) przez klienta tary. 
		|Jakie są terminy wystąpienia najbliższych zwrotów?';
		|tr = 'Müşteri tarafından iade edilmeyen (veya vadesi aşımında iade edilen) ambalaj miktarının ve teminat tutarının değerlendirilmesi.
		|Sonraki iadeler için son tarihler nelerdir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
