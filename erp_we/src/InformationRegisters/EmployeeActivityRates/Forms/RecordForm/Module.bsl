
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	CurrencyOfActivityKindRates = Constants.CurrencyOfActivityKindRates.Get();
	
	If ValueIsFilled(CurrencyOfActivityKindRates) Then
		Items.TheLabelCurrencyIsNotSet.Visible = False;
	Else
		Items.TheLabelCurrencyIsNotSet.Title = NStr("vi = 'Tiền tệ của trích dẫn cho các loại công việc không được đặt. Tiền tệ được đặt trong phần quản trị sản xuất.';
													|ru = 'Валюта расценок на виды работ не задана. Валюта задается в разделе администрирования производства.';
													|en = 'Currency of activity kind rates is not specified. It is set in the production administration section.'; fa = 'Currency of activity kind rates is not specified. It is set in the production administration section.';
													|it = 'I tassi di cambio per i tipi di lavoro non sono specificati. La valuta è impostata nella sezione di amministrazione della produzione.';
													|pl = 'Waluta cen rodzajów prac nie została podana. Waluta może być ustawiona w sekcji administracji produkcją.';
													|tr = 'Etkinlik türlerine yönelik oranların para birimi belirtilmedi. Para birimi, üretim yönetimi bölümünde ayarlanır.'");
		Items.CurrencyOfActivityKindRates.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
EndProcedure
