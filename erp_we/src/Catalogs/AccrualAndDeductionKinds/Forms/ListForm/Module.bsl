#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	For Each String In Rows Do
		
		If String.Value.Data.ItIsADeduction Then
			
			String.Value.Data.RepresentationType = NStr("ru = 'Удержание';
														|vi = 'Deduction';
														|en = 'Deduction'; fa = 'کسر';
														|it = 'Deduction';
														|pl = 'Deduction';
														|tr = 'Kesinti'"); 
			String.Value.Data.CalculationFormula = "";
			
		Else

			String.Value.Data.RepresentationType = NStr("ru = 'Начисление';
														|vi = 'Accrual';
														|en = 'Accrual'; fa = 'محاسبه';
														|it = 'Accrual';
														|pl = 'Accrual';
														|tr = 'Tahakkuk'");
			
		EndIf;	
		
	EndDo;
	
EndProcedure

#EndRegion