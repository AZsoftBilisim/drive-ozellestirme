#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#EndRegion

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	StandardProcessing = False;
	Presentation = NStr("vi = 'Nguồn ghi hạch toán';
						|ru = 'Регистратор расчетов';
						|en = 'Settlement recorder'; fa = 'ثبت‌کننده تسویه';
						|it = 'Registratore di regolamenti';
						|pl = 'Rejestrator rozliczeń';
						|tr = 'Uzlaşma kaydedicisi'") + " " + Data.Number;
EndProcedure

#EndRegion

#EndIf
