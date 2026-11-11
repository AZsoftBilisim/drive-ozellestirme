#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the format string for the expiration date representation.
//
// Parameters:
//  AccuracyOfIndicationOfExpirationDate - EnumRef.AccuracyOfShelfLifeIndication - accuracy of specifying the expiration date of the item type.
// 
// Returns:
//  String - the format string of the expiration date of the item type.
//
Function FormatString(AccuracyOfIndicationOfExpirationDate)Export
	
	FormatString = "";
	
	FormatStringTemplate = NStr("vi = 'DF=%AccuracyOfIndication%';
								|ru = 'ДФ=%AccuracyOfIndication%';
								|en = 'DF=%AccuracyOfIndication%'; fa = 'DF=%AccuracyOfIndication%';
								|it = 'DF=%AccuracyOfIndication%';
								|pl = 'DF=%AccuracyOfIndication%';
								|tr = 'DF=%AccuracyOfIndication%'");
	If AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
		FormatString = StrReplace(FormatStringTemplate, "%AccuracyOfIndication%", "'dd.MM.yy HH:00'");
	ElsIf AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
		FormatString = StrReplace(FormatStringTemplate, "%AccuracyOfIndication%", "MM.yy");
	ElsIf AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToDays Then
		FormatString = StrReplace(FormatStringTemplate, "%AccuracyOfIndication%", "dd.MM.yy");
	EndIf;
	
	Return FormatString;
	
EndFunction

// Returns a representation of the format string to output in the controls
//
// Parameters:
//  AccuracyOfIndicationOfExpirationDate - EnumRef.AccuracyOfShelfLifeIndication - accuracy of specifying the expiration date of the item type.
// 
// Returns:
//  String
//
Function FormatStringPresentation(AccuracyOfIndicationOfExpirationDate)Export
	
	FormatStringPresentation = "";
	
	If AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToHours Then
		FormatStringPresentation = NStr("vi = 'ngày, giờ';
										|ru = 'дата, час';
										|en = 'date, hour'; fa = 'date, hour';
										|it = 'dara, ora';
										|pl = 'data, godzina';
										|tr = 'tarih, saat'");
	ElsIf AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToMonths Then
		FormatStringPresentation = NStr("vi = 'tháng, năm';
										|ru = 'месяц, год';
										|en = 'month, year'; fa = 'month, year';
										|it = 'Mese, anno';
										|pl = 'miesiąc, rok';
										|tr = 'ay, yıl'");
	ElsIf AccuracyOfIndicationOfExpirationDate = Enums.AccuracyOfShelfLifeIndication.UpToDays Then
		FormatStringPresentation = NStr("vi = 'ngày';
										|ru = 'дата';
										|en = 'date'; fa = 'تاریخ';
										|it = 'data';
										|pl = 'data';
										|tr = 'tarih'");
	EndIf;
	
	Return FormatStringPresentation;
	
EndFunction

#EndRegion

#EndIf


