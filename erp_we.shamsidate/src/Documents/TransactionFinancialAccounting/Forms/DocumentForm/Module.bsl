&AtServer
&After("OnCreateAtServer")
Procedure shamsidateOnCreateAtServer(Cancel, StandardProcessing)
	ShamsiDate = sh_ShamsiCalendar.GregorianToShamsi(Object.Date);
EndProcedure

// Date -> ShamsiDate
&AtClient
Procedure shamsidateDateOnChangeAfter(Item)
	ShamsiDate = sh_ShamsiCalendar.GregorianToShamsi(Object.Date);
EndProcedure

// ShamsiDate -> Date
&AtClient
Procedure shamsidateShamsiDateOnChangeAfter(Item)
	
	NewDate = sh_ShamsiCalendar.ShamsiToGregorian(ShamsiDate);
	
	If NewDate = Undefined Then
		Message("Geçersiz Shamsi tarih. Format: YYYY/MM/DD");
		ShamsiDate = sh_ShamsiCalendar.GregorianToShamsi(Object.Date);
		Return;
	EndIf;
	
	TimePart    = ?(ValueIsFilled(Object.Date), Object.Date - BegOfDay(Object.Date), 0);
	Object.Date = NewDate + TimePart;
	ShamsiDate  = sh_ShamsiCalendar.GregorianToShamsi(Object.Date);
	Modified    = True;
	
	// Drive'ın kendi tarih mantığı (kur, numara vb.)
	DateOnChange(Items.Date);
	
EndProcedure