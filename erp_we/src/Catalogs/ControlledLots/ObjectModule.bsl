#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	Raise NStr("vi = 'Không thể sao chép';
				|ru = 'Копирование недоступно';
				|en = 'Copying is not available'; fa = 'Copying is not available';
				|it = 'Copiatura non disponibile';
				|pl = 'Kopiowanie jest niedostępne';
				|tr = 'Kopyalama mevcut değil'");;
	
EndProcedure

#EndRegion

#EndIf
#EndIf
