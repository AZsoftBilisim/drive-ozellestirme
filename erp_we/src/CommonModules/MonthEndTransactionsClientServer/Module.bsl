#Region Public


// Representation of the period in the format "Month year".
// 
// Parameters:
//  Period - Date - Period
// 
// Returns:
//  String - Period presentation
Function PeriodRepresentationMonthYear(Period) Export
	
	If Not ValueIsFilled(Period) Or TypeOf(Period) <> Type("Date") Then
		Return "";
	EndIf;
	
	Months = New Array;
	Months.Add(NStr("vi = 'Tháng 1';
					|ru = 'Январь';
					|en = 'January'; fa = 'ژانویه';
					|it = 'Январь';
					|pl = 'Styczeń';
					|tr = 'Ocak'"));
	Months.Add(NStr("vi = 'Tháng 2';
					|ru = 'Февраль';
					|en = 'February'; fa = 'فوریه';
					|it = 'Февраль';
					|pl = 'Luty';
					|tr = 'Şubat'"));
	Months.Add(NStr("vi = 'Tháng 3';
					|ru = 'Март';
					|en = 'March'; fa = 'مارس';
					|it = 'Март';
					|pl = 'Marzec';
					|tr = 'Mart'"));
	Months.Add(NStr("vi = 'Tháng 4';
					|ru = 'Апрель';
					|en = 'April'; fa = 'آوریل';
					|it = 'Апрель';
					|pl = 'Kwiecień';
					|tr = 'Nisan'"));
	Months.Add(NStr("vi = 'Tháng 5';
					|ru = 'Май';
					|en = 'May'; fa = 'مه';
					|it = 'Май';
					|pl = 'Maj';
					|tr = 'Mayıs'"));
	Months.Add(NStr("vi = 'Tháng 6';
					|ru = 'Июнь';
					|en = 'June'; fa = 'ژوئن';
					|it = 'Июнь';
					|pl = 'Czerwiec';
					|tr = 'Haziran'"));
	Months.Add(NStr("vi = 'Tháng 7';
					|ru = 'Июль';
					|en = 'July'; fa = 'ژوئیه';
					|it = 'Июль';
					|pl = 'Lipiec';
					|tr = 'Temmuz'"));
	Months.Add(NStr("vi = 'Tháng 8';
					|ru = 'Август';
					|en = 'August'; fa = 'اوت';
					|it = 'Август';
					|pl = 'Sierpień';
					|tr = 'Ağustos'"));
	Months.Add(NStr("vi = 'Tháng 9';
					|ru = 'Сентябрь';
					|en = 'September'; fa = 'سپتامبر';
					|it = 'Сентябрь';
					|pl = 'Wrzesień';
					|tr = 'Eylül'"));
	Months.Add(NStr("vi = 'Tháng 10';
					|ru = 'Октябрь';
					|en = 'October'; fa = 'اکتبر';
					|it = 'Октябрь';
					|pl = 'Październik';
					|tr = 'Ekim'"));
	Months.Add(NStr("vi = 'Tháng 11';
					|ru = 'Ноябрь';
					|en = 'November'; fa = 'نوامبر';
					|it = 'Ноябрь';
					|pl = 'Listopad';
					|tr = 'Kasım'"));
	Months.Add(NStr("vi = 'Tháng 12';
					|ru = 'Декабрь';
					|en = 'December'; fa = 'دسامبر';
					|it = 'Декабрь';
					|pl = 'Grudzień';
					|tr = 'Aralık'"));
	
	Return Months[Month(Period)-1] + " " + Format(Year(Period), "NZ=0; NG=");
	
EndFunction

// Returns the name of the service property passed to the parameters of all opened forms.
//
// Returns:
//	String - the name of the service property.
//
Function NameOfServicePropertyOfFormsToOpen() Export
	
	Return "MonthEndTransactions";
	
EndFunction

// Checks whether the report uses a new mechanism for working with long-term operations.
//
// Parameters:
//  Form        - ClientApplicationForm - the form being checked.
//
// Returns:
//   Boolean      - True, new programming interface; False, outdated programming interface.
//
Function DescriptionOfUpdateTaskIsUsed(Form) Export
	
	Return CommonClientServer.HasAttributeOrObjectProperty(Form, "DescriptionOfUpdateTask");
	
EndFunction

#EndRegion
