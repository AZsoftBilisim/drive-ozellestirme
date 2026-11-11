#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(MaximumBatch) Then
		ExceptionText = NStr("vi = 'Chưa điền giá trị trường ""%1""';
							|ru = 'Не заполнено значение поля ""%1""';
							|en = 'The ""%1"" field is blank'; fa = 'The ""%1"" field is blank';
							|it = 'Не заполнено значение поля ""%1""';
							|pl = 'The ""%1"" field is blank';
							|tr = '""%1"" alanı değeri doldurulmamış'");
		Raise StringFunctionsClientServer.SubstituteParametersToString(ExceptionText,
			Metadata().Attributes.MaximumBatch.Presentation());
	EndIf;

EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
	
EndProcedure

#EndRegion

#EndIf
