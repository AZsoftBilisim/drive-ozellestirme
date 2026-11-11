#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RegisterMetadata = Metadata();
	RegisterDimensions = RegisterMetadata.Dimensions;
	
	For Each Record In ThisObject Do
		
		For Each Dimension In RegisterDimensions Do
			
			If Not ValueIsFilled(Record[Dimension.Name]) And Dimension.DenyIncompleteValues Then
				
				ExceptionText = NStr("vi = 'Chưa điền giá trị trường ""%1""';
									|ru = 'Не заполнено значение поля ""%1""';
									|en = 'The %1 field is blank'; fa = 'The %1 field is blank';
									|it = 'Не заполнено значение поля ""%1""';
									|pl = 'The %1 field is blank';
									|tr = '""%1"" alanı değeri doldurulmamış'");
				Raise StringFunctionsClientServer.SubstituteParametersToString(ExceptionText,
					Dimension.Presentation());
					
			EndIf;
			
		EndDo;
		
		If Not ValueIsFilled(Record.RecordsCount) Then
			ExceptionText = NStr("vi = 'Chưa điền giá trị trường ""%1""';
								|ru = 'Не заполнено значение поля ""%1""';
								|en = 'The %1 field is blank'; fa = 'The %1 field is blank';
								|it = 'Не заполнено значение поля ""%1""';
								|pl = 'The %1 field is blank';
								|tr = '""%1"" alanı değeri doldurulmamış'");
			Raise StringFunctionsClientServer.SubstituteParametersToString(ExceptionText,
				RegisterMetadata.Resources.RecordsCount.Presentation());
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf