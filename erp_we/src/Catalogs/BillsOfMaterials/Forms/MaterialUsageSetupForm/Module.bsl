
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	FillInFormDetailsByParameters();
	
	SetFormHeader();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	ClearMessages();
	
	If CheckFilling() Then
		
		If Modified Then
			Modified = False;
			NotifyChoice(SelectionValue());
		Else
			Close();
		EndIf;
		
	EndIf;
	Return; // empty handler

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInFormDetailsByParameters()
	
	FillPropertyValues(ThisForm, Parameters, "Products,Characteristic,MaterialApplication");
	
	UsageMode = Number(Parameters.AlternateType);
	Probability        = ?(Parameters.Probability > 1 And Parameters.Probability < 100, Parameters.Probability, 100);
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	If ValueIsFilled(Products) Then
	
		TextProducts = StrTemplate(NStr("vi = 'Mặt hàng: %1';
										|ru = 'Номенклатура: %1';
										|en = 'Item: %1'; fa = 'Item: %1';
										|it = 'Articolo: %1';
										|pl = 'Towary: %1';
										|tr = 'Öğe: %1'"), Products);
		
		If ValueIsFilled(Characteristic) Then
			
			TextProducts = TextProducts + ", " + StrTemplate(NStr("vi = 'Đặc tính: %1';
																	|ru = 'Характеристика: %1';
																	|en = 'Item variant: %1'; fa = 'Item variant: %1';
																	|it = 'Caratteristica: %1';
																	|pl = 'Charakterystyka: %1';
																	|tr = 'Varyant: %1'"), Characteristic);
			
		EndIf;
		
		ThisForm.AutoTitle = False;
		ThisForm.Title = StrTemplate(NStr("vi = 'Sử dụng nguyên vật liệu (%1)';
											|ru = 'Применение материала (%1)';
											|en = 'Material application (%1)'; fa = 'Material application (%1)';
											|it = 'Applicazione del materiale (%1)';
											|pl = 'Zastosowanie materiału (%1)';
											|tr = 'Malzemenin uygulanması (%1)'"), TextProducts);
		
	EndIf;
	
EndProcedure

&AtClient
Function SelectionValue()
	
	Result = New Structure;
	
	Result.Insert("MaterialApplication", MaterialApplication);
	Result.Insert("AlternateType",      Boolean(UsageMode));
	Result.Insert("Probability",         ?(Probability > 1 And Probability < 100, Probability, 0));
	
	Return Result;
	
EndFunction

#EndRegion